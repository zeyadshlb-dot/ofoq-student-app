import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ofoq_student_app/core/theme/app_themes.dart';
import 'package:ofoq_student_app/core/theme/theme_provider.dart';
import 'package:ofoq_student_app/features/home/presentation/providers/layout_provider.dart';
import 'package:ofoq_student_app/features/onboarding/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final layoutAsync = ref.watch(layoutProvider);

    return layoutAsync.when(
      data: (layout) {
        return MaterialApp(
          title: layout.theme.platformName,
          debugShowCheckedModeBanner: false,
          theme: AppThemes.getThemeFromTenant(layout.theme, Brightness.light),
          darkTheme: AppThemes.getThemeFromTenant(
            layout.theme,
            Brightness.dark,
          ),
          themeMode: themeMode,
          home: const SplashScreen(), // Always start with SplashScreen
        );
      },
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (err, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }
}
