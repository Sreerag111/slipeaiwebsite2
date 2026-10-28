import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plagiarism_checker/core/constants/payment_constants.dart';
import 'package:plagiarism_checker/features/premium/data/services/payment_service.dart';
import 'package:plagiarism_checker/features/premium/data/services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../domain/repositories/premium_repository.dart';

class PremiumController extends GetxController {
  final PremiumRepository _repository;

  PremiumController({
    required PremiumRepository repository,
  }) : _repository = repository;

  final RxBool isPremium = false.obs;
  final RxBool isTrialActive = false.obs;
  final RxBool hasUsedFreeTrial = false.obs;
  final RxBool isAutoPayEnabled = false.obs;
  final RxInt chatCount = 0.obs;
  final RxInt imageGenerationCount = 0.obs;
  final RxInt rewardedImageCredits = 0.obs;
  final RxInt photoEnhancementCount = 0.obs;
  final RxInt videoEnhancementCount = 0.obs;
  final RxInt rewardedPhotoCredits = 0.obs;
  final RxInt rewardedVideoCredits = 0.obs;
  final RxInt memeCount = 0.obs;
  final RxBool isEntitlementResolved = false.obs;
  final PaymentService _paymentService = PaymentService();
  final RazorpayService _razorpayService = RazorpayService();
  final RxBool isProcessingPayment = false.obs;
  final RxBool isCancellingSubscription = false.obs;
  final RxBool cancelAtPeriodEnd = false.obs;
  final Rxn<DateTime> subscriptionAccessUntil = Rxn<DateTime>();
  final Rxn<DateTime> subscriptionTrialEndsAt = Rxn<DateTime>();
  final Rxn<DateTime> subscriptionCurrentPeriodEnd = Rxn<DateTime>();
  final RxString subscriptionStatus = 'inactive'.obs;
  final RxString subscriptionPlanId = ''.obs;
  final RxString subscriptionTier = ''.obs;
  final RxString purchaseType = ''.obs;
  final RxnInt subscriptionAmountPaise = RxnInt();
  final RxString subscriptionBillingPeriod = ''.obs;

  bool get shouldShowUpgrade => !isPremium.value;

  bool get hasProAccess {
    if (!isPremium.value) return false;
    if (subscriptionTier.value == 'pro') return true;
    final plan = subscriptionPlanId.value;
    return plan == 'pro_monthly' ||
        plan == 'pro_yearly' ||
        plan == 'monthly' ||
        plan == 'max';
  }

  bool get hasPhotoAccess {
    if (isPremium.value) return true;
    return photoEnhancementCount.value < 2 || rewardedPhotoCredits.value > 0;
  }

  User? get user => FirebaseAuth.instance.currentUser;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _premiumSubscription;
  Timer? _premiumExpiryTimer;
  int _bindingRevision = 0;
  bool _hasBoundUser = false;
  String? _boundUid;

  String? _currentPlanId;
  String? _currentSubscriptionId;
  String? _currentOrderId;
  String? _currentCheckoutKind;
  BuildContext? _purchaseContext;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
          (nextUser) => unawaited(_bindToUser(nextUser)),
        );

    _razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  Future<void> _bindToUser(User? nextUser) async {
    final uid = nextUser?.uid;
    if (_hasBoundUser && _boundUid == uid) return;
    _hasBoundUser = true;
    _boundUid = uid;
    final revision = ++_bindingRevision;
    await _premiumSubscription?.cancel();
    _premiumSubscription = null;
    if (revision != _bindingRevision) return;

    isPremium.value = false;
    isEntitlementResolved.value = false;
    isTrialActive.value = false;
    hasUsedFreeTrial.value = false;
    _premiumExpiryTimer?.cancel();
    cancelAtPeriodEnd.value = false;
    subscriptionAccessUntil.value = null;
    subscriptionTrialEndsAt.value = null;
    subscriptionCurrentPeriodEnd.value = null;
    subscriptionStatus.value = 'inactive';
    subscriptionPlanId.value = '';
    subscriptionTier.value = '';
    purchaseType.value = '';
    subscriptionAmountPaise.value = null;
    subscriptionBillingPeriod.value = '';
    isAutoPayEnabled.value = _repository.getIsAutoPayEnabled();
    chatCount.value = _repository.getChatCount();
    imageGenerationCount.value = _repository.getImageCount();
    rewardedImageCredits.value = 0;
    photoEnhancementCount.value = 0;
    videoEnhancementCount.value = 0;
    rewardedPhotoCredits.value = 0;
    rewardedVideoCredits.value = 0;
    memeCount.value = _repository.getMemeCount();

    if (uid == null) {
      isEntitlementResolved.value = true;
      return;
    }
    _premiumSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) => _applyUserSnapshot(uid, snapshot));

    try {
      final status = await _paymentService.getPremiumStatus();
      if (revision == _bindingRevision &&
          FirebaseAuth.instance.currentUser?.uid == uid) {
        _applyServerStatus(status);
      }
    } catch (error) {
      log('Unable to refresh premium status: $error');
    }
  }

  void _applyUserSnapshot(
    String uid,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (FirebaseAuth.instance.currentUser?.uid != uid) return;
    final data = snapshot.data();
    final billingValue = data?['billing'];
    final billingData = billingValue is Map
        ? Map<String, dynamic>.from(billingValue)
        : const <String, dynamic>{};
    hasUsedFreeTrial.value = billingData['trialUsedAt'] != null;
    final premiumValue = data?['premium'];
    final premiumData = premiumValue is Map
        ? Map<String, dynamic>.from(premiumValue)
        : const <String, dynamic>{};
    final status = premiumData['status']?.toString().toLowerCase();
    final subscriptionId = premiumData['subscriptionId'];
    final orderId = premiumData['orderId'];
    final hasReviewBypass = premiumData['reviewBypass'] == true;
    final hasEntitlementReference = hasReviewBypass ||
        (subscriptionId is String && subscriptionId.isNotEmpty) ||
        (orderId is String && orderId.isNotEmpty);
    final accessUntil = _readDate(
      premiumData['accessUntil'] ?? premiumData['currentPeriodEnd'],
    );
    final hasCancellationAccess = status == 'cancelled' &&
        accessUntil != null &&
        accessUntil.isAfter(DateTime.now());
    final statusAllowsAccess = status == 'authenticated' ||
        status == 'active' ||
        (status == 'prepaid_active' &&
            accessUntil != null &&
            accessUntil.isAfter(DateTime.now())) ||
        hasCancellationAccess;
    final hasAccess = premiumData['isPremium'] == true &&
        statusAllowsAccess &&
        hasEntitlementReference;
    final trialEndsAt = _readDate(premiumData['trialEndsAt']);
    final hasTrial =
        hasAccess && trialEndsAt != null && trialEndsAt.isAfter(DateTime.now());

    _setLocalPremiumState(hasAccess, hasTrial);
    isEntitlementResolved.value = true;
    subscriptionStatus.value = status ?? 'inactive';
    cancelAtPeriodEnd.value = premiumData['cancelAtPeriodEnd'] == true;
    subscriptionAccessUntil.value = accessUntil;
    subscriptionTrialEndsAt.value = trialEndsAt;
    subscriptionCurrentPeriodEnd.value =
        _readDate(premiumData['currentPeriodEnd']);
    subscriptionPlanId.value = premiumData['planId']?.toString() ?? '';
    subscriptionTier.value = premiumData['tier']?.toString() ?? '';
    purchaseType.value = premiumData['purchaseType']?.toString() ?? '';
    subscriptionAmountPaise.value =
        (premiumData['billingAmountPaise'] as num?)?.toInt();
    subscriptionBillingPeriod.value =
        premiumData['billingPeriod']?.toString() ?? '';
    _schedulePremiumExpiry();

    final serverUsageValue = data?['serverUsage'];
    final usageValue =
        serverUsageValue is Map ? serverUsageValue : data?['usage'];
    if (usageValue is Map) {
      final usage = Map<String, dynamic>.from(usageValue);
      chatCount.value =
          (usage['chatCount'] as num?)?.toInt() ?? chatCount.value;
      imageGenerationCount.value =
          (usage['imageCount'] as num?)?.toInt() ?? imageGenerationCount.value;
      rewardedImageCredits.value =
          (usage['rewardedImageCredits'] as num?)?.toInt() ?? 0;
      photoEnhancementCount.value =
          (usage['photoEnhancementCount'] as num?)?.toInt() ?? 0;
      videoEnhancementCount.value =
          (usage['videoEnhancementCount'] as num?)?.toInt() ?? 0;
      rewardedPhotoCredits.value =
          (usage['rewardedPhotoCredits'] as num?)?.toInt() ?? 0;
      rewardedVideoCredits.value =
          (usage['rewardedVideoCredits'] as num?)?.toInt() ?? 0;
      memeCount.value =
          (usage['memeCount'] as num?)?.toInt() ?? memeCount.value;
    }
  }

  void _applyServerStatus(Map<String, dynamic> status) {
    _setLocalPremiumState(
      status['isPremium'] == true,
      status['isTrialActive'] == true,
    );
    isEntitlementResolved.value = true;
    subscriptionStatus.value =
        status['status']?.toString().toLowerCase() ?? 'inactive';
    cancelAtPeriodEnd.value = status['cancelAtPeriodEnd'] == true;
    subscriptionAccessUntil.value = _readDate(status['accessUntil']);
    subscriptionTrialEndsAt.value = _readDate(status['trialEndsAt']);
    subscriptionCurrentPeriodEnd.value = _readDate(status['currentPeriodEnd']);
    if (status['hasUsedFreeTrial'] != null) {
      hasUsedFreeTrial.value = status['hasUsedFreeTrial'] == true;
    }
    if (status['planId'] != null) {
      subscriptionPlanId.value = status['planId'].toString();
    }
    if (status['tier'] != null) {
      subscriptionTier.value = status['tier'].toString();
    }
    if (status['purchaseType'] != null) {
      purchaseType.value = status['purchaseType'].toString();
    }
    subscriptionAmountPaise.value =
        (status['billingAmountPaise'] as num?)?.toInt();
    subscriptionBillingPeriod.value = status['billingPeriod']?.toString() ?? '';
    _schedulePremiumExpiry();
  }

  void _schedulePremiumExpiry() {
    _premiumExpiryTimer?.cancel();
    if (subscriptionStatus.value != 'cancelled' &&
        subscriptionStatus.value != 'prepaid_active') {
      return;
    }

    final accessUntil = subscriptionAccessUntil.value;
    if (accessUntil == null) return;
    final remaining = accessUntil.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _setLocalPremiumState(false, false);
      return;
    }

    _premiumExpiryTimer = Timer(remaining + const Duration(seconds: 1), () {
      if (subscriptionStatus.value == 'cancelled' ||
          subscriptionStatus.value == 'prepaid_active') {
        _setLocalPremiumState(false, false);
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          unawaited(_refreshPremiumStatus(currentUser.uid));
        }
      }
    });
  }

  Future<void> _refreshPremiumStatus(String uid) async {
    try {
      final status = await _paymentService.getPremiumStatus();
      if (FirebaseAuth.instance.currentUser?.uid == uid) {
        _applyServerStatus(status);
      }
    } catch (error) {
      log('Unable to refresh premium status: $error');
    }
  }

  /// Recheck the subscription after returning from the purchase page.
  Future<void> refreshPremiumStatus() async {
    final uid = user?.uid;
    if (uid == null) return;
    await _refreshPremiumStatus(uid);
  }

  DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      if (seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
      }
    }
    return null;
  }

  void _setLocalPremiumState(bool hasAccess, bool hasTrial) {
    isPremium.value = hasAccess;
    isTrialActive.value = hasTrial;
    unawaited(_repository.setIsPremium(hasAccess));
    unawaited(_repository.setIsTrialActive(hasTrial));
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _premiumSubscription?.cancel();
    _premiumExpiryTimer?.cancel();
    _razorpayService.dispose();
    super.onClose();
  }

  Future<void> incrementChatCount() async {
    if (isPremium.value) return;
    await _repository.incrementChatCount();
    chatCount.value = _repository.getChatCount();
  }

  Future<void> incrementImageCount() async {
    if (isPremium.value) return;
    // Cloud Functions already counted this request and consumed any reward.
    // Reading their values avoids overwriting them with a stale local count.
    await refreshMediaUsage();
  }

  Future<void> refreshMediaUsage() async {
    final uid = user?.uid;
    if (uid == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (user?.uid != uid) return;
      _applyUserSnapshot(uid, snapshot);
    } catch (error) {
      debugPrint('[AdMob] media usage refresh failed: $error');
    }
  }

  Future<void> incrementMemeCount() async {
    if (isPremium.value) return;
    await _repository.incrementMemeCount();
    memeCount.value = _repository.getMemeCount();
  }

  Future<void> resetLimits() async {
    await _repository.resetCounts();
    chatCount.value = 0;
    imageGenerationCount.value = 0;
    memeCount.value = 0;
  }

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    try {
      final planId = _currentPlanId;
      final paymentId = response.paymentId;
      final signature = response.signature;
      if (planId == null || paymentId == null || signature == null) {
        throw Exception('Razorpay did not return complete payment details.');
      }

      final status = _currentCheckoutKind == 'one_time'
          ? await _paymentService.verifyOneTimePayment(
              paymentId: paymentId,
              orderId: _currentOrderId ??
                  (throw Exception('Purchase order information missing.')),
              signature: signature,
              planId: planId,
            )
          : await _paymentService.verifySubscription(
              paymentId: paymentId,
              subscriptionId: _currentSubscriptionId ??
                  (throw Exception('Subscription information missing.')),
              signature: signature,
              planId: planId,
            );
      _applyServerStatus(status);
      subscriptionPlanId.value = planId;
      final activatedPlanName = _planName(planId);

      Get.snackbar(
        "Success",
        "$activatedPlanName activated",
      );
      final purchaseContext = _purchaseContext;
      _purchaseContext = null;
      if (purchaseContext != null &&
          purchaseContext.mounted &&
          Navigator.of(purchaseContext).canPop()) {
        Navigator.of(purchaseContext).pop();
      }
    } catch (e) {
      Get.snackbar(
        "Verification Failed",
        e.toString(),
      );
    } finally {
      isProcessingPayment.value = false;
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    isProcessingPayment.value = false;
    _purchaseContext = null;

    Get.snackbar(
      "Payment Failed",
      response.message ?? "Please try again",
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  String _planName(String planId) => switch (planId) {
        'lite_weekly' => 'Slipe AI Lite Weekly',
        'lite_monthly' => 'Slipe AI Lite Monthly',
        'lite_yearly' => 'Slipe AI Lite Yearly',
        'pro_monthly' => 'Slipe AI Pro Monthly',
        'pro_yearly' => 'Slipe AI Pro Yearly',
        'max' => 'Slipe AI Pro Yearly',
        _ => 'Slipe AI Pro Monthly',
      };

  bool canSendChat() {
    if (isPremium.value) return true;
    return chatCount.value < 10;
  }

  bool canGenerateImage() {
    if (isPremium.value) return true;
    return imageGenerationCount.value < 1 || rewardedImageCredits.value > 0;
  }

  Future<void> claimRewardedImageCredit() async {
    if (user == null || isPremium.value || imageGenerationCount.value < 1) {
      throw StateError(
        'Rewarded image creation is only available after the Free limit.',
      );
    }
    final callable = FirebaseFunctions.instance.httpsCallable(
      'claimRewardedImageCredit',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call<Map<String, dynamic>>();
    final credits = (result.data['rewardedImageCredits'] as num?)?.toInt();
    if (result.data['success'] != true || credits == null || credits < 1) {
      throw StateError('Unable to activate the rewarded image creation.');
    }
    rewardedImageCredits.value = credits;
  }

  bool canGenerateMeme() {
    if (isPremium.value) return true;
    return memeCount.value < 1;
  }

  /// Normal production flow: users see premium dialog / rewarded ads when limits reached.
  bool get bypassRewardedAdForTesting => false;

  bool needsEnhancementAd({required bool isVideo}) {
    if (isVideo) return false;
    return !bypassRewardedAdForTesting &&
        shouldShowFreeAds &&
        photoEnhancementCount.value >= 2 &&
        rewardedPhotoCredits.value == 0;
  }

  Future<void> claimRewardedEnhancementCredit({required bool isVideo}) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('claimRewardedEnhancementCredit')
        .call<Map<String, dynamic>>({'feature': isVideo ? 'video' : 'photo'});
    if (result.data['success'] != true) {
      throw StateError('Could not activate the enhancement reward.');
    }
    if (isVideo) {
      rewardedVideoCredits.value = 1;
    } else {
      rewardedPhotoCredits.value = 1;
    }
  }

  /// Trial and paid subscriptions have the same enhancer access. The live
  /// user subscription and expiry timer keep this state current.
  bool canExportEnhancement({required bool isVideo}) =>
      user != null && (isVideo ? hasProAccess : isPremium.value);

  /// Ads are restricted to signed-in Free accounts whose entitlement has
  /// already been resolved. This prevents ads flashing for paid/trial users.
  bool get shouldShowFreeAds =>
      user != null && isEntitlementResolved.value && !isPremium.value;

  /// Video ads are restricted to Free accounts only; Lite and Pro accounts are completely ad-free.
  bool get shouldShowVideoAds =>
      user != null && isEntitlementResolved.value && !isPremium.value;

  bool canUploadFile() {
    // Free users can upload up to 3 attachments per thread.
    return isPremium.value;
  }

  Future<void> startPremiumPurchase(
    BuildContext context,
    String planId,
  ) async {
    try {
      isProcessingPayment.value = true;
      _currentPlanId = planId;
      _currentSubscriptionId = null;
      _currentOrderId = null;
      _currentCheckoutKind = null;
      _purchaseContext = context;
      if (kDebugMode) {
        debugPrint('[SubscriptionDebug] Purchase started: planId=$planId');
      }

      final currentUser = user;
      if (currentUser == null) {
        throw Exception('Please sign in before starting a subscription.');
      }

      if (planId == 'lite_weekly') {
        final order = await _paymentService.createOneTimeOrder(planId: planId);
        _currentCheckoutKind = 'one_time';
        _currentOrderId = order['orderId'] as String;
        _razorpayService.openOneTimeCheckout(
          key: PaymentConstants.razorpayKey,
          orderId: _currentOrderId!,
          amountPaise: (order['amountPaise'] as num).toInt(),
          name: 'Slipe AI',
          description: 'Slipe AI Lite — 7 days access',
          email: currentUser.email ?? '',
        );
        return;
      }

      final subscription =
          await _paymentService.createSubscription(planId: planId);

      _currentCheckoutKind = 'subscription';
      _currentSubscriptionId = subscription['subscriptionId'] as String;
      if (kDebugMode) {
        debugPrint('[SubscriptionDebug] Opening Razorpay subscription '
            'checkout: planId=$planId, status=${subscription['status']}');
      }

      _razorpayService.openSubscriptionCheckout(
        key: PaymentConstants.razorpayKey,
        subscriptionId: _currentSubscriptionId!,
        name: "Slipe AI",
        description: "Slipe AI subscription",
        email: currentUser.email ?? "",
      );
    } catch (e, stackTrace) {
      isProcessingPayment.value = false;
      _purchaseContext = null;

      Get.snackbar(
        "Payment Error",
        e.toString(),
        snackPosition: SnackPosition.TOP,
      );

      log(
        '[SubscriptionDebug] Purchase failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> cancelSubscription({bool atCycleEnd = true}) async {
    if (isCancellingSubscription.value) return false;
    if (purchaseType.value == 'one_time') return false;

    try {
      isCancellingSubscription.value = true;
      final status = await _paymentService.cancelSubscription(
        cancelAtCycleEnd: atCycleEnd,
      );
      _applyServerStatus(status);

      final accessUntil = subscriptionAccessUntil.value;
      final suffix = accessUntil == null
          ? ''
          : ' You can keep using Premium until '
              '${accessUntil.day}/${accessUntil.month}/${accessUntil.year}.';
      Get.snackbar(
        'Subscription cancelled',
        'Future renewal has been stopped.$suffix',
        snackPosition: SnackPosition.TOP,
      );
      return true;
    } catch (error) {
      Get.snackbar(
        'Unable to cancel subscription',
        error.toString(),
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isCancellingSubscription.value = false;
    }
  }

  Future<void> activateFreeTrial({
    required bool enableAutoPay,
    required String planId,
    required BuildContext context,
  }) async {
    try {
      await _repository.setIsAutoPayEnabled(enableAutoPay);
      isAutoPayEnabled.value = enableAutoPay;
      await startPremiumPurchase(context, planId);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to activate free trial: $e",
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> restorePurchase() async {
    Get.snackbar(
      'Coming Soon',
      'Restore purchases functionality will be added here.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1A1A1A),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
