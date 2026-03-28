import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ofoq_student_app/features/home/presentation/providers/layout_provider.dart';
import 'package:ofoq_student_app/features/auth/presentation/screens/register_screen.dart';
import 'package:ofoq_student_app/core/widgets/premium_widgets.dart';
import 'package:ofoq_student_app/features/home/presentation/screens/main_navigation_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useCode = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(layoutProvider);
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for auth state changes to navigate
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    });

    return layoutAsync.when(
      data: (layout) => Scaffold(
        body: Row(
          children: [
            // Left Side: Image (Desktop only)
            if (isDesktop)
              Expanded(
                flex: 42,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            layout.theme.heroImage.isNotEmpty
                                ? layout.theme.heroImage
                                : 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?q=80&w=2071',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            colorScheme.primary.withOpacity(0.9),
                            colorScheme.primary.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
                      left: 40,
                      right: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (layout.theme.logo.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Image.network(
                                layout.theme.logo,
                                height: 60,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Text(
                            'مرحباً بك في ${layout.theme.platformName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            layout.theme.metaDescription,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Right Side: Form
            Expanded(
              flex: 58,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF12131E), const Color(0xFF1A1B2E)]
                        : [Colors.white, const Color(0xFFF8F9FD)],
                  ),
                ),
                child: Stack(
                  children: [
                    const FloatingParticles(),
                    Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!isDesktop &&
                                      layout.theme.logo.isNotEmpty)
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.06)
                                              : colorScheme.primary.withOpacity(
                                                  0.05,
                                                ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.network(
                                          layout.theme.logo,
                                          height: 64,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 32),
                                  Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1A1B2E),
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'أدخل بياناتك للاستمرار واستكمال رحلتك',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade500,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 36),
                                  AnimatedInput(
                                    icon: Icons.phone_android_outlined,
                                    label: 'رقم الهاتف',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    hint: '01xxxxxxxxx',
                                  ),
                                  const SizedBox(height: 16),
                                  if (!_useCode)
                                    AnimatedInput(
                                      icon: Icons.lock_outline_rounded,
                                      label: 'كلمة المرور',
                                      controller: _passwordController,
                                      isPassword: true,
                                      hint: '••••••••',
                                    ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        foregroundColor: colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      child: const Text(
                                        'نسيت كلمة السر؟',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Switch Login Method
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.04)
                                          : colorScheme.primary.withOpacity(
                                              0.04,
                                            ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : colorScheme.primary.withOpacity(
                                                0.08,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 28,
                                          child: Switch(
                                            value: _useCode,
                                            onChanged: (val) =>
                                                setState(() => _useCode = val),
                                            activeColor: colorScheme.primary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'تسجيل الدخول عن طريق الكود',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF1A1B2E),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.lock_person_outlined,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // Login Button
                                  SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed:
                                          authState.status == AuthStatus.loading
                                          ? null
                                          : () {
                                              ref
                                                  .read(authProvider.notifier)
                                                  .login(
                                                    _phoneController.text,
                                                    _passwordController.text,
                                                    layout.tenantSlug,
                                                  );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child:
                                          authState.status == AuthStatus.loading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'تسجيل الدخول',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  '🚀',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterScreen(),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: colorScheme.primary,
                                        ),
                                        child: const Text(
                                          'انشئ حسابك الآن',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'لا يوجد لديك حساب؟',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade500,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (authState.errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.15),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                authState.errorMessage!,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
