import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:ofoq_student_app/features/home/data/models/course_model.dart';
import 'package:ofoq_student_app/core/utils/content_protection.dart';
import 'package:ofoq_student_app/features/home/presentation/widgets/lesson_players/watermark_overlay.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';

class LessonVideoPlayer extends StatefulWidget {
  final LessonModel lesson;
  final VoidCallback onClose;
  final String studentName;
  final String? studentPhone;

  const LessonVideoPlayer({
    super.key,
    required this.lesson,
    required this.onClose,
    required this.studentName,
    this.studentPhone,
  });

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    ContentProtection.enable();
  }

  Future<void> _initializePlayer() async {
    try {
      String url = widget.lesson.videoUrl ?? '';
      if (url.isEmpty) {
        throw 'Video URL not found.';
      }

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

      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));

      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    ContentProtection.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: [_buildHeader(), _buildPlayer()]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.lesson.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Text('❌ $_error', style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio,
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),
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
      ),
    );
  }
}
