import 'dart:io';

import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  /// General button taps.
  static Future<void> tap() async {
    if (Platform.isIOS) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  /// Send message.
  static Future<void> send() async {
    if (Platform.isIOS) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  /// Open menus, bottom sheets, pickers.
  static Future<void> menu() async {
    if (Platform.isIOS) {
      await HapticFeedback.selectionClick();
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  /// Selecting an option.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Long press actions.
  static Future<void> longPress() async {
    if (Platform.isIOS) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Successful operation.
  static Future<void> success() async {
    if (Platform.isIOS) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  /// Warning / stop generation.
  static Future<void> warning() async {
    if (Platform.isIOS) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Destructive actions.
  static Future<void> error() async {
    if (Platform.isIOS) {
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  /// AI finished responding.
  static Future<void> responseCompleted() async {
    await HapticFeedback.selectionClick();
  }

  /// Voice recording started.
  static Future<void> recordingStarted() async {
    await HapticFeedback.mediumImpact();
  }

  /// Voice recording stopped.
  static Future<void> recordingStopped() async {
    await HapticFeedback.lightImpact();
  }
}