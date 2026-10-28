import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/theme_controller.dart';

class WaveformMicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final String recordingDuration;

  const WaveformMicButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.recordingDuration = '00:00',
  });

  @override
  State<WaveformMicButton> createState() => _WaveformMicButtonState();
}

class _WaveformMicButtonState extends State<WaveformMicButton> {
  @override
  void didUpdateWidget(WaveformMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GestureDetector(
        onTap: widget.onTap,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: widget.isListening ? _buildActiveRecorder() : _buildIdleMic(),
        ),
      );
    });
  }

  Widget _buildIdleMic() {
    final isDark = ThemeController.instance.isDarkMode;
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Icon(
          Icons.mic_none_rounded,
          color: isDark ? Colors.white : Colors.black,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildActiveRecorder() {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _WaveformPainter — draws animated bars as waveform
// ─────────────────────────────────────────────────────────────────────────────

// ignore: unused_element
class _WaveformPainter extends CustomPainter {
  final List<double> barHeights;
  final Color color;

  _WaveformPainter({required this.barHeights, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.fill;

    final barCount = barHeights.length;
    final barWidth = 2.5;
    final spacing = (size.width - barWidth * barCount) / (barCount - 1);
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);
      final barH = (size.height * barHeights[i]).clamp(3.0, size.height);

      // Glow effect — softer version behind main bar
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth + 2
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barH,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, glowPaint);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.barHeights != barHeights || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ModernRecordingBanner — replaces the old static banner
// ─────────────────────────────────────────────────────────────────────────────

class ModernRecordingBanner extends StatefulWidget {
  final String transcript;
  final String duration;

  const ModernRecordingBanner({
    super.key,
    required this.transcript,
    required this.duration,
  });

  @override
  State<ModernRecordingBanner> createState() => _ModernRecordingBannerState();
}

class _ModernRecordingBannerState extends State<ModernRecordingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final bannerBg = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFF1F5F9);
      final bannerBorder = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8F0);
      final transcriptColor =
          isDark ? Colors.white70 : const Color(0xFF0F172A);
      final durationColor =
          isDark ? Colors.white38 : const Color(0xFF64748B);

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: bannerBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bannerBorder),
        ),
        child: Row(
          children: [
            // Pulsing dot
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red
                      .withValues(alpha: 0.4 + 0.6 * _pulseController.value),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red
                          .withValues(alpha: 0.5 * _pulseController.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.transcript.trim().isEmpty
                    ? 'Listening…'
                    : widget.transcript,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: transcriptColor,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.duration,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: durationColor,
              ),
            ),
          ],
        ),
      );
    });
  }
}

