import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkController extends GetxController with WidgetsBindingObserver {
  NetworkController({InternetConnection? connection})
      : _connection = connection ?? InternetConnection();

  final InternetConnection _connection;
  final RxBool isOffline = false.obs;
  final RxBool showReconnected = false.obs;
  StreamSubscription<InternetStatus>? _statusSubscription;
  Timer? _offlinePollTimer;
  Timer? _reconnectedBannerTimer;
  bool _isRefreshing = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _statusSubscription = _connection.onStatusChange.listen(_applyStatus);
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final hasInternet = await _connection.hasInternetAccess;
      _setOffline(!hasInternet);
    } catch (_) {
      _setOffline(true);
    } finally {
      _isRefreshing = false;
    }
  }

  void _applyStatus(InternetStatus status) {
    _setOffline(status == InternetStatus.disconnected);
  }

  void _setOffline(bool offline) {
    if (offline) {
      _reconnectedBannerTimer?.cancel();
      showReconnected.value = false;
      isOffline.value = true;
      _startOfflinePolling();
      return;
    }

    final wasOffline = isOffline.value;
    isOffline.value = false;
    _offlinePollTimer?.cancel();
    _offlinePollTimer = null;

    if (wasOffline) {
      showReconnected.value = true;
      _reconnectedBannerTimer?.cancel();
      _reconnectedBannerTimer = Timer(const Duration(seconds: 2), () {
        showReconnected.value = false;
      });
    }
  }

  void _startOfflinePolling() {
    _offlinePollTimer ??= Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => unawaited(refresh()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusSubscription?.cancel();
    _offlinePollTimer?.cancel();
    _reconnectedBannerTimer?.cancel();
    super.onClose();
  }
}
