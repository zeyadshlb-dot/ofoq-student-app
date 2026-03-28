import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/offline/data/models/downloaded_lesson_model.dart';
import 'package:ofoq_student_app/features/offline/data/services/video_download_service.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';

// ─── State classes ──────────────────────────────────────────────────────────

class DownloadState {
  /// lessonId → progress 0.0–1.0, or -1 if failed
  final Map<int, double> activeDownloads;
  final Map<int, CancelToken> cancelTokens;

  const DownloadState({
    this.activeDownloads = const {},
    this.cancelTokens = const {},
  });

  DownloadState copyWith({
    Map<int, double>? activeDownloads,
    Map<int, CancelToken>? cancelTokens,
  }) => DownloadState(
    activeDownloads: activeDownloads ?? this.activeDownloads,
    cancelTokens: cancelTokens ?? this.cancelTokens,
  );
}

// ─── Download notifier ───────────────────────────────────────────────────────

class DownloadNotifier extends Notifier<DownloadState> {
  @override
  DownloadState build() => const DownloadState();

  bool isDownloading(int lessonId) =>
      state.activeDownloads.containsKey(lessonId);

  double progressOf(int lessonId) => state.activeDownloads[lessonId] ?? 0.0;

  Future<void> startDownload({
    required int lessonId,
    required String lessonTitle,
    required int courseId,
    required String courseTitle,
    String? courseImage,
    required String rawUrl,
  }) async {
    if (isDownloading(lessonId)) return;

    // Resolve full URL (same logic as LessonVideoPlayer)
    String url = rawUrl;
    if (!url.startsWith('http')) {
      if (url.startsWith('/')) url = url.substring(1);
      if (url.startsWith('public/storage/')) {
        url = '${EndPoints.imageBaseUrl}$url';
      } else if (url.startsWith('storage/')) {
        url = '${EndPoints.imageBaseUrl}public/$url';
      } else {
        url = '${EndPoints.imageBaseUrl}public/storage/$url';
      }
    }

    final cancelToken = CancelToken();

    // Register as active
    state = state.copyWith(
      activeDownloads: {...state.activeDownloads, lessonId: 0.0},
      cancelTokens: {...state.cancelTokens, lessonId: cancelToken},
    );

    await VideoDownloadService.downloadVideo(
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      courseId: courseId,
      courseTitle: courseTitle,
      courseImage: courseImage,
      url: url,
      cancelToken: cancelToken,
      onProgress: (p) {
        final updated = Map<int, double>.from(state.activeDownloads)
          ..[lessonId] = p;
        state = state.copyWith(activeDownloads: updated);
      },
    );

    // Remove from active downloads when done
    final updatedDownloads = Map<int, double>.from(state.activeDownloads)
      ..remove(lessonId);
    final updatedTokens = Map<int, CancelToken>.from(state.cancelTokens)
      ..remove(lessonId);

    state = state.copyWith(
      activeDownloads: updatedDownloads,
      cancelTokens: updatedTokens,
    );

    // Refresh the downloaded lessons list
    ref.invalidate(downloadedLessonsProvider);
  }

  void cancelDownload(int lessonId) {
    state.cancelTokens[lessonId]?.cancel();
    final updatedDownloads = Map<int, double>.from(state.activeDownloads)
      ..remove(lessonId);
    final updatedTokens = Map<int, CancelToken>.from(state.cancelTokens)
      ..remove(lessonId);
    state = state.copyWith(
      activeDownloads: updatedDownloads,
      cancelTokens: updatedTokens,
    );
  }

  Future<void> deleteDownload(int lessonId) async {
    await VideoDownloadService.deleteLesson(lessonId);
    ref.invalidate(downloadedLessonsProvider);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final downloadNotifierProvider =
    NotifierProvider<DownloadNotifier, DownloadState>(() => DownloadNotifier());

final downloadedLessonsProvider = FutureProvider<List<DownloadedLessonModel>>((
  ref,
) async {
  return VideoDownloadService.getDownloadedLessons();
});

/// Whether a specific lesson is already downloaded (cached check).
final isLessonDownloadedProvider = FutureProvider.family<bool, int>((
  ref,
  lessonId,
) async {
  return VideoDownloadService.isDownloaded(lessonId);
});

final totalStorageUsedProvider = FutureProvider<int>((ref) async {
  // Depend on the downloaded list so it refreshes automatically
  ref.watch(downloadedLessonsProvider);
  return VideoDownloadService.totalStorageUsedBytes();
});
