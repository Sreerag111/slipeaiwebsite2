import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FloatingBubbleService {
  static const _channel = MethodChannel('com.blide.ai/floating_bubble');

  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission') ?? false;
      debugPrint('[FloatingBubble] hasPermission() = $result');
      return result;
    } catch (e) {
      debugPrint('[FloatingBubble] hasPermission() error: $e');
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  /// Returns true if service started successfully, false if permission missing
  static Future<bool> start() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('[FloatingBubble] invoking startBubble method channel with uid: $uid');
      final result = await _channel.invokeMethod<bool>('startBubble', {
        'userId': uid,
      }) ?? false;
      debugPrint('[FloatingBubble] startBubble returned $result');
      return result;
    } catch (e) {
      debugPrint('[FloatingBubble] start() error: $e');
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopBubble');
    } catch (_) {}
  }

  static Future<void> moveToBackground() async {
    try {
      await _channel.invokeMethod('moveToBackground');
    } catch (_) {}
  }

  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBubbleRunning') ?? false;
      debugPrint('[FloatingBubble] isRunning() = $result');
      return result;
    } catch (e) {
      debugPrint('[FloatingBubble] isRunning() error: $e');
      return false;
    }
  }
}
