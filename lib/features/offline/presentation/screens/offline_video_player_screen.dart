import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:ofoq_student_app/features/offline/data/models/downloaded_lesson_model.dart';
import 'package:ofoq_student_app/core/utils/content_protection.dart';
import 'package:ofoq_student_app/features/home/presentation/widgets/lesson_players/watermark_overlay.dart';

/// Full-screen video player for locally-downloaded (offline) lessons.
class OfflineVideoPlayerScreen extends ConsumerStatefulWidget {
  final DownloadedLessonModel lesson;
  final String studentName;
  final String? studentPhone;

  const OfflineVideoPlayerScreen({
    super.key,
    required this.lesson,
    required this.studentName,
    this.studentPhone,
  });

  @override
  ConsumerState<OfflineVideoPlayerScreen> createState() =>
      _OfflineVideoPlayerScreenState();
}

class _OfflineVideoPlayerScreenState
    extends ConsumerState<OfflineVideoPlayerScreen> {
  late VideoPlayerController _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    ContentProtection.enable();
    _init();
  }

  Future<void> _init() async {
    try {
      final file = File(widget.lesson.localPath);
      if (!await file.exists()) {
        throw 'الملف غير موجود على الجهاز، يرجى إعادة التحميل.';
      }
      _videoCtrl = VideoPlayerController.file(file);
      await _videoCtrl.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoCtrl.value.aspectRatio,
        placeholder: const Center(child: CircularProgressIndicator()),
        errorBuilder: (ctx, msg) => Center(
          child: Text(msg, style: const TextStyle(color: Colors.white)),
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    _chewieCtrl?.dispose();
    ContentProtection.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildPlayer()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF0F1117),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.offline_bolt,
              color: Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lesson.lessonTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.download_done,
                      color: Colors.green,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'محفوظ • ${widget.lesson.fileSizeFormatted}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white54, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'جارٍ تحميل الفيديو…',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Chewie(controller: _chewieCtrl!),
        WatermarkOverlay(
          studentName: widget.studentName,
          studentPhone: widget.studentPhone,
          animate: false,
        ),
        WatermarkOverlay(
          studentName: widget.studentName,
          studentPhone: widget.studentPhone,
          animate: true,
        ),
      ],
    );
  }
}
