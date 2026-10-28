import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late final Razorpay _razorpay;

  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();

    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );
  }

  void openSubscriptionCheckout({
    required String key,
    required String subscriptionId,
    required String name,
    required String description,
    required String email,
  }) {
    final prefill = <String, String>{};
    if (email.trim().isNotEmpty) {
      prefill['email'] = email.trim();
    }
    final options = {
      "key": key,
      "subscription_id": subscriptionId,
      "name": name,
      "description": description,
      if (prefill.isNotEmpty) "prefill": prefill,
      "theme": {
        "color": "#5E5CE6",
      },
    };

    if (kDebugMode) {
      final keyMode = key.startsWith('rzp_live_')
          ? 'live'
          : key.startsWith('rzp_test_')
              ? 'test'
              : 'unknown';
      debugPrint(
        '[RazorpayCheckoutDebug] Opening subscription checkout: '
        'keyMode=$keyMode, keySuffix=${_suffix(key)}, '
        'subscriptionIdPrefix=${_prefix(subscriptionId)}, '
        'emailPrefilled=${prefill.containsKey('email')}, '
        'optionKeys=${options.keys.join(',')}, '
        'methodRestricted=${options.containsKey('method')}, '
        'configRestricted=${options.containsKey('config')}',
      );
    }

    _razorpay.open(options);
  }

  void openOneTimeCheckout({
    required String key,
    required String orderId,
    required int amountPaise,
    required String name,
    required String description,
    required String email,
  }) {
    final prefill = <String, String>{};
    if (email.trim().isNotEmpty) prefill['email'] = email.trim();
    _razorpay.open({
      'key': key,
      'order_id': orderId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': name,
      'description': description,
      if (prefill.isNotEmpty) 'prefill': prefill,
      'theme': {'color': '#5E5CE6'},
    });
  }

  void _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) {
    if (kDebugMode) {
      debugPrint(
        '[RazorpayCheckoutDebug] Payment success: '
        'paymentIdPrefix=${_prefix(response.paymentId)}, '
        'orderOrSubscriptionIdPrefix=${_prefix(response.orderId)}, '
        'signaturePresent=${response.signature?.isNotEmpty == true}',
      );
    }
    onSuccess?.call(response);
  }

  void _handlePaymentError(
    PaymentFailureResponse response,
  ) {
    if (kDebugMode) {
      debugPrint(
        '[RazorpayCheckoutDebug] Payment failure: '
        'code=${response.code}, message=${response.message}',
      );
    }
    onFailure?.call(response);
  }

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    if (kDebugMode) {
      debugPrint(
        '[RazorpayCheckoutDebug] External wallet selected: '
        'wallet=${response.walletName}',
      );
    }
    onExternalWallet?.call(response);
  }

  String _prefix(String? value) {
    if (value == null || value.isEmpty) return 'none';
    return value.substring(0, value.length < 10 ? value.length : 10);
  }

  String _suffix(String value) {
    if (value.isEmpty) return 'none';
    final start = value.length > 6 ? value.length - 6 : 0;
    return value.substring(start);
  }

  void dispose() {
    _razorpay.clear();
  }
}
