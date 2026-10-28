import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EnhancerPageHeader extends StatelessWidget {
  const EnhancerPageHeader({
    super.key,
    required this.title,
    required this.onHistory,
  });

  final String title;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1F1F1F) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (dark ? Colors.white : Colors.black)
                      .withValues(alpha: dark ? 0.12 : 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: (dark ? Colors.white : Colors.black)
                      .withValues(alpha: dark ? 0.05 : 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onHistory,
                customBorder: const CircleBorder(),
                child: Tooltip(
                  message: 'History',
                  child: Center(
                    child: Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancerEmptyStage extends StatelessWidget {
  const EnhancerEmptyStage({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.borderRadius = 22.0,
    this.margin,
    this.imageCards,
  });

  static const defaultPhotoCards = <String>[
    'assets/images/enhancer_card_1.jpg',
    'assets/images/enhancer_card_2.jpg',
    'assets/images/enhancer_card_3.png',
  ];

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final List<String>? imageCards;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : const Color(0xFF161A22);
    final muted = dark ? Colors.white60 : const Color(0xFF64748B);

    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.20)
        : const Color(0xFF0F172A).withValues(alpha: 0.16);

    // Enhanced contrast for light mode so dots are clearly noticeable
    final dotColor = dark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFF0F172A).withValues(alpha: 0.22);

    final gradientColors = dark
        ? const [Color(0xFF1D2129), Color(0xFF12141A)]
        : const [Color(0xFFFAFCFF), Color(0xFFEFF3F8)];

    final radius = BorderRadius.circular(borderRadius);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final effectiveMargin = margin ??
        EdgeInsets.symmetric(
          horizontal: screenWidth > 540 ? (screenWidth - 500) / 2 : 16.0,
          vertical: 8.0,
        );

    final hasCards = imageCards != null && imageCards!.isNotEmpty;

    Widget stage = CustomPaint(
      foregroundPainter: DashedRRectPainter(
        color: borderColor,
        strokeWidth: 1.4,
        dashLength: 7.5,
        dashGap: 6.0,
        radius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. BACKGROUND DOT GRID (ChatGPT / Notion style)
                // Center underneath cards is clear (no dots), softly fades out to borders
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: DotGridPainter(
                        dotColor: dotColor,
                        dotRadius: 1.2,
                        spacing: 16.0,
                        radialFade: true,
                        maskCenter: hasCards,
                      ),
                    ),
                  ),
                ),
                // 2. CENTER CONTENT
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasCards)
                          ShufflingImageStack(images: imageCards!)
                        else
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white,
                              border: Border.all(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (dark
                                          ? Colors.black
                                          : const Color(0xFF0F172A))
                                      .withValues(alpha: dark ? 0.30 : 0.06),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(icon, size: 32, color: foreground),
                          ),
                        SizedBox(height: hasCards ? 14 : 16),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: foreground,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          detail,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Padding(padding: effectiveMargin, child: stage);
  }
}

/// Animated 3-card stack fanned out like a hand of cards with continuous looping shuffle.
class ShufflingImageStack extends StatefulWidget {
  const ShufflingImageStack({
    super.key,
    required this.images,
    this.cardSize = 104.0,
  });

  final List<String> images;
  final double cardSize;

  @override
  State<ShufflingImageStack> createState() => _ShufflingImageStackState();
}

class _ShufflingImageStackState extends State<ShufflingImageStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _shuffleTimer;
  int _step = 0;

  static const _slots = <_CardSlot>[
    // Slot 0: Back-Left (-12 degrees, shifted left)
    _CardSlot(
      x: -42.0,
      y: 4.0,
      angle: -12.0 * math.pi / 180,
      scale: 0.88,
    ),
    // Slot 1: Front Center (0 degrees, slightly larger, on top)
    _CardSlot(
      x: 0.0,
      y: -4.0,
      angle: 0.0,
      scale: 1.04,
    ),
    // Slot 2: Back-Right (+12 degrees, shifted right)
    _CardSlot(
      x: 42.0,
      y: 4.0,
      angle: 12.0 * math.pi / 180,
      scale: 0.88,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _step = (_step + 1) % 3;
          });
          _controller.reset();
          _scheduleNextShuffle();
        }
      }
    });

    _scheduleNextShuffle();
  }

  void _scheduleNextShuffle() {
    _shuffleTimer?.cancel();
    if (!mounted) return;
    _shuffleTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (!TickerMode.valuesOf(context).enabled) {
        // Paused because screen or route is not visible; re-check gently
        _scheduleNextShuffle();
        return;
      }
      _controller.forward(from: 0.0);
    });
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 230,
      height: 136,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final t = _animation.value;

          // Compute slot interpolation for each of the 3 cards
          final cards = List.generate(3, (i) {
            final fromIndex = (i + _step) % 3;
            final toIndex = (i + _step + 1) % 3;

            final slotFrom = _slots[fromIndex];
            final slotTo = _slots[toIndex];

            final isFrontToBack = fromIndex == 1;
            final isBackToFront = toIndex == 1;

            final x = slotFrom.x + (slotTo.x - slotFrom.x) * t;
            final baseY = slotFrom.y + (slotTo.y - slotFrom.y) * t;
            final arcY = isFrontToBack ? -math.sin(t * math.pi) * 12.0 : 0.0;
            final y = baseY + arcY;

            final angle = slotFrom.angle + (slotTo.angle - slotFrom.angle) * t;
            final scale = slotFrom.scale + (slotTo.scale - slotFrom.scale) * t;

            double elevation;
            if (isFrontToBack) {
              elevation = t < 0.5 ? 4.0 : 0.6;
            } else if (isBackToFront) {
              elevation = t < 0.5 ? 1.5 : 3.5;
            } else {
              elevation = 1.0;
            }

            return _CardRenderData(
              cardIndex: i,
              x: x,
              y: y,
              angle: angle,
              scale: scale,
              elevation: elevation,
            );
          });

          // Sort ascending so highest elevation is rendered last (on top)
          cards.sort((a, b) => a.elevation.compareTo(b.elevation));

          return Center(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                for (final card in cards)
                  Transform.translate(
                    key: ValueKey('card_${card.cardIndex}'),
                    offset: Offset(card.x, card.y),
                    child: Transform.rotate(
                      angle: card.angle,
                      child: Transform.scale(
                        scale: card.scale,
                        child: _CardItem(
                          imagePath: widget
                              .images[card.cardIndex % widget.images.length],
                          dark: dark,
                          size: widget.cardSize,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardSlot {
  const _CardSlot({
    required this.x,
    required this.y,
    required this.angle,
    required this.scale,
  });

  final double x;
  final double y;
  final double angle;
  final double scale;
}

class _CardRenderData {
  const _CardRenderData({
    required this.cardIndex,
    required this.x,
    required this.y,
    required this.angle,
    required this.scale,
    required this.elevation,
  });

  final int cardIndex;
  final double x;
  final double y;
  final double angle;
  final double scale;
  final double elevation;
}

class _CardItem extends StatelessWidget {
  const _CardItem({
    required this.imagePath,
    required this.dark,
    this.size = 104.0,
  });

  final String imagePath;
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        dark ? Colors.white.withValues(alpha: 0.32) : Colors.white;

    final shadowColor = Colors.black.withValues(alpha: dark ? 0.38 : 0.15);

    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: dark ? const Color(0xFF1E222A) : const Color(0xFFE2E8F0),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 7),
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.18 : 0.04),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Strictly clip all images (including opaque JPGs) to rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                imagePath,
                width: size,
                height: size,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: dark
                        ? const Color(0xFF242833)
                        : const Color(0xFFE9EEF5),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: dark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Crisp photo card border overlay
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 2.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a subtle, evenly spaced dot matrix pattern (ChatGPT / Notion style).
/// Scales dynamically to any size and adapts to dark/light theme.
/// Uses a radial gradient shader to gently fade dots towards the container edges,
/// and can mask out dots directly behind the center image stack.
class DotGridPainter extends CustomPainter {
  const DotGridPainter({
    required this.dotColor,
    this.dotRadius = 1.2,
    this.spacing = 16.0,
    this.radialFade = true,
    this.maskCenter = true,
  });

  final Color dotColor;
  final double dotRadius;
  final double spacing;
  final bool radialFade;
  final bool maskCenter;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (radialFade) {
      if (maskCenter) {
        // Clear behind the center cards, softly emerging outward, and fading at edges
        paint.shader = RadialGradient(
          center: Alignment.center,
          radius: 0.88,
          colors: [
            dotColor.withValues(
                alpha: 0.0), // Center directly under cards: no dots
            dotColor.withValues(alpha: 0.0), // Cards boundary: no dots
            dotColor.withValues(
                alpha: dotColor.a * 0.40), // Softly emerging from behind cards
            dotColor, // Strongest ring around cards
            dotColor.withValues(alpha: dotColor.a * 0.70),
            dotColor.withValues(alpha: 0.0), // Fades out at outer borders
          ],
          stops: const [0.0, 0.22, 0.36, 0.58, 0.82, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      } else {
        paint.shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            dotColor,
            dotColor.withValues(alpha: dotColor.a * 0.85),
            dotColor.withValues(alpha: dotColor.a * 0.35),
            dotColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.40, 0.72, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      }
    } else {
      paint.color = dotColor;
    }

    final cols = (size.width / spacing).floor();
    final rows = (size.height / spacing).floor();
    final startX = (size.width - (cols * spacing)) / 2;
    final startY = (size.height - (rows * spacing)) / 2;

    for (double x = startX; x <= size.width; x += spacing) {
      for (double y = startY; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radialFade != radialFade ||
        oldDelegate.maskCenter != maskCenter;
  }
}

class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({
    required this.color,
    this.strokeWidth = 1.8,
    this.dashLength = 7.5,
    this.dashGap = 6.0,
    this.radius = 20.0,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final inset = strokeWidth / 2 + 0.5;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - (inset * 2),
        size.height - (inset * 2),
      ),
      Radius.circular((radius - inset).clamp(0.0, double.infinity)),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      final totalLength = metric.length;
      if (totalLength <= 0) continue;

      final targetCycle = dashLength + dashGap;
      final count = (totalLength / targetCycle).round().clamp(1, 10000);
      final actualCycle = totalLength / count;
      final actualDash = actualCycle * (dashLength / targetCycle);
      final actualGap = actualCycle - actualDash;

      double distance = 0.0;
      for (int i = 0; i < count; i++) {
        final extract = metric.extractPath(distance, distance + actualDash);
        canvas.drawPath(extract, paint);
        distance += actualDash + actualGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashLength != oldDelegate.dashLength ||
      dashGap != oldDelegate.dashGap ||
      radius != oldDelegate.radius;
}
