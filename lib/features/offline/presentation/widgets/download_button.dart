import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/offline/presentation/providers/download_providers.dart';

/// A smart download button that shows:
/// - ⬇ Download icon  → not downloaded
/// - Circular progress → currently downloading
/// - ✅ Check icon     → already downloaded (tap to delete)
class DownloadButton extends ConsumerWidget {
  final int lessonId;
  final String lessonTitle;
  final int courseId;
  final String courseTitle;
  final String? courseImage;
  final String videoUrl;

  const DownloadButton({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.courseId,
    required this.courseTitle,
    this.courseImage,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadNotifierProvider);
    final isDownloading = downloadState.activeDownloads.containsKey(lessonId);
    final progress = downloadState.activeDownloads[lessonId] ?? 0.0;
    final downloadedAsync = ref.watch(isLessonDownloadedProvider(lessonId));

    if (isDownloading) {
      return GestureDetector(
        onTap: () => ref
            .read(downloadNotifierProvider.notifier)
            .cancelDownload(lessonId),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                color: Colors.blue,
                backgroundColor: Colors.blue.withOpacity(0.2),
              ),
              const Icon(Icons.close, size: 14, color: Colors.blue),
            ],
          ),
        ),
      );
    }

    return downloadedAsync.when(
      data: (isDownloaded) {
        if (isDownloaded) {
          return GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.download_done,
                size: 18,
                color: Colors.green,
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            ref
                .read(downloadNotifierProvider.notifier)
                .startDownload(
                  lessonId: lessonId,
                  lessonTitle: lessonTitle,
                  courseId: courseId,
                  courseTitle: courseTitle,
                  courseImage: courseImage,
                  rawUrl: videoUrl,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.download, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'جارٍ تحميل "$lessonTitle"…',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF2563EB),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.file_download_outlined,
              size: 18,
              color: Colors.blue,
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف التحميل؟'),
        content: Text('هل تريد حذف "$lessonTitle" من التحميلات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(downloadNotifierProvider.notifier).deleteDownload(lessonId);
    }
  }
}
