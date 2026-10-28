import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // Display — Hero / Landing titles (26–30px)
  // ---------------------------------------------------------------------------

  static TextStyle get displayLarge => GoogleFonts.montserrat(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.5,
      );

  static TextStyle get displaySmall => GoogleFonts.montserrat(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // ---------------------------------------------------------------------------
  // Headline — Section headers, stat values (22–24px)
  // ---------------------------------------------------------------------------

  static TextStyle get headlineMedium => GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineSmall => GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: AppTheme.textPrimary,
        height: 1.2,
      );

  // ---------------------------------------------------------------------------
  // Title — AppBar titles, card titles (15–20px)
  // ---------------------------------------------------------------------------

  static TextStyle get titleLarge => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.3,
      );

  static TextStyle get titleLargeBold => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.2,
      );

  static TextStyle get titleMediumLg => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: 1.2,
      );

  static TextStyle get titleMedium => GoogleFonts.montserrat(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get titleMediumMd => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: 2,
      );

  static TextStyle get titleMediumSm => GoogleFonts.montserrat(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: 2,
      );

  static TextStyle get titleMediumXs => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: 2,
      );

  static TextStyle get titleMediumXxs => GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: 1.5,
      );

  static TextStyle get titleSmall => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      );

  static TextStyle get titleSmallBold => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.35,
      );

  static TextStyle get titleSmallW600 => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      );

  static TextStyle get titleSmallMuted => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      );

  static TextStyle get titleSmallLarge => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      );

  // ---------------------------------------------------------------------------
  // Body — Chat text, inputs, descriptions (14–16px)
  // ---------------------------------------------------------------------------

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        color: Colors.white,
        height: 1.7,
      );

  static TextStyle get bodyLargeW500 => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.7,
      );

  static TextStyle get bodyMediumLg => GoogleFonts.montserrat(
        fontSize: 15.5,
        color: Colors.white,
        height: 1.45,
      );

  static TextStyle get bodyMedium => GoogleFonts.montserrat(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMediumBase => GoogleFonts.montserrat(
        fontSize: 15,
        color: Colors.white,
      );

  static TextStyle get bodyMediumButton => GoogleFonts.montserrat(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  static TextStyle get bodySmallLg => GoogleFonts.montserrat(
        fontSize: 14,
        color: AppTheme.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.montserrat(
        fontSize: 14,
        color: Colors.white,
        height: 1.5,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmallMuted => GoogleFonts.montserrat(
        fontSize: 14,
        color: AppTheme.textMuted,
      );

  static TextStyle get bodySmallSecondary => GoogleFonts.montserrat(
        fontSize: 14,
        color: AppTheme.textSecondary,
      );

  static TextStyle get bodySmallW600 => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      );

  static TextStyle get bodySmallBold => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.accent,
      );

  // ---------------------------------------------------------------------------
  // Label — Buttons, chips, badges (12–14px)
  // ---------------------------------------------------------------------------

  static TextStyle get labelLarge => GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      );

  static TextStyle get labelLargeBold => GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get labelMedium => GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get labelMediumMuted => GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
      );

  static TextStyle get labelSmall => GoogleFonts.montserrat(
        fontSize: 13,
        color: AppTheme.textSecondary,
        height: 1.55,
      );

  static TextStyle get labelSmallMuted => GoogleFonts.montserrat(
        fontSize: 13,
        color: AppTheme.textMuted,
      );

  // ---------------------------------------------------------------------------
  // Caption — Subtitles, metadata (11–13px)
  // ---------------------------------------------------------------------------

  static TextStyle get captionLarge => GoogleFonts.montserrat(
        fontSize: 13.5,
        color: AppTheme.textPrimary,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.montserrat(
        fontSize: 13,
        color: Colors.white,
      );

  static TextStyle get captionMuted => GoogleFonts.montserrat(
        fontSize: 12,
        color: AppTheme.textMuted,
      );

  static TextStyle get captionSecondary => GoogleFonts.montserrat(
        fontSize: 12,
        color: AppTheme.textSecondary,
      );

  static TextStyle get captionSmall => GoogleFonts.montserrat(
        fontSize: 12.5,
        color: AppTheme.textSecondary,
      );

  static TextStyle get captionW500 => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle get captionDesc => GoogleFonts.montserrat(
        fontSize: 12,
        color: AppTheme.textMuted,
        height: 1.4,
      );

  // ---------------------------------------------------------------------------
  // Micro — Section headers, tags, badges (10–11px)
  // ---------------------------------------------------------------------------

  static TextStyle get microLabel => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 1.5,
      );

  static TextStyle get microLabelLs2 => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 2,
      );

  static TextStyle get microBadge => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1,
      );

  static TextStyle get microNumber => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      );

  static TextStyle get microSection => GoogleFonts.montserrat(
        fontSize: 10,
        color: AppTheme.textMuted,
        letterSpacing: 1,
      );

  static TextStyle get microAccent => GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.accent,
      );

  static TextStyle get microStatus => GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Color(0xFF00FF88),
        letterSpacing: 1.2,
      );

  // ---------------------------------------------------------------------------
  // Nano — Tiny labels, info rows (8–9px)
  // ---------------------------------------------------------------------------

  static TextStyle get nanoLabel => GoogleFonts.montserrat(
        fontSize: 9,
        color: Colors.white38,
      );

  static TextStyle get nanoHeader => GoogleFonts.montserrat(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7C3AED),
        letterSpacing: 1,
      );

  static TextStyle get nanoTag => GoogleFonts.montserrat(
        fontSize: 8,
        fontWeight: FontWeight.w700,
      );
}
