import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography and controls shared by the enhancer flow in both color modes.
class EnhancerStyle {
  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final accent = base.colorScheme.primary;
    final onAccent = base.colorScheme.onPrimary;
    final inter = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: base.colorScheme.onSurface,
      displayColor: base.colorScheme.onSurface,
    );
    return base.copyWith(
      textTheme: inter.copyWith(
        bodyLarge: inter.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        bodyMedium: inter.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        bodySmall: inter.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: GoogleFonts.inter(
          color: base.colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: accent.withValues(alpha: 0.42),
          disabledForegroundColor: onAccent.withValues(alpha: 0.70),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: base.colorScheme.onSurface,
          side: BorderSide(color: base.colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static TextStyle body(BuildContext context, {Color? color}) =>
      GoogleFonts.inter(
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      );

  static TextStyle heading(BuildContext context, {double size = 28}) =>
      GoogleFonts.inter(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.7,
        height: 1.15,
      );
}
