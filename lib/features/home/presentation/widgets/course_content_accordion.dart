import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/home/data/models/course_model.dart';
import 'package:ofoq_student_app/features/offline/presentation/providers/download_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ofoq_student_app/features/home/presentation/widgets/lesson_players/lesson_video_player.dart';
import 'package:ofoq_student_app/features/home/presentation/widgets/lesson_players/lesson_pdf_viewer.dart';
import 'package:ofoq_student_app/features/home/presentation/widgets/lesson_players/lesson_exam_player.dart';

class CourseContentAccordion extends ConsumerStatefulWidget {
  final List<ChapterModel> chapters;
  final bool isSubscribed;
  final String studentName;
  final String? studentPhone;
  final int courseId;
  final String courseTitle;
  final String? courseImage;

  const CourseContentAccordion({
    super.key,
    required this.chapters,
    required this.isSubscribed,
    required this.studentName,
    this.studentPhone,
    required this.courseId,
    required this.courseTitle,
    this.courseImage,
  });

  @override
  ConsumerState<CourseContentAccordion> createState() =>
      _CourseContentAccordionState();
}

class _CourseContentAccordionState
    extends ConsumerState<CourseContentAccordion> {
  final Set<int> _expandedChapters = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: widget.chapters.asMap().entries.map((entry) {
        final index = entry.key;
        final chapter = entry.value;
        final isExpanded = _expandedChapters.contains(index);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222340) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.06),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // Chapter header
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedChapters.remove(index);
                    } else {
                      _expandedChapters.add(index);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(
                                isDark ? 0.25 : 0.12,
                              ),
                              Theme.of(context).colorScheme.secondary
                                  .withOpacity(isDark ? 0.15 : 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1B2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${chapter.lessons?.length ?? 0} درس',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white54 : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Lessons
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: (chapter.lessons ?? []).map((lesson) {
                    return _LessonTile(
                      lesson: lesson,
                      isSubscribed: widget.isSubscribed,
                      studentName: widget.studentName,
                      studentPhone: widget.studentPhone,
                      courseId: widget.courseId,
                      courseTitle: widget.courseTitle,
                      courseImage: widget.courseImage,
                      isDark: isDark,
                    );
                  }).toList(),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LessonTile extends ConsumerWidget {
  final LessonModel lesson;
  final bool isSubscribed;
  final String studentName;
  final String? studentPhone;
  final int courseId;
  final String courseTitle;
  final String? courseImage;
  final bool isDark;

  const _LessonTile({
    required this.lesson,
    required this.isSubscribed,
    required this.studentName,
    this.studentPhone,
    required this.courseId,
    required this.courseTitle,
    this.courseImage,
    required this.isDark,
  });

  IconData _typeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_filled_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'exam':
        return Icons.quiz_rounded;
      case 'live':
        return Icons.live_tv_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'video':
        return Colors.blue;
      case 'pdf':
        return Colors.red;
      case 'exam':
        return Colors.orange;
      case 'live':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'video':
        return 'فيديو';
      case 'pdf':
        return 'PDF';
      case 'exam':
        return 'امتحان';
      case 'live':
        return 'بث مباشر';
      default:
        return type;
    }
  }

  void _openLesson(BuildContext context) {
    if (!isSubscribed) return;

    switch (lesson.type) {
      case 'video':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: LessonVideoPlayer(
                  lesson: lesson,
                  onClose: () => Navigator.pop(ctx),
                  studentName: studentName,
                  studentPhone: studentPhone,
                ),
              ),
            ),
          ),
        );
        break;
      case 'pdf':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: LessonPDFViewer(
                  lesson: lesson,
                  onClose: () => Navigator.pop(ctx),
                  studentName: studentName,
                  studentPhone: studentPhone,
                ),
              ),
            ),
          ),
        );
        break;
      case 'exam':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: LessonExamPlayer(
                  lesson: lesson,
                  onClose: () => Navigator.pop(ctx),
                  studentName: studentName,
                  studentPhone: studentPhone,
                ),
              ),
            ),
          ),
        );
        break;
      case 'live':
        if (lesson.liveSessionId != null) {
          launchUrl(
            Uri.parse(lesson.liveSessionId!),
            mode: LaunchMode.externalApplication,
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _typeColor(lesson.type);

    return InkWell(
      onTap: isSubscribed ? () => _openLesson(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.grey.withOpacity(0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSubscribed
                    ? _typeIcon(lesson.type)
                    : Icons.lock_outline_rounded,
                color: isSubscribed ? color : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _typeLabel(lesson.type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      if (lesson.duration != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${lesson.duration} دقيقة',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Download button for videos (subscribed only)
            if (isSubscribed &&
                lesson.type == 'video' &&
                lesson.videoUrl != null)
              _DownloadButton(
                lesson: lesson,
                courseId: courseId,
                courseTitle: courseTitle,
                courseImage: courseImage,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends ConsumerWidget {
  final LessonModel lesson;
  final int courseId;
  final String courseTitle;
  final String? courseImage;
  final bool isDark;
  final ColorScheme colorScheme;

  const _DownloadButton({
    required this.lesson,
    required this.courseId,
    required this.courseTitle,
    this.courseImage,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadNotifierProvider);
    final isDownloading = downloadState.activeDownloads.containsKey(lesson.id);
    final double progress = downloadState.activeDownloads[lesson.id] ?? 0.0;

    // Check if already downloaded
    final downloadedLessonsAsync = ref.watch(downloadedLessonsProvider);
    final isDownloaded =
        downloadedLessonsAsync.whenOrNull(
          data: (lessons) {
            return lessons.any((l) => l.lessonId == lesson.id);
          },
        ) ??
        false;

    if (isDownloaded) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.download_done_rounded,
          color: Colors.green,
          size: 20,
        ),
      );
    }

    if (isDownloading) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
            Text(
              '${(progress * 100).toInt()}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white70 : const Color(0xFF1A1B2E),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        ref
            .read(downloadNotifierProvider.notifier)
            .startDownload(
              lessonId: lesson.id,
              lessonTitle: lesson.title,
              rawUrl: lesson.videoUrl!,
              courseId: courseId,
              courseTitle: courseTitle,
              courseImage: courseImage,
            );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.download_rounded,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
