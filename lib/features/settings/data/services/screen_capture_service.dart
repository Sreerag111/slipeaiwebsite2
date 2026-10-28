import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenContextData {
  final String ocrText;
  final double ocrConfidence;
  final bool hasCode;
  final bool hasError;
  final bool hasButtons;
  final String contextJson;
  final int frameNumber;
  final double changeMagnitude;
  final bool isSignificant;

  const ScreenContextData({
    this.ocrText = '',
    this.ocrConfidence = 0.0,
    this.hasCode = false,
    this.hasError = false,
    this.hasButtons = false,
    this.contextJson = '',
    this.frameNumber = 0,
    this.changeMagnitude = 0.0,
    this.isSignificant = false,
  });

  bool get hasSufficientText =>
      ocrText.length > 20 && ocrConfidence > 0.3;

  Map<String, dynamic>? get parsedContext {
    try {
      return contextJson.isNotEmpty ? jsonDecode(contextJson) as Map<String, dynamic> : null;
    } catch (_) {
      return null;
    }
  }

  String get appName {
    final ctx = parsedContext;
    return ctx?['app'] as String? ?? '';
  }

  String get screenName {
    final ctx = parsedContext;
    return ctx?['screen'] as String? ?? '';
  }

  List<String> get visibleText {
    final ctx = parsedContext;
    if (ctx?['visibleText'] != null) {
      return List<String>.from(ctx!['visibleText'] as List);
    }
    return [];
  }

  List<String> get buttons {
    final ctx = parsedContext;
    if (ctx?['actions'] != null) {
      return List<String>.from(ctx!['actions'] as List);
    }
    return [];
  }
}

class ScreenCaptureService {
  static const _channel = MethodChannel('com.blide.ai/screen_capture');

  static final ScreenCaptureService _instance = ScreenCaptureService._();
  factory ScreenCaptureService() => _instance;
  ScreenCaptureService._();

  final StreamController<ScreenContextData> _contextController =
      StreamController<ScreenContextData>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  Stream<ScreenContextData> get contextStream => _contextController.stream;
  Stream<String> get statusStream => _statusController.stream;

  bool _isSharing = false;
  bool get isSharing => _isSharing;

  int _totalContextUpdates = 0;
  int get totalContextUpdates => _totalContextUpdates;

  ScreenContextData _latestContext = const ScreenContextData();
  ScreenContextData get latestContext => _latestContext;

  void _ensureHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenShareEvent') {
        final args = call.arguments as Map?;
        if (args == null) return;
        final type = args['type'] as String?;
        final data = args['data'] as Map?;
        if (data == null) return;

        switch (type) {
          case 'screenContext':
            _handleContextUpdate(data);
            break;
          case 'status':
            _handleStatus(data);
            break;
          case 'aiResponse':
            _handleAiResponse(data);
            break;
          case 'aiError':
            _handleAiError(data);
            break;
        }
      }
      return null;
    });
  }

  void _handleContextUpdate(Map data) {
    final ocrText = data['ocrText'] as String? ?? '';
    final ocrConfidence = (data['ocrConfidence'] as num?)?.toDouble() ?? 0.0;
    final hasCode = data['hasCode'] as bool? ?? false;
    final hasError = data['hasError'] as bool? ?? false;
    final hasButtons = data['hasButtons'] as bool? ?? false;
    final contextJson = data['context'] as String? ?? '';
    final frameNumber = (data['frameNumber'] as num?)?.toInt() ?? 0;
    final changeMag = (data['changeMagnitude'] as num?)?.toDouble() ?? 0.0;
    final isSignificant = data['isSignificantChange'] as bool? ?? false;

    final context = ScreenContextData(
      ocrText: ocrText,
      ocrConfidence: ocrConfidence,
      hasCode: hasCode,
      hasError: hasError,
      hasButtons: hasButtons,
      contextJson: contextJson,
      frameNumber: frameNumber,
      changeMagnitude: changeMag,
      isSignificant: isSignificant,
    );

    _latestContext = context;
    _totalContextUpdates++;
    _contextController.add(context);

    if (frameNumber % 15 == 0) {
      debugPrint('[ScreenCapture] Context #$frameNumber: '
          'ocr=${ocrText.length}chars app=${context.appName}');
    }
  }

  void _handleStatus(Map data) {
    final status = data['status'] as String?;
    switch (status) {
      case 'started':
        _isSharing = true;
        debugPrint('[ScreenCapture] Screen share started');
        _statusController.add('started');
        break;
      case 'stopped':
      case 'stopped_by_system':
        _isSharing = false;
        debugPrint('[ScreenCapture] Screen share stopped: $status');
        _statusController.add('stopped');
        break;
      case 'error':
        final msg = data['message'] as String? ?? 'Unknown error';
        debugPrint('[ScreenCapture] Error: $msg');
        _statusController.add('error:$msg');
        break;
    }
  }

  void _handleAiResponse(Map data) {
    final response = data['response'] as String?;
    final complete = data['complete'] as bool? ?? false;
    if (response != null) {
      _statusController.add('ai_response:$response:$complete');
    }
  }

  void _handleAiError(Map data) {
    final error = data['error'] as String?;
    if (error != null) {
      debugPrint('[ScreenCapture] AI error: $error');
      _statusController.add('ai_error:$error');
    }
  }

  Future<String?> startScreenShare() async {
    _ensureHandler();
    debugPrint('[ScreenCapture] Starting live screen analysis');

    if (!Platform.isAndroid) {
      return 'Screen analysis only supported on Android';
    }

    try {
      final result = await _channel.invokeMethod<Map>('startScreenShare');
      if (result == null) return 'No result from platform';

      final granted = result['granted'] as bool? ?? false;
      final error = result['error'] as String?;

      if (!granted) {
        debugPrint('[ScreenCapture] Permission denied: $error');
        return error ?? 'Permission denied';
      }

      debugPrint('[ScreenCapture] Permission granted');
      return null;
    } catch (e) {
      debugPrint('[ScreenCapture] Failed to start: $e');
      return e.toString();
    }
  }

  Future<void> stopScreenShare() async {
    _isSharing = false;
    _totalContextUpdates = 0;
    debugPrint('[ScreenCapture] Stopping screen analysis');
    try {
      await _channel.invokeMethod('stopScreenShare');
    } catch (_) {}
  }

  void dispose() {
    _contextController.close();
    _statusController.close();
    _channel.setMethodCallHandler(null);
  }
}
