import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/theme_controller.dart';

class GlowingCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double glowIntensity;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const GlowingCard({
    super.key,
    required this.child,
    this.glowColor,
    this.glowIntensity = 0.3,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final color = glowColor ?? AppTheme.accent;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161618) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.3 : 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(
                    alpha: glowIntensity * (isDark ? 0.4 : 0.2)),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      );
    });
  }
}

class ScoreGauge extends StatelessWidget {
  final double score;
  final String label;
  final Color color;
  final double size;

  const ScoreGauge({
    super.key,
    required this.score,
    required this.label,
    required this.color,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Column(
        children: [
          CircularPercentIndicator(
            radius: size / 2,
            lineWidth: 8,
            percent: score / 100,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${score.toInt()}%',
                  style: GoogleFonts.montserrat(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            progressColor: color,
            backgroundColor: color.withValues(alpha: 0.15),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1200,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF8E8E93) : Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    });
  }
}

class RiskBadge extends StatelessWidget {
  final String riskLevel;
  final Color color;

  const RiskBadge({super.key, required this.riskLevel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            riskLevel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class FindingChip extends StatelessWidget {
  final String text;
  final int index;

  const FindingChip({super.key, required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161618) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 10, top: 1),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: index * 100))
          .slideX(begin: -0.1);
    });
  }
}

class SuspiciousSectionCard extends StatefulWidget {
  final dynamic section;
  final int index;

  const SuspiciousSectionCard(
      {super.key, required this.section, required this.index});

  @override
  State<SuspiciousSectionCard> createState() => _SuspiciousSectionCardState();
}

class _SuspiciousSectionCardState extends State<SuspiciousSectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final confidence = widget.section.confidenceLevel;
    final confColor = confidence >= 70
        ? AppTheme.danger
        : confidence >= 40
            ? AppTheme.warning
            : AppTheme.success;

    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161618) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: confColor.withValues(alpha: isDark ? 0.3 : 0.25),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: confColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${confidence.toInt()}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: confColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.section.text.length > 80
                            ? '${widget.section.text.substring(0, 80)}...'
                            : widget.section.text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
                height: 1,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FULL TEXT',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F1F22)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                            left: BorderSide(color: confColor, width: 3)),
                      ),
                      child: Text(
                        widget.section.text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'REASON',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.section.reason,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SUGGESTION',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: AppTheme.warning, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.section.suggestion,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppTheme.warning,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: widget.index * 80))
          .slideY(begin: 0.1);
    });
  }
}

class DetailStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const DetailStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161618) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? (isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      );
    });
  }
}
