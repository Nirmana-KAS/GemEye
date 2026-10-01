import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colour tokens. Every colour used by the UI lives here.
class AppColors {
  // Brand
  static const Color primary = Color(0xFF1B3A8C);
  static const Color primaryLight = Color(0xFF3B5FD9);
  static const Color surface = Color(0xFFEEF1FA);

  // Neutrals
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryTrack = Color(0x4DFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7089);
  static const Color textMuted = Color(0xFFA0A4B8);
  static const Color border = Color(0xFFE5E7F0);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Tinted status backgrounds (icon chips in snackbars and dialogs)
  static const Color successTint = Color(0x1F10B981);
  static const Color warningTint = Color(0x24F59E0B);
  static const Color errorTint = Color(0x1FEF4444);

  // Shadows and overlays
  static const Color shadow = Color(0x1A1A1D2E);
  static const Color menuShadow = Color(0x1F1A1D2E);
  static const Color scrim = Color(0x6B1A1D2E);

  // Google sign-in branding
  static const Color googleBorder = Color(0xFF747775);
  static const Color googleText = Color(0xFF1F1F1F);
  static const Color googlePressed = Color(0xFFF8F9FA);
  static const Color googleDisabledBorder = Color(0x1F1F1F1F);
  static const Color googleDisabledText = Color(0x611F1F1F);

  // GEMCLOUD grade colours, Grade 1 (darkest) to Grade 7 (lightest)
  static const Color grade1 = Color(0xFF020519);
  static const Color grade2 = Color(0xFF0B0F3F);
  static const Color grade3 = Color(0xFF091A72);
  static const Color grade4 = Color(0xFF2A408C);
  static const Color grade5 = Color(0xFF47619E);
  static const Color grade6 = Color(0xFF718BB7);
  static const Color grade7 = Color(0xFFABBDD6);
  static const List<Color> grades = [
    grade1, grade2, grade3, grade4, grade5, grade6, grade7,
  ];

  // GemEye calibration card patch colours
  static const Color patchWhite = Color(0xFFFFFFFF);
  static const Color patchBlack = Color(0xFF000000);
  static const Color patchGrey18 = Color(0xFF757575);
  static const Color patchGrey50 = Color(0xFFBABABA);
  static const Color patchBlue = Color(0xFF003F87);
  static const Color patchRed = Color(0xFFAF363C);
}

/// Font families and the text style scale.
class AppText {
  static const String heading = 'Poppins';
  static const String body = 'Inter';
  static const String mono = 'JetBrainsMono';
  static const String google = 'Roboto';

  /// Wordmark on Splash and Login (28 Poppins Bold).
  static const TextStyle display = TextStyle(
    fontFamily: heading,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.primary,
  );

  /// Screen title (20 Poppins SemiBold).
  static const TextStyle screenTitle = TextStyle(
    fontFamily: heading,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// Section header (16 Poppins SemiBold).
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: heading,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Small heading (14 Poppins SemiBold).
  static const TextStyle titleSmall = TextStyle(
    fontFamily: heading,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Body (14 Inter Regular).
  static const TextStyle body14 = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  /// Body medium (14 Inter Medium).
  static const TextStyle body14Medium = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Secondary (12 Inter Regular).
  static const TextStyle secondary = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Field label (12 Inter Medium).
  static const TextStyle label = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Caption (11 Inter Regular).
  static const TextStyle caption = TextStyle(
    fontFamily: body,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Button (14 Poppins SemiBold).
  static const TextStyle button = TextStyle(
    fontFamily: heading,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Numeric colour values only (12 JetBrains Mono).
  static const TextStyle monoValue = TextStyle(
    fontFamily: mono,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Google sign-in button label (14 Roboto Medium).
  static const TextStyle googleButton = TextStyle(
    fontFamily: google,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.googleText,
  );
}

/// Corner radius tokens.
class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 14;
  static const double xxl = 16;
  static const double logo = 20;
  static const double pill = 999;
}

/// Spacing tokens (4 dp grid).
class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double huge = 32;
  static const double massive = 48;

  /// Horizontal screen gutter.
  static const double screen = 20;

  /// Minimum touch target.
  static const double touchTarget = 48;

  /// Standard control height (buttons, fields).
  static const double controlHeight = 48;
}

/// Status bar styles for screens with light or primary-coloured tops.
class AppSystemUi {
  static const SystemUiOverlayStyle darkIcons = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );
  static const SystemUiOverlayStyle lightIcons = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );
}

/// Legacy colour names used by screens not yet redesigned. Aliases [AppColors].
class GemEyeColors {
  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color primarySurface = AppColors.surface;
  static const Color background = AppColors.background;
  static const Color card = AppColors.card;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;
  static const Color border = AppColors.border;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
}

/// Legacy font names used by screens not yet redesigned. Aliases [AppText].
class GemEyeFonts {
  static const String heading = AppText.heading;
  static const String body = AppText.body;
  static const String mono = AppText.mono;
}

class GemEyeTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.primaryLight,
        surface: AppColors.card,
        surfaceTint: AppColors.background,
        error: AppColors.error,
      ),
      fontFamily: AppText.body,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: AppSystemUi.lightIcons,
        titleTextStyle: TextStyle(
          fontFamily: AppText.heading,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: AppColors.onPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: AppText.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: AppText.button,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          fontFamily: AppText.body,
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionHandleColor: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: TextStyle(
            fontFamily: AppText.body,
            fontWeight: FontWeight.w500,
            fontSize: 11),
        unselectedLabelStyle: TextStyle(
            fontFamily: AppText.body,
            fontWeight: FontWeight.w400,
            fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
