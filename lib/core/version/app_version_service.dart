import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum AppUpdateStatus {
  upToDate,
  softUpdateAvailable,
  forceUpdateRequired,
}

class AppVersionConfig {
  const AppVersionConfig({
    required this.minSupportedBuild,
    required this.latestBuild,
    required this.forceUpdate,
    required this.title,
    required this.message,
    required this.playStoreUrl,
  });

  final int minSupportedBuild;
  final int latestBuild;
  final bool forceUpdate;
  final String title;
  final String message;
  final String playStoreUrl;

  factory AppVersionConfig.fromFirestore(Map<String, dynamic>? data) {
    return AppVersionConfig(
      minSupportedBuild: (data?['min_supported_build'] as num?)?.toInt() ?? 1,
      latestBuild: (data?['latest_build'] as num?)?.toInt() ?? 1,
      forceUpdate: data?['force_update'] as bool? ?? true,
      title: data?['title'] as String? ?? 'Update Available',
      message: data?['message'] as String? ??
          'A new version of Slipe AI is available with the latest features and performance updates. Please update to continue.',
      playStoreUrl: data?['play_store_url'] as String? ??
          'https://play.google.com/store/apps/details?id=com.paceai.paceai',
    );
  }
}

class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  int? _currentBuildNumber;
  String? _currentVersionName;
  AppVersionConfig? _cachedConfig;

  int? get currentBuildNumber => _currentBuildNumber;
  String? get currentVersionName => _currentVersionName;
  AppVersionConfig? get currentConfig => _cachedConfig;

  /// Returns the current runtime build number, initializing from platform if necessary.
  Future<int> getEffectiveBuildNumber() async {
    if (debugOverrideCurrentBuild != null) {
      return debugOverrideCurrentBuild!;
    }
    if (_currentBuildNumber != null) {
      return _currentBuildNumber!;
    }
    await initialize();
    return _currentBuildNumber ?? 1;
  }

  // Debug overrides for easy manual testing and unit tests
  int? debugOverrideCurrentBuild;
  int? debugOverrideMinBuild;
  AppVersionConfig? debugOverrideConfig;

  Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersionName = info.version;
      _currentBuildNumber = int.tryParse(info.buildNumber) ?? 1;
    } catch (e) {
      debugPrint('[AppVersionService] Failed to load PackageInfo: $e');
      _currentVersionName = '1.0.0';
      _currentBuildNumber = 1;
    }
    debugPrint(
      '[AppVersionService] Current version: $_currentVersionName '
      'build: $_currentBuildNumber',
    );
  }

  Future<AppUpdateStatus>? _inFlightCheck;

  Future<AppUpdateStatus> checkUpdateStatus({bool forceRefresh = false}) {
    if (!forceRefresh && _cachedConfig != null) {
      return Future.value(_evaluateStatus());
    }
    if (_inFlightCheck != null && !forceRefresh) {
      return _inFlightCheck!;
    }
    final future = _performCheckUpdateStatus(forceRefresh: forceRefresh);
    _inFlightCheck = future;
    return future;
  }

  Future<AppUpdateStatus> _performCheckUpdateStatus({
    bool forceRefresh = false,
  }) async {
    try {
      if (_currentBuildNumber == null) {
        await initialize();
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('app_config')
            .doc('version_control')
            .get(GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ))
            .timeout(const Duration(seconds: 4));

        if (doc.exists && doc.data() != null) {
          _cachedConfig = AppVersionConfig.fromFirestore(doc.data());
        }
      } catch (e) {
        debugPrint('[AppVersionService] Failed to fetch version_control: $e');
      }

      return _evaluateStatus();
    } finally {
      _inFlightCheck = null;
    }
  }

  AppUpdateStatus _evaluateStatus() {
    final effectiveBuild =
        debugOverrideCurrentBuild ?? _currentBuildNumber ?? 999;
    final config = debugOverrideConfig ?? _cachedConfig;
    if (config == null) {
      return AppUpdateStatus.upToDate;
    }

    final effectiveMin =
        debugOverrideMinBuild ?? config.minSupportedBuild;

    debugPrint(
      '[AppVersionService] Checking: clientBuild=$effectiveBuild, '
      'minSupported=$effectiveMin, latest=${config.latestBuild}, '
      'force=${config.forceUpdate}',
    );

    if (effectiveBuild < effectiveMin && config.forceUpdate) {
      return AppUpdateStatus.forceUpdateRequired;
    }

    if (effectiveBuild < config.latestBuild) {
      return AppUpdateStatus.softUpdateAvailable;
    }

    return AppUpdateStatus.upToDate;
  }

  Future<void> launchStoreUpdate({String? customUrl}) async {
    final urlString = customUrl ??
        _cachedConfig?.playStoreUrl ??
        'https://play.google.com/store/apps/details?id=com.paceai.paceai';

    try {
      if (Platform.isAndroid) {
        final marketUri = Uri.parse('market://details?id=com.paceai.paceai');
        if (await canLaunchUrl(marketUri)) {
          await launchUrl(marketUri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      final webUri = Uri.parse(urlString);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AppVersionService] Could not launch store URL: $e');
    }
  }
}
