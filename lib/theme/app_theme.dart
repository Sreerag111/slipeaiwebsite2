import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';

/// App Theme configuration supporting both Dark and Light mode.
///
/// Features:
/// - [lightTheme] and [darkTheme] ThemeData instances
/// - [AppColorsExtension] custom ThemeExtension for semantic colors
/// - Context extension `context.colors` and `context.isDarkMode`
/// - Backward-compatible static constants for dark theme fallback
class AppTheme {
  AppTheme._();

  // ===========================================================================
  // BACKWARD COMPATIBLE CONSTANTS (Dark Theme defaults)
  // ===========================================================================
  static const Color primary = AppDarkColors.scaffoldBackground;
  static const Color surface = AppDarkColors.surface;
  static const Color card = AppDarkColors.card;
  static const Color cardElevated = AppDarkColors.cardElevated;
  static Color get accent => _darkAccent ? Colors.white : Colors.black;
  static Color get onAccent => _darkAccent ? Colors.black : Colors.white;
  static bool get _darkAccent => Get.isRegistered<ThemeController>()
      ? ThemeController.instance.isDarkMode
      : Get.isDarkMode;
  static const Color accentSecondary = AppDarkColors.accentSecondary;
  static const Color warning = AppDarkColors.warning;
  static const Color success = AppDarkColors.success;
  static const Color danger = AppDarkColors.danger;
  static const Color textPrimary = AppDarkColors.textPrimary;
  static const Color textSecondary = AppDarkColors.textSecondary;
  static const Color textMuted = AppDarkColors.textMuted;
  static const Color border = AppDarkColors.border;
  static Color get borderGlow => accent;
  static const Color darkGrey = Color.fromARGB(255, 24, 24, 24);

  // ===========================================================================
  // CONTEXT HELPERS
  // ===========================================================================
  /// Retrieves the current [AppColorsExtension] based on the active theme in [context].
  static AppColorsExtension colorsOf(BuildContext context) {
    return Theme.of(context).extension<AppColorsExtension>() ??
        AppColorsExtension.dark;
  }

  // ===========================================================================
  // DARK THEME
  // ===========================================================================
  static ThemeData get darkTheme {
    const colors = AppColorsExtension.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        primary: colors.accent,
        onPrimary: colors.background,
        secondary: colors.accentSecondary,
        onSecondary: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: colors.danger,
        onError: Colors.white,
        outline: colors.border,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        colors,
      ],
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppDarkColors.scaffoldBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        hintStyle:
            GoogleFonts.montserrat(color: colors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.montserrat(color: colors.textSecondary),
        prefixIconColor: colors.textMuted,
        suffixIconColor: colors.textMuted,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: colors.textPrimary,
        size: 20,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.accent,
        unselectedLabelColor: colors.textMuted,
        indicatorColor: colors.accent,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ===========================================================================
  // LIGHT THEME
  // ===========================================================================
  static ThemeData get lightTheme {
    const colors = AppColorsExtension.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.light(
        primary: colors.accent,
        onPrimary: Colors.white,
        secondary: colors.accentSecondary,
        onSecondary: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: colors.danger,
        onError: Colors.white,
        outline: colors.border,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        colors,
      ],
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppLightColors.scaffoldBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        hintStyle:
            GoogleFonts.montserrat(color: colors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.montserrat(color: colors.textSecondary),
        prefixIconColor: colors.textMuted,
        suffixIconColor: colors.textMuted,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: colors.textPrimary,
        size: 20,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.accent,
        unselectedLabelColor: colors.textMuted,
        indicatorColor: colors.accent,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// =============================================================================
// RAW COLOR PALETTES
// =============================================================================

/// Dark Mode Color Constants
class AppDarkColors {
  AppDarkColors._();

  static const Color scaffoldBackground = Color(0xFF000000);
  static const Color surface = Color(0xFF0C0C0E);
  static const Color card = Color(0xFF141418);
  static const Color cardElevated = Color(0xFF1C1C22);
  static const Color inputFill = Color(0xFF121216);

  static const Color accent = Colors.white;
  static const Color accentSecondary = Color(0xFF7C3AED); // Vivid Violet

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFD4D4D8);
  static const Color textMuted = Color(0xFF71717A);

  static const Color border = Color(0xFF27272A);
  static const Color borderGlow = Colors.white;
  static const Color divider = Color(0xFF1E1E24);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color shimmerBase = Color(0xFF1C1C22);
  static const Color shimmerHighlight = Color(0xFF2A2A34);
}

/// Light Mode Color Constants
class AppLightColors {
  AppLightColors._();

  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFF1F5F9); // Slate 100
  static const Color inputFill = Color(0xFFF1F5F9); // Slate 100

  static const Color accent = Colors.black;
  static const Color accentSecondary = Color(0xFF7C3AED); // Royal Violet

  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black;
  static const Color textMuted = Colors.black;

  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderGlow = Colors.black;
  static const Color divider = Color(0xFFF1F5F9); // Slate 100

  static const Color success = Color(0xFF059669); // Emerald 600
  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color danger = Color(0xFFDC2626); // Red 600

  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
}

// =============================================================================
// THEME EXTENSION (Allows dynamic access across widgets)
// =============================================================================

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color surface;
  final Color card;
  final Color cardElevated;
  final Color inputFill;
  final Color accent;
  final Color accentSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderGlow;
  final Color divider;
  final Color success;
  final Color warning;
  final Color danger;
  final Color shimmerBase;
  final Color shimmerHighlight;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.card,
    required this.cardElevated,
    required this.inputFill,
    required this.accent,
    required this.accentSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderGlow,
    required this.divider,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  /// Predefined Dark Mode Extension
  static const dark = AppColorsExtension(
    background: AppDarkColors.scaffoldBackground,
    surface: AppDarkColors.surface,
    card: AppDarkColors.card,
    cardElevated: AppDarkColors.cardElevated,
    inputFill: AppDarkColors.inputFill,
    accent: AppDarkColors.accent,
    accentSecondary: AppDarkColors.accentSecondary,
    textPrimary: AppDarkColors.textPrimary,
    textSecondary: AppDarkColors.textSecondary,
    textMuted: AppDarkColors.textMuted,
    border: AppDarkColors.border,
    borderGlow: AppDarkColors.borderGlow,
    divider: AppDarkColors.divider,
    success: AppDarkColors.success,
    warning: AppDarkColors.warning,
    danger: AppDarkColors.danger,
    shimmerBase: AppDarkColors.shimmerBase,
    shimmerHighlight: AppDarkColors.shimmerHighlight,
  );

  /// Predefined Light Mode Extension
  static const light = AppColorsExtension(
    background: AppLightColors.scaffoldBackground,
    surface: AppLightColors.surface,
    card: AppLightColors.card,
    cardElevated: AppLightColors.cardElevated,
    inputFill: AppLightColors.inputFill,
    accent: AppLightColors.accent,
    accentSecondary: AppLightColors.accentSecondary,
    textPrimary: AppLightColors.textPrimary,
    textSecondary: AppLightColors.textSecondary,
    textMuted: AppLightColors.textMuted,
    border: AppLightColors.border,
    borderGlow: AppLightColors.borderGlow,
    divider: AppLightColors.divider,
    success: AppLightColors.success,
    warning: AppLightColors.warning,
    danger: AppLightColors.danger,
    shimmerBase: AppLightColors.shimmerBase,
    shimmerHighlight: AppLightColors.shimmerHighlight,
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? cardElevated,
    Color? inputFill,
    Color? accent,
    Color? accentSecondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderGlow,
    Color? divider,
    Color? success,
    Color? warning,
    Color? danger,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      inputFill: inputFill ?? this.inputFill,
      accent: accent ?? this.accent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderGlow: borderGlow ?? this.borderGlow,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      card: Color.lerp(card, other.card, t) ?? card,
      cardElevated:
          Color.lerp(cardElevated, other.cardElevated, t) ?? cardElevated,
      inputFill: Color.lerp(inputFill, other.inputFill, t) ?? inputFill,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t) ??
          accentSecondary,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      border: Color.lerp(border, other.border, t) ?? border,
      borderGlow: Color.lerp(borderGlow, other.borderGlow, t) ?? borderGlow,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t) ?? shimmerBase,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t) ??
              shimmerHighlight,
    );
  }
}

// =============================================================================
// CONVENIENT BUILDCONTEXT EXTENSIONS
// =============================================================================

extension AppThemeContextExtension on BuildContext {
  /// Quick access to custom semantic app colors
  AppColorsExtension get colors => AppTheme.colorsOf(this);

  /// Check if the current theme is dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Quick access to ThemeData
  ThemeData get theme => Theme.of(this);

  /// Quick access to TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;
}
