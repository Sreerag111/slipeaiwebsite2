import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../theme/theme_controller.dart';
import '../../../../theme/app_theme.dart';
import '../../../chat/presentation/pages/home_screen.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/widgets/premium_dialog.dart';
import '../../data/services/focus_mode_native_service.dart';
import '../../domain/entities/focus_block_schedule.dart';
import '../widgets/block_schedule_dialog.dart';

enum _PendingPermission { none, overlay, usage }

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

enum _LoadState { loading, loaded, error }

class _FocusModeScreenState extends State<FocusModeScreen>
    with WidgetsBindingObserver {
  bool _focusModeEnabled = false;
  _LoadState _loadState = _LoadState.loading;
  List<BlockableApp> _apps = [];

  // appId -> chosen schedule, only present for apps that are blocked.
  final Map<String, FocusBlockSchedule> _schedules = {};

  _PendingPermission _pendingPermission = _PendingPermission.none;
  static const _kPrefsEnabled = 'focus_mode_enabled';
  static const _kPrefsSchedules = 'focus_mode_schedules_json';

  static const _channel = MethodChannel('paceai/focus_mode');

  bool _permissionIssue = false;
  String? _permissionIssueDetail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler(_handleNativeCall);
    _restorePersistedState();
    if (_focusModeEnabled) {
      FocusModeNativeService.instance.updateSchedules(_schedules);
      FocusModeNativeService.instance.startFocusService();
      _recheckPermissions();
    }
    _loadApps();
  }

  void _restorePersistedState() {
    final prefs = Get.find<SharedPreferences>();
    final persistedEnabled = prefs.getBool(_kPrefsEnabled) ?? false;
    final hasPremium = Get.find<PremiumController>().isPremium.value;
    final enabled = hasPremium && persistedEnabled;
    if (persistedEnabled && !hasPremium) {
      unawaited(Future.wait([
        prefs.setBool(_kPrefsEnabled, false),
        FocusModeNativeService.instance.stopFocusService(),
      ]));
    }
    final raw = prefs.getString(_kPrefsSchedules);
    final restored = <String, FocusBlockSchedule>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((pkg, value) {
          final map = value as Map<String, dynamic>;
          restored[pkg] = FocusBlockSchedule(
            start:
                TimeOfDay(hour: map['startHour'], minute: map['startMinute']),
            end: TimeOfDay(hour: map['endHour'], minute: map['endMinute']),
            days: (map['days'] as List)
                .map((i) => Weekday.values[i as int])
                .toSet(),
          );
        });
      } catch (_) {
        // Corrupt/old data - ignore and start fresh rather than crash.
      }
    }
    setState(() {
      _focusModeEnabled = enabled;
      _schedules
        ..clear()
        ..addAll(restored);
    });
  }

  Future<void> _persistState() async {
    final prefs = Get.find<SharedPreferences>();
    await prefs.setBool(_kPrefsEnabled, _focusModeEnabled);
    final encoded = _schedules.map(
      (pkg, s) => MapEntry(pkg, {
        'startHour': s.start.hour,
        'startMinute': s.start.minute,
        'endHour': s.end.hour,
        'endMinute': s.end.minute,
        'days': s.days.map((d) => d.index).toList(),
      }),
    );
    await prefs.setString(_kPrefsSchedules, jsonEncode(encoded));
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    if (_pendingPermission != _PendingPermission.none) {
      final pending = _pendingPermission;
      _pendingPermission = _PendingPermission.none;
      _resumePermissionFlow(pending);
    } else {
      // Not mid-request - still worth checking in case a permission was
      // revoked while the app was backgrounded/killed.
      _recheckPermissions();
    }
  }

  Future<void> _resumePermissionFlow(_PendingPermission justRequested) async {
    if (justRequested == _PendingPermission.overlay) {
      final granted =
          await FocusModeNativeService.instance.hasOverlayPermission();
      if (!granted) {
        _showPermissionDeniedSnack('Display over other apps');
        return;
      }
      await _proceedToUsageAccessStep();
    } else if (justRequested == _PendingPermission.usage) {
      final granted = await FocusModeNativeService.instance.hasUsageAccess();
      if (!granted) {
        _showPermissionDeniedSnack('Usage Access');
        return;
      }
      await _enableFocusMode();
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onPermissionLost':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final usageOk = args['usageAccess'] as bool;
        final overlayOk = args['overlay'] as bool;
        if (!mounted) return;
        setState(() {
          _permissionIssue = true;
          _permissionIssueDetail = !usageOk && !overlayOk
              ? 'Usage access and display-over-apps were both turned off.'
              : !usageOk
                  ? 'Usage access was turned off.'
                  : 'Display-over-apps permission was turned off.';
        });
        break;

      case 'onPermissionRestored':
        if (!mounted) return;
        setState(() {
          _permissionIssue = false;
          _permissionIssueDetail = null;
        });
        break;
    }
  }

  Future<void> _recheckPermissions() async {
    if (!_focusModeEnabled) return; // nothing to enforce if it's off anyway
    final usageOk = await FocusModeNativeService.instance.hasUsageAccess();
    final overlayOk =
        await FocusModeNativeService.instance.hasOverlayPermission();
    if (!mounted) return;
    setState(() {
      _permissionIssue = !(usageOk && overlayOk);
      _permissionIssueDetail = !usageOk && !overlayOk
          ? 'Usage access and display-over-apps were both turned off.'
          : !usageOk
              ? 'Usage access was turned off.'
              : !overlayOk
                  ? 'Display-over-apps permission was turned off.'
                  : null;
    });
  }

  Future<void> _loadApps() async {
    setState(() => _loadState = _LoadState.loading);
    try {
      final installed =
          await FocusModeNativeService.instance.getInstalledSocialApps();
      setState(() {
        _apps = installed
            .map((a) => BlockableApp(
                  id: a.packageName,
                  name: a.appName,
                  iconBytes: a.iconBytes,
                ))
            .toList();
        _loadState = _LoadState.loaded;
      });
    } catch (_) {
      setState(() => _loadState = _LoadState.error);
    }
  }

  Future<void> _onMasterToggle(bool turningOn) async {
    if (!turningOn) {
      setState(() {
        _focusModeEnabled = false;
        _schedules.clear();
      });
      await FocusModeNativeService.instance.stopFocusService();
      await _persistState();
      return;
    }

    if (!Get.find<PremiumController>().isPremium.value) {
      if (mounted) showPremiumDialog(context);
      return;
    }

    await _proceedToOverlayStep();
  }

  Future<void> _proceedToOverlayStep() async {
    final hasOverlay =
        await FocusModeNativeService.instance.hasOverlayPermission();
    if (hasOverlay) {
      await _proceedToUsageAccessStep();
      return;
    }
    if (!mounted) return;
    final shouldRequest = await _showPermissionExplainer(
      title: 'Display over other apps',
      message:
          'Focus Mode needs this permission to show the block screen on top '
          'of a distracting app the moment you open it. Without it, '
          'blocked apps can\'t actually be blocked.',
    );
    if (shouldRequest != true) return;
    _pendingPermission = _PendingPermission.overlay;
    await FocusModeNativeService.instance.requestOverlayPermission();
  }

  Future<void> _proceedToUsageAccessStep() async {
    final hasAccess = await FocusModeNativeService.instance.hasUsageAccess();
    if (hasAccess) {
      await _enableFocusMode();
      return;
    }
    if (!mounted) return;
    final shouldRequest = await _showPermissionExplainer(
      title: 'Usage Access',
      message: 'Focus Mode needs Usage Access to detect which app you\'re '
          'currently using, so it knows when a blocked app has been opened.',
    );
    if (shouldRequest != true) return;
    _pendingPermission = _PendingPermission.usage;
    await FocusModeNativeService.instance.requestUsageAccess();
  }

  Future<void> _enableFocusMode() async {
    if (!mounted) return;
    setState(() => _focusModeEnabled = true);
    await FocusModeNativeService.instance.updateSchedules(_schedules);
    await FocusModeNativeService.instance.startFocusService();
    await _persistState();
  }

  void _showPermissionDeniedSnack(String permissionName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$permissionName wasn\'t granted, so Focus Mode can\'t start yet.',
        ),
      ),
    );
  }

  Future<bool?> _showPermissionExplainer({
    required String title,
    required String message,
  }) {
    final isDark = ThemeController.instance.isDarkMode;
    final dialogBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(title, style: TextStyle(color: titleColor)),
        content: Text(message, style: TextStyle(color: bodyColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: kFocusAccent)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kFocusAccent,
              foregroundColor: AppTheme.onAccent,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Open Settings',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAppToggle(BlockableApp app, bool turningOn) async {
    if (!turningOn) {
      setState(() => _schedules.remove(app.id));
      await FocusModeNativeService.instance.updateSchedules(_schedules);
      await _persistState();
      return;
    }

    final schedule = await showBlockScheduleDialog(
      context,
      appName: app.name,
      initial: _schedules[app.id],
    );

    if (schedule == null) return; // cancelled - toggle stays off

    setState(() => _schedules[app.id] = schedule);
    await FocusModeNativeService.instance.updateSchedules(_schedules);
    await _persistState();
  }

  Future<void> _editAppSchedule(BlockableApp app) async {
    final currentSchedule = _schedules[app.id];

    if (currentSchedule == null) return;

    final updatedSchedule = await showBlockScheduleDialog(
      context,
      appName: app.name,
      initial: currentSchedule,
    );

    if (updatedSchedule == null) return;

    setState(() {
      _schedules[app.id] = updatedSchedule;
    });

    await FocusModeNativeService.instance.updateSchedules(_schedules);
    await _persistState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final scaffoldBg = isDark ? Colors.black : const Color(0xFFF5F6F8);
      final textColor = isDark ? Colors.white : Colors.black;
      final mutedColor = isDark ? Colors.white70 : Colors.black87;
      final cardColor =
          isDark ? Colors.white.withValues(alpha: .06) : Colors.white;
      final cardBorder =
          isDark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1);
      final dividerColor = isDark ? Colors.white12 : null;

      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          foregroundColor: textColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                // Opened fresh (e.g. cold-started from the notification tap
                // with nothing else on the stack) - go Home instead of
                // leaving the user stuck with no way out.
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
          title: Text(
            'Focus Mode',
            style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _loadApps,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Text(
                'Block distracting apps and stay focused on what matters.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              // ── Focus Mode master card
              _Card(
                color: cardColor,
                border: cardBorder,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Focus Mode',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textColor)),
                            const SizedBox(height: 4),
                            Text(
                              'Block selected apps during focus time',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: mutedColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _focusModeEnabled,
                        activeThumbColor: kFocusAccent,
                        onChanged: _onMasterToggle,
                      ),
                    ],
                  ),
                ),
              ),

              if (_permissionIssue) ...[
                const SizedBox(height: 14),
                _PermissionIssueBanner(
                  isDark: isDark,
                  message: _permissionIssueDetail ??
                      'A required permission was turned off.',
                  onFix: () async {
                    final overlayOk = await FocusModeNativeService.instance
                        .hasOverlayPermission();
                    if (!overlayOk) {
                      await FocusModeNativeService.instance
                          .requestOverlayPermission();
                    } else {
                      await FocusModeNativeService.instance
                          .requestUsageAccess();
                    }
                  },
                ),
              ],

              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: !_focusModeEnabled
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 22),
                          Text(
                            'Select Apps',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Apps will be blocked during their scheduled time',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAppsSection(
                            cardColor: cardColor,
                            cardBorder: cardBorder,
                            dividerColor: dividerColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAppsSection({
    required Color cardColor,
    required BoxBorder? cardBorder,
    required Color? dividerColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    if (_loadState == _LoadState.loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: kFocusAccent)),
      );
    }

    if (_loadState == _LoadState.error) {
      return _Card(
        color: cardColor,
        border: cardBorder,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Couldn\'t load installed apps.',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _loadApps, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_apps.isEmpty) {
      return _Card(
        color: cardColor,
        border: cardBorder,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No supported social apps found on this device.',
            style: TextStyle(
              color: mutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return _Card(
      color: cardColor,
      border: cardBorder,
      child: Column(
        children: [
          for (int i = 0; i < _apps.length; i++) ...[
            _AppRow(
              app: _apps[i],
              schedule: _schedules[_apps[i].id],
              textColor: textColor,
              onChanged: (turningOn) => _onAppToggle(_apps[i], turningOn),
              onScheduleTap: () => _editAppSchedule(_apps[i]),
            ),
            if (i != _apps.length - 1)
              Divider(height: 1, indent: 60, color: dividerColor),
          ],
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.schedule,
    required this.textColor,
    required this.onChanged,
    required this.onScheduleTap,
  });

  final BlockableApp app;
  final FocusBlockSchedule? schedule;
  final Color textColor;
  final ValueChanged<bool> onChanged;
  final VoidCallback onScheduleTap;

  @override
  Widget build(BuildContext context) {
    final isOn = schedule != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: app.iconBytes != null
                ? Image.memory(app.iconBytes!, width: 36, height: 36)
                : Container(
                    width: 36,
                    height: 36,
                    color:
                        (app.iconColor ?? Colors.grey).withValues(alpha: .12),
                    child: Icon(
                      app.icon ?? Icons.apps_rounded,
                      color: app.iconColor ?? Colors.grey,
                      size: 19,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                if (isOn) ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: onScheduleTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 2,
                      ),
                      child: Text(
                        '${schedule!.formatRange(context)} • '
                        '${schedule!.days.map((d) => d.shortLabel).join(', ')}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: kFocusAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: isOn,
            activeThumbColor: kFocusAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.color, this.border});
  final Widget child;
  final Color color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: border == null
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _PermissionIssueBanner extends StatelessWidget {
  const _PermissionIssueBanner({
    required this.message,
    required this.onFix,
    required this.isDark,
  });
  final String message;
  final VoidCallback onFix;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Slightly stronger tint + border on dark backgrounds so the banner
    // doesn't get lost against a near-black scaffold.
    final bgAlpha = isDark ? .18 : .12;
    final borderAlpha = isDark ? .45 : .35;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.orange[300]! : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Focus Mode paused. $message',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          TextButton(
            onPressed: onFix,
            child: Text('Fix', style: TextStyle(color: kFocusAccent)),
          ),
        ],
      ),
    );
  }
}
