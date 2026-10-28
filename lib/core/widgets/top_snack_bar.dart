import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows a floating snackbar anchored to the TOP of the screen.
/// Works by using a custom [OverlayEntry] so it is independent of Scaffold.
void showTopSnackBar(
  BuildContext context,
  String message, {
  Color? color,
  Color? textColor,
  Duration duration = const Duration(seconds: 3),
  bool rootOverlay = true,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: rootOverlay) ??
      Overlay.maybeOf(context);
  if (overlay == null) return;

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final effectiveColor =
      color ?? (isDark ? const Color(0xFF262626) : Colors.white);
  final effectiveTextColor = textColor ??
      (effectiveColor.computeLuminance() > 0.5 ? Colors.black : Colors.white);

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _TopSnackBar(
      message: message,
      color: effectiveColor,
      textColor: effectiveTextColor,
      duration: duration,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _TopSnackBar extends StatefulWidget {
  final String message;
  final Color color;
  final Color? textColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopSnackBar({
    required this.message,
    required this.color,
    this.textColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isLightBg = widget.color.computeLuminance() > 0.5;
    final effectiveTextColor = widget.textColor ??
        (isLightBg ? Colors.black : Colors.white);

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: GoogleFonts.montserrat(
                  color: effectiveTextColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
