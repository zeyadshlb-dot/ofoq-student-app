import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ofoq_student_app/features/offline/data/models/downloaded_lesson_model.dart';

/// هل الـ URL ده HLS؟
bool _isHls(String url) =>
    url.contains('.m3u8') || url.contains('hls') || url.contains('playlist');

/// هل الـ platform يدعم FFmpeg؟ (Android / iOS فقط)
bool get _ffmpegSupported => Platform.isAndroid || Platform.isIOS;

/// Manages downloading, listing, and deleting offline video files.
/// Supports both direct MP4 links and HLS (.m3u8) streams.
class VideoDownloadService {
  static const String _prefsKey = 'downloaded_lessons_v1';

  // ──────────────────────────── Public API ────────────────────────────────────

  /// Returns all locally downloaded lessons.
  static Future<List<DownloadedLessonModel>> getDownloadedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return DownloadedLessonModel.listFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  /// Returns true if the given lesson is already downloaded.
  static Future<bool> isDownloaded(int lessonId) async {
    final list = await getDownloadedLessons();
    return list.any((l) => l.lessonId == lessonId);
  }

  /// Downloads a video (MP4 or HLS) and saves it as a local MP4 file.
  ///
  /// - For **HLS** (.m3u8): uses FFmpeg to download + mux all segments → MP4
  /// - For **MP4**: uses Dio with progress callback
  ///
  /// [onProgress] receives values from 0.0 → 1.0
  static Future<DownloadedLessonModel?> downloadVideo({
    required int lessonId,
    required String lessonTitle,
    required int courseId,
    required String courseTitle,
    String? courseImage,
    required String url,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken, // used only for MP4 downloads
  }) async {
    final dir = await _getDownloadsDir();
    final filePath = '${dir.path}/lesson_$lessonId.mp4';

    try {
      if (_isHls(url)) {
        if (_ffmpegSupported) {
          // Android / iOS → FFmpeg يحمّل HLS ويحوّله MP4
          await _downloadHls(
            url: url,
            outputPath: filePath,
            onProgress: onProgress,
          );
        } else {
          // Linux / Desktop → FFmpeg مش متاح، نجرب Dio مباشرة
          // (يشتغل لو الـ server بيرجع MP4 في الـ URL)
          await _downloadMp4(
            url: url,
            outputPath: filePath,
            onProgress: onProgress,
            cancelToken: cancelToken,
          );
        }
      } else {
        await _downloadMp4(
          url: url,
          outputPath: filePath,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
      }

      final file = File(filePath);
      if (!await file.exists()) throw 'الملف لم يُنشأ — تحقق من الرابط.';

      final size = await file.length();
      final model = DownloadedLessonModel(
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        courseId: courseId,
        courseTitle: courseTitle,
        courseImage: courseImage,
        localPath: filePath,
        fileSizeBytes: size,
        downloadedAt: DateTime.now(),
        originalUrl: url,
      );

      await _saveLesson(model);
      return model;
    } catch (e) {
      // Clean up partial file
      await _safeDelete(filePath);
      return null;
    }
  }

  /// Deletes a downloaded lesson and removes it from the catalog.
  static Future<void> deleteLesson(int lessonId) async {
    final lessons = await getDownloadedLessons();
    final target = lessons.where((l) => l.lessonId == lessonId).firstOrNull;
    if (target != null) await _safeDelete(target.localPath);

    final updated = lessons.where((l) => l.lessonId != lessonId).toList();
    await _persistList(updated);
  }

  /// Total storage used by all downloaded files.
  static Future<int> totalStorageUsedBytes() async {
    final list = await getDownloadedLessons();
    int total = 0;
    for (final l in list) {
      total += l.fileSizeBytes;
    }
    return total;
  }

  // ──────────────────────────── HLS Download ──────────────────────────────────

  /// Uses FFmpeg to download an HLS stream and mux it into a single MP4 file.
  /// FFmpeg handles:
  ///   1. Parsing the .m3u8 manifest
  ///   2. Downloading all .ts segments
  ///   3. Muxing them into a single MP4
  static Future<void> _downloadHls({
    required String url,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) async {
    // FFmpeg log callback to extract progress for HLS
    FFmpegKitConfig.enableLogCallback(null);
    FFmpegKitConfig.enableStatisticsCallback((stats) {
      // HLS duration is unknown upfront; use time-based estimate
      // stats.getTime() gives milliseconds processed
      final ms = stats.getTime();
      if (ms > 0 && onProgress != null) {
        // Approximate: signal that we're actively downloading
        // We clamp to 0.95 so the completion (1.0) is only on success
        final approx = (ms / 1000 / 60).clamp(0.0, 0.95); // rough min-based
        onProgress(approx);
      }
    });

    // FFmpeg command:
    // -i           → input URL (HLS manifest)
    // -c copy      → copy streams without re-encoding (fast)
    // -bsf:a       → fix AAC ADTS headers for MP4 container
    // -y           → overwrite output if exists
    final session = await FFmpegKit.execute(
      '-i "$url" -c copy -bsf:a aac_adtstoasc -y "$outputPath"',
    );

    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      throw 'FFmpeg فشل في تحميل الـ HLS — كود الخطأ: ${returnCode?.getValue()}';
    }

    onProgress?.call(1.0);
  }

  // ──────────────────────────── MP4 Download ──────────────────────────────────

  static Future<void> _downloadMp4({
    required String url,
    required String outputPath,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dio = Dio();
    await dio.download(
      url,
      outputPath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );
  }

  // ──────────────────────────── Helpers ───────────────────────────────────────

  static Future<Directory> _getDownloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/ofoq_downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> _saveLesson(DownloadedLessonModel model) async {
    final list = await getDownloadedLessons();
    final updated = list.where((l) => l.lessonId != model.lessonId).toList()
      ..add(model);
    await _persistList(updated);
  }

  static Future<void> _persistList(List<DownloadedLessonModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, DownloadedLessonModel.listToJson(list));
  }

  static Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
