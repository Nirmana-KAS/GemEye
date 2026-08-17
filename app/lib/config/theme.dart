import 'package:flutter/material.dart';

class GemEyeColors {
  static const Color primary = Color(0xFF1B3A8C);
  static const Color primaryLight = Color(0xFF3B5FD9);
  static const Color primarySurface = Color(0xFFEEF1FA);
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7089);
  static const Color textMuted = Color(0xFFA0A4B8);
  static const Color border = Color(0xFFE5E7F0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

class GemEyeFonts {
  static const String heading = 'Poppins';
  static const String body = 'Inter';
  static const String mono = 'JetBrainsMono';
}

class GemEyeTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: GemEyeColors.background,
      colorScheme: const ColorScheme.light(
        primary: GemEyeColors.primary,
        onPrimary: Colors.white,
        secondary: GemEyeColors.primaryLight,
        surface: GemEyeColors.card,
        error: GemEyeColors.error,
      ),
      fontFamily: GemEyeFonts.body,
      appBarTheme: const AppBarTheme(
        backgroundColor: GemEyeColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: GemEyeFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GemEyeColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: GemEyeFonts.heading,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GemEyeColors.primary,
          side: const BorderSide(color: GemEyeColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: GemEyeFonts.heading,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: GemEyeColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: GemEyeColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GemEyeColors.primarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GemEyeColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GemEyeColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GemEyeColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          fontFamily: GemEyeFonts.body,
          color: GemEyeColors.textMuted,
          fontSize: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: const DividerThemeData(
        color: GemEyeColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: GemEyeColors.primary,
        unselectedItemColor: GemEyeColors.textMuted,
        selectedLabelStyle: TextStyle(fontFamily: GemEyeFonts.body, fontWeight: FontWeight.w500, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontFamily: GemEyeFonts.body, fontWeight: FontWeight.w400, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}