import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/home/presentation/providers/layout_provider.dart';
import 'package:ofoq_student_app/core/utils/image_helper.dart';
import 'package:ofoq_student_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ofoq_student_app/features/home/presentation/providers/dashboard_providers.dart';
import 'package:ofoq_student_app/core/widgets/student_heatmap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ofoq_student_app/core/api/api_provider.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';
import 'package:ofoq_student_app/features/home/presentation/widgets/course_card.dart';

class HomeScreenContent extends ConsumerStatefulWidget {
  const HomeScreenContent({super.key});

  @override
  ConsumerState<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<HomeScreenContent> {
  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(layoutProvider);
    final authState = ref.watch(authProvider);
    final activeTab = ref.watch(activeTabProvider);
    final student = authState.studentData;

    return layoutAsync.when(
      data: (layout) => Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Hero Banner
            _buildHeroBanner(context, layout, student),

            // 2. Stats Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: _buildStatsRow(context, ref),
              ),
            ),

            // 3. Tab Navigation
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTabNavigation(context, ref, activeTab),
              ),
            ),

            // 4. Tab Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _renderTabContent(
                  context,
                  ref,
                  activeTab,
                  student,
                  layout,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildHeroBanner(BuildContext context, layout, student) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = (student?['name'] ?? 'ط')
        .split(' ')
        .take(2)
        .map((e) => e[0])
        .join('');

    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
            ),
            // Decorative shapes
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            // Small decorative dots
            Positioned(
              top: 80,
              right: 30,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: 60,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Colors.white24, Colors.white10],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      image:
                          (student?['image'] != null &&
                              student!['image'].isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(
                                ImageHelper.getFullUrl(student['image']),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child:
                        (student?['image'] == null || student!['image'].isEmpty)
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  // Info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'طالب نشط ✦',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          student?['name'] ?? 'أهلاً بك يا بطل!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_android_outlined,
                              color: Colors.white.withOpacity(0.6),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student?['phone'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Icon(
                              Icons.school_outlined,
                              color: Colors.white.withOpacity(0.6),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                student?['educational_stage']?['name'] ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildStatsRow(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final student = ref.watch(authProvider).studentData;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            context,
            icon: '🔥',
            label: 'أيام النشاط',
            value: progressAsync.when(
              data: (data) => data
                  .map(
                    (e) => (e['updated_at'] ?? e['UpdatedAt']).toString().split(
                      'T',
                    )[0],
                  )
                  .toSet()
                  .length
                  .toString(),
              loading: () => '...',
              error: (_, __) => '0',
            ),
            colors: [Colors.orange, Colors.redAccent],
            isDark: isDark,
          ),
          _buildStatCard(
            context,
            icon: '📚',
            label: 'دروس مكتملة',
            value: progressAsync.when(
              data: (data) => data
                  .where((e) => e['is_completed'] == true)
                  .length
                  .toString(),
              loading: () => '...',
              error: (_, __) => '0',
            ),
            colors: [Colors.blue, Colors.cyan],
            isDark: isDark,
          ),
          _buildStatCard(
            context,
            icon: '⭐',
            label: 'نقاطي',
            value: (student?['points'] ?? 0).toString(),
            colors: [Colors.amber, Colors.orangeAccent],
            isDark: isDark,
          ),
          _buildStatCard(
            context,
            icon: '💰',
            label: 'المحفظة',
            value: '${student?['balance'] ?? 0} ج',
            colors: [const Color(0xFF10B981), Colors.green],
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required List<Color> colors,
    required bool isDark,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222340) : Colors.white,
        borderRadius: BorderRadius.circular(22),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors
                    .map((c) => c.withOpacity(isDark ? 0.25 : 0.15))
                    .toList(),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1A1B2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation(
    BuildContext context,
    WidgetRef ref,
    String activeTab,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final tabs = [
      {'id': 'courses', 'label': 'كورساتي', 'icon': Icons.book_outlined},
      {
        'id': 'progress',
        'label': 'المتابعة',
        'icon': Icons.video_library_outlined,
      },
      {
        'id': 'wallet',
        'label': 'المحفظة',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'id': 'assignments',
        'label': 'الواجبات',
        'icon': Icons.assignment_outlined,
      },
      {'id': 'exams', 'label': 'الامتحانات', 'icon': Icons.quiz_outlined},
      {
        'id': 'leaderboard',
        'label': 'لوحة الشرف',
        'icon': Icons.emoji_events_outlined,
      },
      {'id': 'id_card', 'label': 'البطاقة', 'icon': Icons.qr_code_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222340) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.08),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = activeTab == tab['id'];
            return GestureDetector(
              onTap: () => ref
                  .read(activeTabProvider.notifier)
                  .setTab(tab['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 17,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.grey),
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _renderTabContent(
    BuildContext context,
    WidgetRef ref,
    String activeTab,
    student,
    layout,
  ) {
    switch (activeTab) {
      case 'courses':
        return _buildCoursesTab(ref, student);
      case 'progress':
        return _buildProgressTab(ref);
      case 'wallet':
        return _buildWalletTab(context, ref, student);
      case 'exams':
        return _buildExamsTab(ref);
      case 'assignments':
        return _buildAssignmentsTab(ref);
      case 'leaderboard':
        return _buildLeaderboardTab(ref, student);
      case 'id_card':
        return _buildIdCardTab(context, student, layout);
      default:
        return const SizedBox();
    }
  }

  // ══ TAB RENDERERS ══

  Widget _buildCoursesTab(WidgetRef ref, student) {
    final coursesAsync = ref.watch(coursesProvider);
    final enrolledIds = (student?['enrolled_course_ids'] as List?) ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return coursesAsync.when(
      data: (courses) {
        final subscribed = courses
            .where(
              (c) => enrolledIds
                  .map((id) => id.toString())
                  .contains(c['id'].toString()),
            )
            .toList();
        final available = courses
            .where(
              (c) => !enrolledIds
                  .map((id) => id.toString())
                  .contains(c['id'].toString()),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('كورساتي المشترك فيها', isDark),
            const SizedBox(height: 15),
            subscribed.isEmpty
                ? _buildEmptyState('لا يوجد كورسات مشترك بها حالياً')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: subscribed
                          .map<Widget>(
                            (c) => CourseCard(course: c, isSubscribed: true),
                          )
                          .toList(),
                    ),
                  ),
            const SizedBox(height: 30),
            _buildSectionTitle('كورسات متاحة لمرحلتك', isDark),
            const SizedBox(height: 15),
            available.isEmpty
                ? _buildEmptyState('لا يوجد كورسات أخرى متاحة')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: available
                          .map<Widget>((c) => CourseCard(course: c))
                          .toList(),
                    ),
                  ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Error: $err'),
    );
  }

  Widget _buildProgressTab(WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return progressAsync.when(
      data: (data) => Column(
        children: [
          StudentHeatmap(
            progressData: data,
            primaryColor: Theme.of(context).colorScheme.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          ...data.map(
            (p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222340) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.06),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        (p['is_completed'] == true ? Colors.green : Colors.blue)
                            .withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    p['is_completed'] == true
                        ? Icons.check_circle_rounded
                        : Icons.play_circle_outline_rounded,
                    color: p['is_completed'] == true
                        ? Colors.green
                        : Colors.blue,
                    size: 22,
                  ),
                ),
                title: Text(
                  'درس #${p['lesson_id']} - ${p['title'] ?? 'فيديو فني'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                  ),
                ),
                subtitle: Text(
                  'شاهدت ${((p['progress_seconds'] ?? 0) / 60).floor()} دقيقة',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildWalletTab(BuildContext context, WidgetRef ref, student) {
    final voucherController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'الرصيد المتاح',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${student?['balance'] ?? 0} ج.م',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222340) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.08),
            ),
          ),
          child: TextField(
            controller: voucherController,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1B2E),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'أدخل كود الشحن',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () async {
                    final api = ref.read(apiConsumerProvider);
                    try {
                      await api.post(
                        EndPoints.chargeVoucher,
                        data: {'code': voucherController.text},
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم الشحن بنجاح!')),
                      );
                      ref.refresh(authProvider);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: ${e.toString()}')),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamsTab(WidgetRef ref) {
    final examsAsync = ref.watch(availableExamsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return examsAsync.when(
      data: (exams) => Column(
        children: exams
            .map(
              (ex) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222340) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('📝', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex['title'],
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
                            'المدة: ${ex['duration_minutes']} دقيقة | ${ex['questions_count']} سؤال',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ابدأ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildAssignmentsTab(WidgetRef ref) {
    final asAsync = ref.watch(assignmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return asAsync.when(
      data: (list) => Column(
        children: list
            .map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222340) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color:
                            (a['submitted'] == true
                                    ? Colors.green
                                    : Colors.purple)
                                .withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          a['submitted'] == true ? '✅' : '📋',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title'],
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
                            a['course_name'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (a['submitted'] == true
                                    ? Colors.green
                                    : Colors.orange)
                                .withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        a['submitted'] == true ? 'تم التسليم' : 'بانتظار الحل',
                        style: TextStyle(
                          color: a['submitted'] == true
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildLeaderboardTab(WidgetRef ref, student) {
    final lbAsync = ref.watch(leaderboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return lbAsync.when(
      data: (list) => Column(
        children: [
          _buildSectionTitle('تصنيف الطلاب 🏆', isDark),
          const SizedBox(height: 15),
          ...list.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final isMe = s['id'] == student?['id'];
            final isTop3 = idx < 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? colorScheme.primary.withOpacity(isDark ? 0.15 : 0.06)
                    : (isDark ? const Color(0xFF222340) : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isMe
                      ? colorScheme.primary.withOpacity(0.3)
                      : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey.withOpacity(0.06)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isTop3
                          ? LinearGradient(
                              colors: idx == 0
                                  ? [Colors.amber, Colors.orange]
                                  : idx == 1
                                  ? [Colors.grey.shade400, Colors.grey.shade300]
                                  : [
                                      Colors.brown.shade300,
                                      Colors.brown.shade200,
                                    ],
                            )
                          : null,
                      color: isTop3
                          ? null
                          : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        isTop3 ? ['🥇', '🥈', '🥉'][idx] : '${idx + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isTop3 ? 18 : 14,
                          color: isTop3
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      s['name'],
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 14,
                        color: isMe
                            ? colorScheme.primary
                            : (isDark ? Colors.white : const Color(0xFF1A1B2E)),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${s['points']} نقطة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.amber : Colors.amber.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildIdCardTab(BuildContext context, student, layout) {
    final studentData = {
      'id': student?['id'],
      'name': student?['name'],
      'phone': student?['phone'],
      'auth': 'student_auth',
    };
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222340) : Colors.white,
          borderRadius: BorderRadius.circular(28),
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
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top decoration bar
            Container(
              height: 5,
              width: 80,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Text(
              layout.theme.platformName,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'البطاقة الذكية للطالب',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: studentData.toString(),
                version: QrVersions.auto,
                size: 180.0,
                gapless: false,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: isDark ? Colors.white : Colors.black,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              student?['name'] ?? '',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1A1B2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              student?['phone'] ?? '',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ofoq Platform | أفق',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1A1B2E),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.08),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Text('📭', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              msg,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
