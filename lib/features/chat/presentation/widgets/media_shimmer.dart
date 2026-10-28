import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChatGPT-style shimmer placeholder for AI-generated media.
///
/// The light sweep moves:
/// TOP-LEFT → BOTTOM-RIGHT.
///
/// Used for both:
/// - Generating image…
/// - Loading image…
///
/// No external shimmer package required.
class MediaShimmer extends StatefulWidget {
  const MediaShimmer({
    super.key,
    required this.isDark,
    required this.label,
    this.subtitle,
    this.height = 220,
    this.borderRadius = 16,
    this.showFrame = true,
  });

  final bool isDark;
  final String label;
  final String? subtitle;

  /// Keep this identical for generating + loading
  /// so the container does not jump.
  final double height;

  final double borderRadius;

  /// false when this shimmer is already inside
  /// GeneratedImageBubble's existing framed container.
  final bool showFrame;

  @override
  State<MediaShimmer> createState() => _MediaShimmerState();
}

class _MediaShimmerState extends State<MediaShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isDark ? const Color(0xFF121214) : const Color(0xFFF1F5F9);

    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.showFrame && !widget.isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        foregroundDecoration: widget.showFrame
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = Curves.easeInOutCubic.transform(
                _controller.value,
              );

              // ---------------------------------------------------------
              // IMPORTANT:
              //
              // Start gradient outside TOP-LEFT.
              // Finish gradient outside BOTTOM-RIGHT.
              //
              // This produces the premium diagonal ↘ movement.
              // ---------------------------------------------------------

              final position = -3.0 + (4.0 * progress);

              final broadBegin = Alignment(
                position - 0.5,
                position - 0.5,
              );

              final broadEnd = Alignment(
                position + 2.5,
                position + 2.5,
              );

              final shineBegin = Alignment(
                position,
                position,
              );

              final shineEnd = Alignment(
                position + 2.0,
                position + 2.0,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Base
                  ColoredBox(
                    color: baseColor,
                  ),

                  // -----------------------------------------------------
                  // Very subtle background depth.
                  // No purple / colorful glow.
                  // Keeps it closer to ChatGPT.
                  // -----------------------------------------------------

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.isDark
                              ? Colors.white.withValues(alpha: 0.015)
                              : Colors.white.withValues(alpha: 0.42),
                          Colors.transparent,
                          widget.isDark
                              ? Colors.white.withValues(alpha: 0.01)
                              : Colors.black.withValues(alpha: 0.015),
                        ],
                      ),
                    ),
                  ),

                  // -----------------------------------------------------
                  // Wide soft light.
                  //
                  // This prevents the shimmer from looking like a cheap
                  // narrow skeleton-loading stripe.
                  // -----------------------------------------------------

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: broadBegin,
                        end: broadEnd,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(
                            alpha: widget.isDark ? 0.015 : 0.08,
                          ),
                          Colors.white.withValues(
                            alpha: widget.isDark ? 0.055 : 0.28,
                          ),
                          Colors.white.withValues(
                            alpha: widget.isDark ? 0.015 : 0.08,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [
                          0.00,
                          0.25,
                          0.50,
                          0.75,
                          1.00,
                        ],
                      ),
                    ),
                  ),

                  // -----------------------------------------------------
                  // Main premium shine.
                  //
                  // Travels:
                  //
                  // TOP LEFT
                  //     ↘
                  //       ↘
                  //         BOTTOM RIGHT
                  // -----------------------------------------------------

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: shineBegin,
                        end: shineEnd,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(
                            alpha: widget.isDark ? 0.025 : 0.10,
                          ),
                          Colors.white.withValues(
                            alpha: widget.isDark ? 0.16 : 0.72,
                          ),
                          Colors.white.withValues(
                            alpha: widget.isDark ? 0.05 : 0.16,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [
                          0.00,
                          0.30,
                          0.50,
                          0.70,
                          1.00,
                        ],
                      ),
                    ),
                  ),

                  // Text stays stable while background shines.
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : Colors.black.withValues(alpha: 0.75),
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.subtitle!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                                color: widget.isDark
                                    ? Colors.white.withValues(alpha: 0.52)
                                    : Colors.black.withValues(alpha: 0.52),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
