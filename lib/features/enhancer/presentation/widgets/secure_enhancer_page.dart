import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Non-blocking wrapper for window capture protection.
/// Immediately renders [child] without gating or blocking screen rendering.
class SecureEnhancerPage extends StatefulWidget {
  const SecureEnhancerPage({super.key, required this.child});

  final Widget child;

  @override
  State<SecureEnhancerPage> createState() => _SecureEnhancerPageState();
}

class _SecureEnhancerPageState extends State<SecureEnhancerPage> {
  static const _channel = MethodChannel('com.paceai.paceai/enhancer_security');

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _channel
          .invokeMethod<void>('setCaptureBlocked', {'blocked': true})
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      _channel
          .invokeMethod<void>('setCaptureBlocked', {'blocked': false})
          .catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
