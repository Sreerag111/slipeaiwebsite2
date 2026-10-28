import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../data/services/floating_bubble_service.dart';
import '../../data/services/screen_capture_service.dart';

class CompanionController extends GetxController with WidgetsBindingObserver {
  final RxBool hasPermission = false.obs;
  final RxBool isRunning = false.obs;
  final RxBool isLoading = true.obs;

  final RxBool isScreenSharing = false.obs;
  final RxString screenStatus = ''.obs;
  final RxInt contextUpdates = 0.obs;

  final RxString ocrText = ''.obs;
  final RxString appName = ''.obs;
  final RxString screenName = ''.obs;
  final RxBool hasError = false.obs;
  final RxBool hasCode = false.obs;
  final RxInt frameNumber = 0.obs;

  final RxString screenAnalysis = ''.obs;
  final RxBool isAnalyzing = false.obs;
  final RxString analysisStatus = ''.obs;
  final RxString lastError = ''.obs;
  final RxInt totalAnalyses = 0.obs;

  final ScreenCaptureService _screenService = ScreenCaptureService();
  StreamSubscription<ScreenContextData>? _contextSub;
  StreamSubscription<String>? _statusSub;

  bool _disposed = false;
  final RxBool isToggling = false.obs;
  bool _pendingToggleAfterPermission = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void onClose() {
    _disposed = true;
    isToggling.value = false;
    _pendingToggleAfterPermission = false;
    WidgetsBinding.instance.removeObserver(this);
    _contextSub?.cancel();
    _statusSub?.cancel();
    _screenService.stopScreenShare();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.resumed) {
      refresh().then((_) {
        if (_pendingToggleAfterPermission &&
            hasPermission.value &&
            !isRunning.value) {
          _pendingToggleAfterPermission = false;
          toggle();
        }
      });
    } else if (state == AppLifecycleState.detached) {
      _contextSub?.cancel();
      _statusSub?.cancel();
      _screenService.stopScreenShare();
    }
  }

  Future<void> refresh() async {
    if (_disposed) return;
    hasPermission.value = await FloatingBubbleService.hasPermission();
    isRunning.value = await FloatingBubbleService.isRunning();
    isLoading.value = false;
  }

  Future<void> requestPermission() async {
    await FloatingBubbleService.requestPermission();
    await refresh();
  }

  Future<String?> toggle() async {
    debugPrint(
        '[CompanionToggle] toggle() called — disposed=$_disposed isToggling=${isToggling.value}');
    if (_disposed || isToggling.value) return null;
    if (!isRunning.value &&
        !Get.find<PremiumController>().isPremium.value) {
      return 'Premium subscription required';
    }
    isToggling.value = true;
    try {
      debugPrint(
          '[CompanionToggle] hasPermission=${hasPermission.value} isRunning=${isRunning.value}');
      if (!hasPermission.value) {
        _pendingToggleAfterPermission = true;
        debugPrint('[CompanionToggle] No overlay permission — requesting');
        await requestPermission();
        debugPrint(
            '[CompanionToggle] Permission request done — hasPermission=${hasPermission.value}');
        return null;
      }
      final wasRunning = isRunning.value;
      if (wasRunning) {
        debugPrint('[CompanionToggle] Stopping service');
        await FloatingBubbleService.stop();
      } else {
        debugPrint('[CompanionToggle] Starting service');
        final started = await FloatingBubbleService.start();
        debugPrint('[CompanionToggle] start() returned $started');
        if (!started) {
          await refresh();
          final msg = 'Overlay permission is still required';
          debugPrint('[CompanionToggle] $msg');
          return msg;
        }
      }
      final expected = !wasRunning;
      debugPrint('[CompanionToggle] Polling for isRunning=$expected');
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await refresh();
        debugPrint(
            '[CompanionToggle] Poll $i: isRunning=${isRunning.value} (expected=$expected)');
        if (isRunning.value == expected) {
          debugPrint('[CompanionToggle] State reached!');
          return null;
        }
      }
      final err = wasRunning
          ? 'Failed to stop companion service'
          : 'Failed to start companion service';
      debugPrint('[CompanionToggle] Timeout: $err');
      return err;
    } finally {
      isToggling.value = false;
      debugPrint('[CompanionToggle] isToggling reset to false');
    }
  }

  Future<String?> startScreenShare() async {
    if (_disposed || isScreenSharing.value) return null;
    if (!Get.find<PremiumController>().isPremium.value) {
      return 'Premium subscription required';
    }

    screenStatus.value = 'Starting...';
    _resetState();

    debugPrint('[Companion] Starting live screen understanding...');
    final error = await _screenService.startScreenShare();
    if (error != null) {
      screenStatus.value = 'Failed: $error';
      lastError.value = error;
      return error;
    }

    isScreenSharing.value = true;
    screenStatus.value = 'Live';
    debugPrint('[Companion] Live screen analysis active');

    _contextSub?.cancel();
    _contextSub = _screenService.contextStream.listen(
      (context) {
        if (_disposed) return;
        ocrText.value = context.ocrText;
        appName.value = context.appName;
        screenName.value = context.screenName;
        hasError.value = context.hasError;
        hasCode.value = context.hasCode;
        frameNumber.value = context.frameNumber;
        contextUpdates.value = _screenService.totalContextUpdates;
      },
      onError: (e) {
        debugPrint('[Companion] Context stream error: $e');
      },
    );

    _statusSub?.cancel();
    _statusSub = _screenService.statusStream.listen(
      (status) {
        if (_disposed) return;
        if (status == 'stopped') {
          debugPrint('[Companion] System stopped screen analysis');
          stopScreenShare();
        } else if (status.startsWith('ai_response:')) {
          _handleAiResponse(status);
        } else if (status.startsWith('ai_error:')) {
          _handleAiError(status);
        }
      },
      onError: (e) {
        debugPrint('[Companion] Status stream error: $e');
      },
    );

    return null;
  }

  void _handleAiResponse(String status) {
    final parts = status.split(':');
    if (parts.length >= 3) {
      final response = parts.sublist(1, parts.length - 1).join(':');
      screenAnalysis.value = response;
      totalAnalyses.value++;
      analysisStatus.value = 'AI (${totalAnalyses.value})';
      lastError.value = '';
      debugPrint('[Companion] AI response: ${response.length} chars');
    }
  }

  void _handleAiError(String status) {
    final error = status.substring('ai_error:'.length);
    lastError.value = error;
    analysisStatus.value = 'Failed';
    debugPrint('[Companion] AI error: $error');
  }

  void _resetState() {
    ocrText.value = '';
    appName.value = '';
    screenName.value = '';
    hasError.value = false;
    hasCode.value = false;
    frameNumber.value = 0;
    screenAnalysis.value = '';
    isAnalyzing.value = false;
    analysisStatus.value = '';
    lastError.value = '';
    totalAnalyses.value = 0;
    contextUpdates.value = 0;
  }

  Future<void> stopScreenShare() async {
    _contextSub?.cancel();
    _contextSub = null;
    _statusSub?.cancel();
    _statusSub = null;
    try {
      await _screenService.stopScreenShare();
    } catch (_) {}
    isScreenSharing.value = false;
    screenStatus.value = '';
    _resetState();
  }
}
