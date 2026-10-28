import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Logs enhancement metadata in debug builds and redacts provider error text.
class EnhancerDebugLog {
  static void event(String stage, {String? detail}) {
    if (!kDebugMode) return;
    debugPrint('[Enhancer] $stage${detail == null ? '' : ' $detail'}');
  }

  static void failure(String stage, Object error) {
    if (!kDebugMode) return;
    final code = error is FirebaseFunctionsException
        ? error.code
        : error.runtimeType.toString();
    final details = error is FirebaseFunctionsException ? error.details : null;
    final diagnostics = <String>[];
    if (error is FirebaseFunctionsException) {
      diagnostics.add('message=${_safeText(error.message ?? '')}');
    }
    if (details is Map) {
      for (final key in [
        'reason',
        'stage',
        'endpoint',
        'httpStatus',
        'providerCode',
        'providerMessage',
        'responseKeys',
        'errorType',
        'errorMessage',
      ]) {
        final value = details[key];
        if (value is String || value is num) {
          diagnostics.add('$key=${_safeText(value.toString())}');
        }
      }
    }
    debugPrint('[Enhancer] $stage failed type=$code'
        '${diagnostics.isEmpty ? '' : ' ${diagnostics.join(' ')}'}');
  }

  static void providerJobFailure(String stage, Object? details) {
    if (!kDebugMode) return;
    if (details is! Map) {
      debugPrint('[Enhancer] $stage failed reason=PROVIDER_JOB_FAILED '
          'providerDetails=unavailable');
      return;
    }
    final diagnostics = <String>[];
    for (final key in [
      'reason',
      'jobId',
      'category',
      'model',
      'outputFormat',
      'providerCode',
      'providerMessage',
      'responseKeys',
    ]) {
      final value = details[key];
      if (value is String || value is num) {
        diagnostics.add('$key=${_safeText(value.toString())}');
      }
    }
    debugPrint('[Enhancer] $stage failed ${diagnostics.join(' ')}');
  }

  static void playerFailure(
    String stage,
    Object error, {
    required String side,
    String? description,
  }) {
    if (!kDebugMode) return;
    final diagnostics = <String>[
      'side=$side',
      'type=${error.runtimeType}',
      if (description != null && description.isNotEmpty)
        'description=${_safeText(description)}',
    ];
    debugPrint('[Enhancer] $stage failed ${diagnostics.join(' ')}');
  }

  static String _safeText(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'https?://\S+', caseSensitive: false), '[url]')
        .replaceAll(
            RegExp(r'\b(api[_-]?key|authorization|bearer|token)\s*[:=]\s*[^\s,;]+',
                caseSensitive: false),
            '[secret]=[redacted]')
        .replaceAll(RegExp(r'[A-Za-z0-9_-]{40,}'), '[redacted]')
        .replaceAll(RegExp(r'\s+'), ' ');
    return sanitized.length > 240 ? sanitized.substring(0, 240) : sanitized;
  }
}
