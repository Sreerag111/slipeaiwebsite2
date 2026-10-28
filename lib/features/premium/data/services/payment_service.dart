import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Creates a subscription using the trial configured in Firestore.
  Future<Map<String, dynamic>> createSubscription({
    required String planId,
  }) async {
    final callable = _functions.httpsCallable('createSubscription');
    if (kDebugMode) {
      debugPrint('[SubscriptionDebug] Calling createSubscription: '
          'planId=$planId');
    }

    try {
      final result = await callable.call({
        'planId': planId,
      });
      final data = Map<String, dynamic>.from(result.data);
      if (kDebugMode) {
        debugPrint('[SubscriptionDebug] createSubscription succeeded: '
            'planId=${data['planId']}, status=${data['status']}, '
            'subscriptionIdPrefix=${_prefix(data['subscriptionId'])}, '
            'hasTrial=${data['hasTrial']}, '
            'trialDays=${data['trialDays']}, reused=${data['reused']}');
      }
      return data;
    } on FirebaseFunctionsException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SubscriptionDebug] createSubscription failed: '
            'code=${error.code}, message=${error.message}, '
            'details=${error.details}');
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SubscriptionDebug] Unexpected createSubscription error: '
            '${error.runtimeType}: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOneTimeOrder({
    required String planId,
  }) async {
    final callable = _functions.httpsCallable('createOneTimeOrder');
    final result = await callable.call({'planId': planId});
    return Map<String, dynamic>.from(result.data);
  }

  String _prefix(dynamic value) {
    if (value is! String || value.isEmpty) return 'none';
    return value.substring(0, value.length < 10 ? value.length : 10);
  }

  Future<Map<String, dynamic>> verifySubscription({
    required String paymentId,
    required String subscriptionId,
    required String signature,
    required String planId,
  }) async {
    final callable = _functions.httpsCallable('verifySubscription');

    final result = await callable.call({
      "paymentId": paymentId,
      "subscriptionId": subscriptionId,
      "signature": signature,
      "planId": planId,
    });

    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> verifyOneTimePayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String planId,
  }) async {
    final callable = _functions.httpsCallable('verifyOneTimePayment');
    final result = await callable.call({
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'planId': planId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> getPremiumStatus() async {
    final callable = _functions.httpsCallable('getPremiumStatus');
    final result = await callable.call();
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> cancelSubscription({
    bool cancelAtCycleEnd = true,
  }) async {
    final callable = _functions.httpsCallable('cancelSubscription');
    final result = await callable.call({
      'cancelAtCycleEnd': cancelAtCycleEnd,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
