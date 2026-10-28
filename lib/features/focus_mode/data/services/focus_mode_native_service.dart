import 'package:flutter/services.dart';

import '../../domain/entities/focus_block_schedule.dart';

/// A social app discovered on-device, ready to show in the Blocked Apps list.
class InstalledSocialApp {
  const InstalledSocialApp({
    required this.packageName,
    required this.appName,
    required this.iconBytes,
  });

  final String packageName;
  final String appName;
  final Uint8List iconBytes;

  factory InstalledSocialApp.fromMap(Map<dynamic, dynamic> map) {
    return InstalledSocialApp(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconBytes: map['iconBytes'] as Uint8List,
    );
  }
}

/// Talks to the native Android side for everything Focus Mode needs that
/// Flutter can't do on its own: installed-app discovery and the two
/// special permissions (Usage Access, draw-over-other-apps).
class FocusModeNativeService {
  FocusModeNativeService._();
  static final FocusModeNativeService instance = FocusModeNativeService._();

  static const _channel = MethodChannel('paceai/focus_mode');

  /// Pushes the full current schedule map to native. Call this any time
  /// [schedules] changes (app added/removed/edited) while Focus Mode is on.
  Future<void> updateSchedules(
    Map<String, FocusBlockSchedule> schedules,
  ) async {
    final payload = schedules.map(
      (packageName, schedule) => MapEntry(packageName, {
        'startMinutes': schedule.start.hour * 60 + schedule.start.minute,
        'endMinutes': schedule.end.hour * 60 + schedule.end.minute,
        // Weekday enum is sun=0..sat=6, matching Calendar.DAY_OF_WEEK-1 on native side.
        'days': schedule.days.map((d) => d.index).toList(),
      }),
    );
    await _channel.invokeMethod('updateSchedules', payload);
  }

  Future<void> startFocusService() async {
    await _channel.invokeMethod('startFocusService');
  }

  Future<void> stopFocusService() async {
    await _channel.invokeMethod('stopFocusService');
  }

  Future<List<InstalledSocialApp>> getInstalledSocialApps() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getInstalledSocialApps');
      if (result == null) return [];
      return result
          .cast<Map<dynamic, dynamic>>()
          .map(InstalledSocialApp.fromMap)
          .toList();
    } on PlatformException {
      return [];
    }
  }

  Future<bool> hasUsageAccess() async {
    final result = await _channel.invokeMethod<bool>('hasUsageAccess');
    return result ?? false;
  }

  /// Opens the system Usage Access settings screen. There is no callback
  /// for "granted" - the caller should re-check hasUsageAccess() when the
  /// app resumes (e.g. via WidgetsBindingObserver.didChangeAppLifecycleState).
  Future<void> requestUsageAccess() async {
    await _channel.invokeMethod('requestUsageAccess');
  }

  Future<bool> hasOverlayPermission() async {
    final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
    return result ?? false;
  }

  Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }
}
