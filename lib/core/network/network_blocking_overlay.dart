import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'network_controller.dart';

class NetworkBlockingOverlay extends StatelessWidget {
  const NetworkBlockingOverlay({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NetworkController>();
    return Obx(() {
      final offline = controller.isOffline.value;
      final reconnected = controller.showReconnected.value;
      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                reverseDuration: const Duration(milliseconds: 180),
                transitionBuilder: (banner, animation) => SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(opacity: animation, child: banner),
                ),
                child: offline
                    ? const _NetworkStatusBanner(
                        key: ValueKey('offline'),
                        color: Color(0xFFB42318),
                        icon: Icons.wifi_off_rounded,
                        semanticsLabel: 'No internet connection',
                        message:
                            'No internet connection. Waiting to reconnect…',
                      )
                    : reconnected
                        ? const _NetworkStatusBanner(
                            key: ValueKey('reconnected'),
                            color: Color(0xFF15803D),
                            icon: Icons.wifi_rounded,
                            semanticsLabel: 'Internet connection restored',
                            message: 'Reconnected',
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('connected'),
                          ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _NetworkStatusBanner extends StatelessWidget {
  const _NetworkStatusBanner({
    required this.color,
    required this.icon,
    required this.semanticsLabel,
    required this.message,
    super.key,
  });

  final Color color;
  final IconData icon;
  final String semanticsLabel;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 8,
      child: Semantics(
        liveRegion: true,
        label: semanticsLabel,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
