import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/offline/data/models/downloaded_lesson_model.dart';
import 'package:ofoq_student_app/features/offline/presentation/providers/download_providers.dart';
import 'package:ofoq_student_app/features/offline/presentation/screens/offline_video_player_screen.dart';
import 'package:ofoq_student_app/features/auth/presentation/providers/auth_provider.dart';

/// Screen displayed in the "دروسي المحملة" navigation tab.
/// Groups downloaded lessons by course and allows watching offline.
class DownloadedCoursesScreen extends ConsumerWidget {
  const DownloadedCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(downloadedLessonsProvider);
    final storageAsync = ref.watch(totalStorageUsedProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF12131E)
          : const Color(0xFFF6F7FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -10,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.offline_bolt_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'كورساتي المحملة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    'شاهد دروسك بدون انترنت 📲',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Storage badge
                          storageAsync.when(
                            data: (bytes) => _StorageBadge(bytes: bytes),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: lessonsAsync.when(
              data: (lessons) => lessons.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(isDark: isDark),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, i) {
                        final grouped = _groupByCourse(lessons);
                        final courseId = grouped.keys.elementAt(i);
                        final courseLessons = grouped[courseId]!;
                        return _CourseGroup(
                          courseTitle: courseLessons.first.courseTitle,
                          courseImage: courseLessons.first.courseImage,
                          lessons: courseLessons,
                          ref: ref,
                          context: ctx,
                          isDark: isDark,
                        );
                      }, childCount: _groupByCourse(lessons).length),
                    ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('خطأ: $e')),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Map<int, List<DownloadedLessonModel>> _groupByCourse(
    List<DownloadedLessonModel> lessons,
  ) {
    final map = <int, List<DownloadedLessonModel>>{};
    for (final l in lessons) {
      map.putIfAbsent(l.courseId, () => []).add(l);
    }
    return map;
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StorageBadge extends StatelessWidget {
  final int bytes;
  const _StorageBadge({required this.bytes});

  String _format(int b) {
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storage_rounded, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            'المساحة المستخدمة: ${_format(bytes)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                    colorScheme.secondary.withOpacity(isDark ? 0.15 : 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📥', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد فيديوهات محملة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1A1B2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'افتح أي كورس مشترك فيه\nواضغط على زر التحميل بجانب أي درس فيديو',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اضغط على أيقونة ⬇️ بجانب أي درس',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseGroup extends ConsumerWidget {
  final String courseTitle;
  final String? courseImage;
  final List<DownloadedLessonModel> lessons;
  final WidgetRef ref;
  final BuildContext context;
  final bool isDark;

  const _CourseGroup({
    required this.courseTitle,
    this.courseImage,
    required this.lessons,
    required this.ref,
    required this.context,
    required this.isDark,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef r) {
    final student = r.watch(authProvider).studentData;
    final studentName = (student?['name'] ?? 'طالب').toString();
    final studentPhone = student?['phone']?.toString();
    final colorScheme = Theme.of(ctx).colorScheme;

    final totalMB = lessons.fold(0, (s, l) => s + l.fileSizeBytes);
    final totalStr = totalMB < 1024 * 1024
        ? '${(totalMB / 1024).toStringAsFixed(0)} KB'
        : '${(totalMB / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222340) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
                  colorScheme.secondary.withOpacity(isDark ? 0.06 : 0.03),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('📚', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1B2E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _chip('${lessons.length} درس', Colors.blue, isDark),
                          const SizedBox(width: 8),
                          _chip(totalStr, const Color(0xFF10B981), isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lessons
          ...lessons.map(
            (lesson) => _LessonTile(
              lesson: lesson,
              studentName: studentName,
              studentPhone: studentPhone,
              isDark: isDark,
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: ctx,
                  builder: (c) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF222340)
                        : Colors.white,
                    title: Text(
                      'حذف الفيديو؟',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                      ),
                    ),
                    content: Text(
                      'هل تريد حذف "${lesson.lessonTitle}" من التحميلات؟',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: Text(
                          'لا',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(c, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'حذف',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  r
                      .read(downloadNotifierProvider.notifier)
                      .deleteDownload(lesson.lessonId);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
    ),
  );
}

class _LessonTile extends StatelessWidget {
  final DownloadedLessonModel lesson;
  final String studentName;
  final String? studentPhone;
  final VoidCallback onDelete;
  final bool isDark;

  const _LessonTile({
    required this.lesson,
    required this.studentName,
    this.studentPhone,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfflineVideoPlayerScreen(
            lesson: lesson,
            studentName: studentName,
            studentPhone: studentPhone,
          ),
        ),
      ),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(isDark ? 0.25 : 0.15),
                    colorScheme.secondary.withOpacity(isDark ? 0.15 : 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.lessonTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.download_done_rounded,
                        color: const Color(0xFF10B981),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lesson.fileSizeFormatted,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.access_time_rounded,
                        color: isDark ? Colors.white38 : Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(lesson.downloadedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
