import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlobalErrorController extends GetxController {
  static GlobalErrorController get instance =>
      Get.find<GlobalErrorController>();

  void reportError(dynamic error, StackTrace? stack) {
    debugPrint('[GlobalError] $error${stack != null ? '\n$stack' : ''}');
  }

  void showError(String message) {
    _showTopSnackBar(message);
  }

  void _showTopSnackBar(String message) {
    final context = Get.context;
    if (context == null) return;
    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GlobalErrorBar(
        message: message,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _GlobalErrorBar extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const _GlobalErrorBar({required this.message, required this.onDismiss});

  @override
  State<_GlobalErrorBar> createState() => _GlobalErrorBarState();
}

class _GlobalErrorBarState extends State<_GlobalErrorBar>
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
    Future.delayed(const Duration(seconds: 4), _dismiss);
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
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _ctrl.reset();
                      widget.onDismiss();
                    },
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
