import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/premium/presentation/controllers/premium_controller.dart';

enum RewardedAdResult { earned, dismissed, unavailable }

/// Owns AdMob consent, SDK initialization, preloading, and ad delivery.
class AdMobService {
  AdMobService._();

  static final AdMobService instance = AdMobService._();

  static final String _bannerId = kReleaseMode
      ? 'ca-app-pub-4547262487190663/8402673502'
      : (Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/2014213617');
  static const String _rewardedId = kReleaseMode
      ? 'ca-app-pub-4547262487190663/8946347411'
      : 'ca-app-pub-3940256099942544/5224354917';

  /// Dedicated Loading/Result screen MREC banner ad unit ID.
  static const String _loadingPageAdUnitId = kReleaseMode
      ? 'ca-app-pub-4547262487190663/2918809315'
      : 'ca-app-pub-3940256099942544/6300978111';

  /// Dedicated Full-screen Interstitial ad unit ID.
  static const String _interstitialId = kReleaseMode
      ? 'ca-app-pub-4547262487190663/4231890983'
      : 'ca-app-pub-3940256099942544/1033173712';

  /// Dedicated Native Ad unit ID (Result / Loading screen).
  static String _nativeAdUnitId = kReleaseMode
      ? 'ca-app-pub-4547262487190663/7034126218'
      : (Platform.isIOS
          ? 'ca-app-pub-3940256099942544/3986624511'
          : 'ca-app-pub-3940256099942544/2247696110');

  String get bannerAdUnitId => _bannerId;
  String get rewardedAdUnitId => _rewardedId;
  String get loadingPageAdUnitId => _loadingPageAdUnitId;
  String get interstitialAdUnitId => _interstitialId;
  String get nativeAdUnitId => _nativeAdUnitId;

  static void updateNativeAdUnitId(String id) {
    _nativeAdUnitId = id;
  }

  bool get isInterstitialReady {
    if (Get.isRegistered<PremiumController>()) {
      final premium = Get.find<PremiumController>();
      if (premium.isPremium.value || !premium.shouldShowFreeAds) {
        debugPrint(
            '[AdMob] isInterstitialReady: true (premium/ad-free entitlement)');
        return true;
      }
    }
    final ready = _preloadedInterstitialAd != null;
    debugPrint(
        '[AdMob] isInterstitialReady: $ready (preloaded=${_preloadedInterstitialAd != null})');
    return ready;
  }

  Future<void>? _initialization;
  bool _canRequestAds = false;

  bool get canRequestAds => Platform.isAndroid && _canRequestAds;

  // Rewarded Ad Preloading State
  RewardedAd? _preloadedRewardedAd;
  bool _isPreloadingRewarded = false;

  // Interstitial Ad Preloading State (Ready for Part 2)
  InterstitialAd? _preloadedInterstitialAd;
  bool _isPreloadingInterstitial = false;

  Future<void> initialize() {
    if (_canRequestAds) {
      debugPrint('[AdMob] initialize: already ready');
      return Future<void>.value();
    }
    final currentAttempt = _initialization;
    if (currentAttempt != null) {
      debugPrint('[AdMob] initialize: waiting for current attempt');
      return currentAttempt;
    }

    debugPrint(
        '[AdMob] initialize: starting new attempt (mode=${kReleaseMode ? 'RELEASE' : 'DEBUG'})');
    final attempt = _initialize().whenComplete(() {
      // Permit a later button tap to retry SDK/consent initialization if this
      // attempt could not reach an ad-requestable state.
      if (!_canRequestAds) _initialization = null;
    });
    _initialization = attempt;
    return attempt;
  }

  Future<void> _initialize() async {
    if (!Platform.isAndroid) {
      debugPrint('[AdMob] initialize: unsupported platform');
      return;
    }
    try {
      debugPrint('[AdMob] consent: requesting information update');
      final consentUpdate = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          debugPrint('[AdMob] consent: information update succeeded');
          if (!consentUpdate.isCompleted) consentUpdate.complete();
        },
        (error) {
          debugPrint(
            '[AdMob] consent update failed: '
            'code=${error.errorCode} message=${error.message}',
          );
          if (!consentUpdate.isCompleted) consentUpdate.complete();
        },
      );
      await consentUpdate.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('[AdMob] consent: information update timed out');
        },
      );

      final consentStatus =
          await ConsentInformation.instance.getConsentStatus();
      debugPrint('[AdMob] consent: status=$consentStatus');
      debugPrint('[AdMob] consent: checking required form');
      final consentForm = Completer<void>();
      ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          debugPrint(
            '[AdMob] consent form failed: '
            'code=${error.errorCode} message=${error.message}',
          );
        } else {
          debugPrint('[AdMob] consent: no form required or form completed');
        }
        if (!consentForm.isCompleted) consentForm.complete();
      });
      await consentForm.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('[AdMob] consent: form check timed out');
        },
      );

      bool canRequest = false;
      try {
        canRequest = await ConsentInformation.instance.canRequestAds();
      } catch (e) {
        debugPrint('[AdMob] consent: canRequestAds error: $e');
      }

      // Ensure ad requests are allowed globally. If UMP is unconfigured (e.g. no GDPR
      // form created yet in AdMob console), we still initialize the SDK so that non-EEA
      // users, fallback ad serving, and internal test devices receive ads.
      _canRequestAds = true;
      debugPrint(
        '[AdMob] consent: canRequestAds=$canRequest, proceeding with SDK init\n'
        '  mode        : ${kReleaseMode ? 'RELEASE (live ad units)' : 'DEBUG (test ad units)'}\n'
        '  banner      : $_bannerId\n'
        '  rewarded    : $_rewardedId\n'
        '  interstitial: $_interstitialId\n'
        '  native      : $_nativeAdUnitId\n'
        '  mrec/loading: $_loadingPageAdUnitId',
      );

      try {
        final requestConfiguration = RequestConfiguration(
          testDeviceIds: [
            // Developer & testing devices for instant test ads on internal builds
            '90180E3DFAF7BACBE75EAE7BBD53715E',
          ],
        );
        await MobileAds.instance
            .updateRequestConfiguration(requestConfiguration);
        debugPrint('[AdMob] requestConfiguration: test device IDs registered');
      } catch (e) {
        debugPrint('[AdMob] requestConfiguration error: $e');
      }

      final initialization = await MobileAds.instance.initialize();
      debugPrint(
        '[AdMob] SDK initialized successfully:\n'
        '  adapters: ${initialization.adapterStatuses}',
      );
      // Delay background preloading by 4 seconds so that app launch,
      // splash screen, and the initial page transition remain silky smooth.
      Future.delayed(const Duration(seconds: 4), () {
        unawaited(preloadRewardedAd());
      });
    } catch (error) {
      _canRequestAds = true;
      try {
        await MobileAds.instance.initialize();
        Future.delayed(const Duration(seconds: 4), () {
          unawaited(preloadRewardedAd());
        });
      } catch (_) {}
      debugPrint('[AdMob] initialization exception: $error');
    }
  }

  // ===========================================================================
  // REWARDED AD MANAGEMENT (With Background Preloading for 0ms delay)
  // ===========================================================================

  /// Preloads a rewarded ad in the background.
  Future<void> preloadRewardedAd() async {
    if (!canRequestAds) {
      debugPrint('[AdMob] rewarded preload: skipped — canRequestAds=false');
      return;
    }
    if (_preloadedRewardedAd != null) {
      debugPrint('[AdMob] rewarded preload: skipped — already cached');
      return;
    }
    if (_isPreloadingRewarded) {
      debugPrint('[AdMob] rewarded preload: skipped — already in progress');
      return;
    }
    _isPreloadingRewarded = true;
    debugPrint(
        '[AdMob] rewarded: preloading in background... unit=$rewardedAdUnitId');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint(
              '[AdMob] rewarded: preloaded and cached successfully (unit=$rewardedAdUnitId)');
          _preloadedRewardedAd = ad;
          _isPreloadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[AdMob] rewarded preload failed:\n'
            '  unit   : $rewardedAdUnitId\n'
            '  code   : ${error.code}\n'
            '  domain : ${error.domain}\n'
            '  message: ${error.message}',
          );
          _preloadedRewardedAd = null;
          _isPreloadingRewarded = false;
        },
      ),
    );
  }

  Future<RewardedAdResult> showRewardedAd({
    Duration loadTimeout = const Duration(seconds: 4),
  }) async {
    debugPrint('[AdMob] rewarded: button request received');
    await initialize();
    if (!canRequestAds) {
      debugPrint('[AdMob] rewarded: unavailable because canRequestAds=false');
      return RewardedAdResult.unavailable;
    }

    // 1. Check if we have a preloaded ad ready for 0ms instant display
    if (_preloadedRewardedAd != null) {
      debugPrint('[AdMob] rewarded: showing instantly from preloaded cache!');
      final cachedAd = _preloadedRewardedAd!;
      _preloadedRewardedAd = null; // consume it
      return _presentRewardedAd(cachedAd);
    }

    // 2. If an ad is currently preloading in background, wait for it
    if (_isPreloadingRewarded) {
      debugPrint(
          '[AdMob] rewarded: preload in progress, waiting for completion...');
      final start = DateTime.now();
      while (_isPreloadingRewarded &&
          DateTime.now().difference(start) < loadTimeout) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_preloadedRewardedAd != null) {
        debugPrint(
            '[AdMob] rewarded: preloaded ad ready after wait, showing now');
        final cachedAd = _preloadedRewardedAd!;
        _preloadedRewardedAd = null;
        return _presentRewardedAd(cachedAd);
      }
    }

    // 3. If not preloaded, fetch on demand as fallback
    final result = Completer<RewardedAdResult>();
    try {
      debugPrint(
          '[AdMob] rewarded: no preloaded ad available, loading on-demand...');
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdFailedToLoad: (error) {
            debugPrint(
              '[AdMob] rewarded on-demand load failed:\n'
              '  unit        : $rewardedAdUnitId\n'
              '  code        : ${error.code}\n'
              '  domain      : ${error.domain}\n'
              '  message     : ${error.message}\n'
              '  responseInfo: ${error.responseInfo}',
            );
            if (!result.isCompleted) {
              result.complete(RewardedAdResult.unavailable);
            }
          },
          onAdLoaded: (ad) {
            debugPrint(
                '[AdMob] rewarded: loaded on-demand (unit=$rewardedAdUnitId), now showing');
            _presentRewardedAd(ad).then((res) {
              if (!result.isCompleted) result.complete(res);
            });
          },
        ),
      );
    } catch (error) {
      debugPrint('[AdMob] rewarded request exception: $error');
      if (!result.isCompleted) {
        result.complete(RewardedAdResult.unavailable);
      }
    }
    return result.future;
  }

  Future<RewardedAdResult> _presentRewardedAd(RewardedAd ad) {
    final result = Completer<RewardedAdResult>();
    var rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] rewarded: dismissed rewardEarned=$rewardEarned');
        ad.dispose();
        // Automatically preload the NEXT ad in background for subsequent taps
        unawaited(preloadRewardedAd());
        if (!result.isCompleted) {
          result.complete(rewardEarned
              ? RewardedAdResult.earned
              : RewardedAdResult.dismissed);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] rewarded show failed: $error');
        ad.dispose();
        unawaited(preloadRewardedAd());
        if (!result.isCompleted) {
          result.complete(RewardedAdResult.unavailable);
        }
      },
    );

    debugPrint('[AdMob] rewarded: presenting to user');
    ad.show(onUserEarnedReward: (_, reward) {
      rewardEarned = true;
      debugPrint(
        '[AdMob] rewarded: reward earned '
        'type=${reward.type} amount=${reward.amount}',
      );
    });

    return result.future;
  }

  // ===========================================================================
  // INTERSTITIAL AD MANAGEMENT (Placeholder for Part 2)
  // ===========================================================================

  /// Preloads an interstitial ad in background (Part 2 ready).
  Future<void> preloadInterstitialAd() async {
    if (Get.isRegistered<PremiumController>()) {
      final premium = Get.find<PremiumController>();
      if (premium.isPremium.value || !premium.shouldShowFreeAds) {
        debugPrint(
            '[AdMob] interstitial preload: skipped — premium/ad-free entitlement');
        return;
      }
    }
    if (!canRequestAds) {
      debugPrint('[AdMob] interstitial preload: skipped — canRequestAds=false');
      return;
    }
    if (_preloadedInterstitialAd != null) {
      debugPrint('[AdMob] interstitial preload: skipped — already cached');
      return;
    }
    if (_isPreloadingInterstitial) {
      debugPrint('[AdMob] interstitial preload: skipped — already in progress');
      return;
    }
    _isPreloadingInterstitial = true;
    debugPrint(
        '[AdMob] interstitial: preloading in background... unit=$interstitialAdUnitId');

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint(
              '[AdMob] interstitial: preloaded and cached (unit=$interstitialAdUnitId)');
          _preloadedInterstitialAd = ad;
          _isPreloadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[AdMob] interstitial preload failed:\n'
            '  unit   : $interstitialAdUnitId\n'
            '  code   : ${error.code}\n'
            '  domain : ${error.domain}\n'
            '  message: ${error.message}',
          );
          _preloadedInterstitialAd = null;
          _isPreloadingInterstitial = false;
        },
      ),
    );
  }

  /// Shows interstitial ad, waiting for completion/dismissal before resolving.
  Future<bool> showInterstitialAd({
    Duration loadTimeout = const Duration(seconds: 4),
  }) async {
    if (Get.isRegistered<PremiumController>()) {
      final premium = Get.find<PremiumController>();
      if (premium.isPremium.value || !premium.shouldShowFreeAds) {
        debugPrint(
            '[AdMob] interstitial: skipped because user has ad-free entitlement');
        return true;
      }
    }
    await initialize();
    if (!canRequestAds) {
      debugPrint('[AdMob] interstitial: cannot request ads');
      return false;
    }

    // 1. If ad is already preloaded in memory, show immediately (0ms delay)
    if (_preloadedInterstitialAd != null) {
      debugPrint('[AdMob] interstitial: showing preloaded ad immediately');
      final ad = _preloadedInterstitialAd!;
      _preloadedInterstitialAd = null;
      return _presentInterstitialAd(ad);
    }

    // 2. If an ad is currently preloading in background, wait for it
    if (_isPreloadingInterstitial) {
      debugPrint(
        '[AdMob] interstitial: preloading in progress, waiting up to ${loadTimeout.inSeconds}s',
      );
      final start = DateTime.now();
      while (_isPreloadingInterstitial &&
          DateTime.now().difference(start) < loadTimeout) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
      if (_preloadedInterstitialAd != null) {
        debugPrint('[AdMob] interstitial: preloaded ad ready, showing now');
        final ad = _preloadedInterstitialAd!;
        _preloadedInterstitialAd = null;
        return _presentInterstitialAd(ad);
      }
    }

    // 3. Otherwise, perform on-demand load with loadTimeout
    debugPrint('[AdMob] interstitial: on-demand load starting...');
    final loadCompleter = Completer<InterstitialAd?>();
    _isPreloadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isPreloadingInterstitial = false;
          if (!loadCompleter.isCompleted) loadCompleter.complete(ad);
        },
        onAdFailedToLoad: (error) {
          _isPreloadingInterstitial = false;
          debugPrint(
            '[AdMob] interstitial on-demand load failed:\n'
            '  unit   : $interstitialAdUnitId\n'
            '  code   : ${error.code}\n'
            '  domain : ${error.domain}\n'
            '  message: ${error.message}',
          );
          if (!loadCompleter.isCompleted) loadCompleter.complete(null);
        },
      ),
    );

    InterstitialAd? loadedAd;
    try {
      loadedAd = await loadCompleter.future.timeout(loadTimeout);
    } catch (_) {
      debugPrint('[AdMob] interstitial on-demand load timed out');
      _isPreloadingInterstitial = false;
      return false;
    }

    if (loadedAd != null) {
      return _presentInterstitialAd(loadedAd);
    }
    return false;
  }

  Future<bool> _presentInterstitialAd(InterstitialAd ad) {
    _preloadedInterstitialAd = null;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        debugPrint(
            '[AdMob] interstitial: full-screen content shown (unit=$interstitialAdUnitId)');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] interstitial: dismissed by user');
        ad.dispose();
        unawaited(preloadInterstitialAd());
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
          '[AdMob] interstitial show failed:\n'
          '  unit   : $interstitialAdUnitId\n'
          '  code   : ${error.code}\n'
          '  domain : ${error.domain}\n'
          '  message: ${error.message}',
        );
        ad.dispose();
        unawaited(preloadInterstitialAd());
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    debugPrint(
        '[AdMob] interstitial: presenting full screen now (unit=$interstitialAdUnitId)');
    ad.show();
    return completer.future;
  }
}
