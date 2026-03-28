import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/home/presentation/screens/home_screen.dart';
import 'package:ofoq_student_app/features/offline/presentation/screens/downloaded_courses_screen.dart';
import 'package:ofoq_student_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreenContent(),
    DownloadedCoursesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return connectivity.when(
      data: (results) {
        final isOffline = results.contains(ConnectivityResult.none);

        if (isOffline) {
          return _OfflineShell(isDark: isDark, colorScheme: colorScheme);
        }

        return _OnlineShell(
          currentIndex: _currentIndex,
          screens: _screens,
          onTabChange: (idx) => setState(() => _currentIndex = idx),
          isDark: isDark,
          colorScheme: colorScheme,
        );
      },
      loading: () => _OnlineShell(
        currentIndex: _currentIndex,
        screens: _screens,
        onTabChange: (idx) => setState(() => _currentIndex = idx),
        isDark: isDark,
        colorScheme: colorScheme,
      ),
      error: (_, __) => _OnlineShell(
        currentIndex: _currentIndex,
        screens: _screens,
        onTabChange: (idx) => setState(() => _currentIndex = idx),
        isDark: isDark,
        colorScheme: colorScheme,
      ),
    );
  }
}

class _OnlineShell extends StatelessWidget {
  final int currentIndex;
  final List<Widget> screens;
  final Function(int) onTabChange;
  final bool isDark;
  final ColorScheme colorScheme;

  const _OnlineShell({
    required this.currentIndex,
    required this.screens,
    required this.onTabChange,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1B2E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.06),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isSelected: currentIndex == 0,
                  onTap: () => onTabChange(0),
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
                _NavBarItem(
                  icon: Icons.download_rounded,
                  label: 'المحمل',
                  isSelected: currentIndex == 1,
                  onTap: () => onTabChange(1),
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
                _NavBarItem(
                  icon: Icons.settings_rounded,
                  label: 'الإعدادات',
                  isSelected: currentIndex == 2,
                  onTap: () => onTabChange(2),
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme colorScheme;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : (isDark ? Colors.white54 : Colors.grey),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfflineShell extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;

  const _OfflineShell({required this.isDark, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Offline Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.redAccent.shade700, Colors.red],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'لا يوجد اتصال بالإنترنت - وضع عدم الاتصال',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: DownloadedCoursesScreen()),
        ],
      ),
    );
  }
}
