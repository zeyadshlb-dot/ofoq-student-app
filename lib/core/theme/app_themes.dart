import 'package:flutter/material.dart';
import 'package:ofoq_student_app/features/home/data/models/tenant_layout_model.dart';
import 'package:google_fonts/google_fonts.dart';

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class AppThemes {
  static ThemeData getThemeFromTenant(
    TenantTheme tenantTheme,
    Brightness brightness,
  ) {
    final primaryColor = HexColor.fromHex(tenantTheme.primaryColor);
    final secondaryColor = HexColor.fromHex(tenantTheme.secondaryColor);

    // Dynamic Font from Google Fonts
    TextStyle baseTextStyle;
    try {
      baseTextStyle = GoogleFonts.getFont(tenantTheme.font);
    } catch (e) {
      print(
        '⚠️ Font ${tenantTheme.font} not found in Google Fonts, falling back to Cairo.',
      );
      baseTextStyle = GoogleFonts.cairo(); // Safe fallback
    }

    final isDark = brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A1B2E) : Colors.white;
    final cardColor = isDark ? const Color(0xFF222340) : Colors.white;
    final scaffoldBg = isDark
        ? const Color(0xFF12131E)
        : const Color(0xFFF6F7FB);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: GoogleFonts.getTextTheme(tenantTheme.font).apply(
        bodyColor: isDark ? Colors.white : const Color(0xFF1A1B2E),
        displayColor: isDark ? Colors.white : const Color(0xFF1A1B2E),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        brightness: brightness,
        surface: surfaceColor,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? const Color(0xFF1A1B2E) : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF1A1B2E),
        ),
        titleTextStyle: baseTextStyle.copyWith(
          color: isDark ? Colors.white : const Color(0xFF1A1B2E),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            tenantTheme.borderRadius == 'pill' ? 28 : 20,
          ),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.08),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: baseTextStyle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              tenantTheme.borderRadius == 'pill' ? 30 : 16,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: isDark ? const Color(0xFF1A1B2E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseTextStyle.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: primaryColor,
            );
          }
          return baseTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.grey,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(
            color: isDark ? Colors.white54 : Colors.grey,
            size: 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey.withOpacity(0.08),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: GoogleFonts.cairoTextTheme(),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: GoogleFonts.cairoTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  );
}
