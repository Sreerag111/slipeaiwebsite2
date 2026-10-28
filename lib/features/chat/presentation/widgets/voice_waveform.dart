import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/theme_controller.dart';

/// VoiceWaveform — animated equalizer-style waveform.
///
/// Reference: vertical rounded bars with varying heights.
/// Left section = bright/active | Right section = dim/inactive.
/// When [isActive] is true bars animate continuously.
/// When false bars transition to a subtle static state.
class VoiceWaveform extends StatefulWidget {
  final bool isActive;

  /// Number of bars to render (default 28)
  final int barCount;

  /// Maximum bar height in logical pixels (default 52)
  final double maxBarHeight;

  /// Height of the widget (default 64)
  final double height;

  /// Optional base color. If null, automatically adapts to current theme.
  final Color? color;

  const VoiceWaveform({
    super.key,
    required this.isActive,
    this.barCount = 28,
    this.maxBarHeight = 52,
    this.height = 64,
    this.color,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + _random.nextInt(300)),
      );
      return ctrl;
    });

    _animations = List.generate(widget.barCount, (i) {
      return Tween<double>(
        begin: _minFraction(i),
        end: _maxFraction(i),
      ).animate(CurvedAnimation(
        parent: _controllers[i],
        curve: Curves.easeInOut,
      ));
    });

    if (widget.isActive) _startAll();
  }

  @override
  void didUpdateWidget(VoiceWaveform old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _startAll();
    } else if (!widget.isActive && old.isActive) {
      _stopAll();
    }
  }

  double _minFraction(int i) => 0.08 + _random.nextDouble() * 0.12;
  double _maxFraction(int i) => 0.45 + _random.nextDouble() * 0.55;

  void _startAll() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 18), () {
        if (mounted && widget.isActive) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAll() {
    for (final c in _controllers) {
      c.animateTo(0.12, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final baseColor = widget.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));

      return AnimatedOpacity(
        opacity: widget.isActive ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 350),
        child: SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              // First half = bright active bars, second half = dim inactive
              final isActiveSide = i < widget.barCount * 0.55;
              final barColor = isActiveSide
                  ? baseColor
                  : baseColor.withValues(
                      alpha: isDark
                          ? 0.22 + (i / widget.barCount) * 0.08
                          : 0.18 + (i / widget.barCount) * 0.08,
                    );

              return _AnimatedBar(
                animation: _animations[i],
                maxHeight: widget.maxBarHeight,
                activeColor: barColor,
                isActive: widget.isActive,
                isDark: isDark,
              );
            }),
          ),
        ),
      );
    });
  }
}

class _AnimatedBar extends StatelessWidget {
  final Animation<double> animation;
  final double maxHeight;
  final Color activeColor;
  final bool isActive;
  final bool isDark;

  const _AnimatedBar({
    required this.animation,
    required this.maxHeight,
    required this.activeColor,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final h = (animation.value * maxHeight).clamp(4.0, maxHeight);
        return Container(
          width: 3.5,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 2.2),
          decoration: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isActive && activeColor.a > 0.7
                ? [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
