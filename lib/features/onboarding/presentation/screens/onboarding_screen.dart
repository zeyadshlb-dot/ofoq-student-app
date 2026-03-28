import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ofoq_student_app/features/home/presentation/providers/layout_provider.dart';
import 'package:ofoq_student_app/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ofoq_student_app/features/auth/presentation/screens/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimController;
  late Animation<double> _iconBounce;

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconBounce = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _iconAnimController, curve: Curves.elasticOut),
    );
    _iconAnimController.forward();
  }

  @override
  void dispose() {
    _iconAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_onboarding', false);

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(layoutProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return layoutAsync.when(
      data: (layout) {
        final List<OnboardingData> pages = [
          OnboardingData(
            title: 'مرحباً بك في ${layout.theme.platformName}',
            description: layout.theme.metaDescription,
            icon: Icons.school_rounded,
            gradient: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.7),
            ],
          ),
          OnboardingData(
            title: 'تعلم بذكاء',
            description: 'نظام متكامل لمتابعة دروسك وامتحاناتك بكل سهولة ويسر.',
            icon: Icons.auto_awesome_rounded,
            gradient: [
              colorScheme.secondary,
              colorScheme.secondary.withOpacity(0.7),
            ],
          ),
          OnboardingData(
            title: 'انطلق الآن 🚀',
            description:
                'ابدأ رحلتك التعليمية مع نخبة من أفضل المعلمين في مصر.',
            icon: Icons.rocket_launch_rounded,
            gradient: [colorScheme.primary, colorScheme.secondary],
          ),
        ];

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF12131E), const Color(0xFF1A1B2E)]
                    : [Colors.white, const Color(0xFFF6F7FB)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top: Skip button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page indicator
                        Text(
                          '${_currentPage + 1}/${pages.length}',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            'تخطي',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page View
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _iconAnimController.reset();
                        _iconAnimController.forward();
                      },
                      itemBuilder: (context, index) {
                        return _buildPage(pages[index]);
                      },
                    ),
                  ),

                  // Bottom Controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      children: [
                        // Dot indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: _currentPage == index ? 32 : 6,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? colorScheme.primary
                                    : (isDark
                                          ? Colors.white.withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Next Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage == pages.length - 1) {
                                _completeOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              shadowColor: colorScheme.primary.withOpacity(0.3),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == pages.length - 1
                                      ? 'ابدأ الآن'
                                      : 'التالي',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == pages.length - 1
                                      ? Icons.arrow_forward_rounded
                                      : Icons.arrow_back_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildPage(OnboardingData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with gradient background
          ScaleTransition(
            scale: _iconBounce,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: data.gradient
                      .map((c) => c.withOpacity(isDark ? 0.2 : 0.1))
                      .toList(),
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: data.gradient.first.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: data.gradient
                        .map((c) => c.withOpacity(isDark ? 0.3 : 0.15))
                        .toList(),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, size: 60, color: colorScheme.primary),
              ),
            ),
          ),

          const SizedBox(height: 48),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1A1B2E),
              letterSpacing: -0.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
