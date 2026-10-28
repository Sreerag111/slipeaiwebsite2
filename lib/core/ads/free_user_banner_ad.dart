import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/premium/presentation/controllers/premium_controller.dart';
import 'admob_service.dart';

/// Renders an Anchored Adaptive Collapsible Banner Ad for non-premium users.
///
/// Features:
/// - Automatically scales width to match user device screen via Anchored Adaptive sizing.
/// - Supports AdMob Collapsible banners ('bottom' or 'top') for 2x-3x higher eCPMs.
/// - Automatically respects Premium entitlement (hidden for paid users).
class FreeUserBannerAd extends StatefulWidget {
  const FreeUserBannerAd({
    super.key,
    this.isCollapsible = true,
    this.collapsibleDirection = 'bottom',
    this.topPadding = 0,
    this.bottomPadding = 8,
  });

  /// Whether to request an expandable collapsible banner.
  final bool isCollapsible;

  /// Direction to anchor the collapsible banner ('bottom' or 'top').
  final String collapsibleDirection;

  /// Top padding above the banner.
  final double topPadding;

  /// Bottom padding below the banner.
  final double bottomPadding;

  @override
  State<FreeUserBannerAd> createState() => _FreeUserBannerAdState();
}

class _FreeUserBannerAdState extends State<FreeUserBannerAd>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _ad;
  bool _isLoading = false;
  bool _disposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && mounted) _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad == null && !_isLoading && !_disposed) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_isLoading) {
      debugPrint('[AdMob] banner: _load skipped — already loading');
      return;
    }
    if (_ad != null) {
      debugPrint('[AdMob] banner: _load skipped — already loaded');
      return;
    }
    if (_disposed) {
      debugPrint('[AdMob] banner: _load skipped — widget disposed');
      return;
    }
    _isLoading = true;

    debugPrint('[AdMob] banner: load requested (unit=${AdMobService.instance.bannerAdUnitId})');
    await AdMobService.instance.initialize();
    if (!mounted || _disposed) {
      _isLoading = false;
      debugPrint('[AdMob] banner: aborted after init — unmounted or disposed');
      return;
    }
    if (!AdMobService.instance.canRequestAds) {
      _isLoading = false;
      debugPrint('[AdMob] banner: skipped — canRequestAds=false (Platform.isAndroid=${AdMobService.instance.canRequestAds})');
      return;
    }
    if (Get.isRegistered<PremiumController>()) {
      final premium = Get.find<PremiumController>();
      if (premium.isPremium.value || !premium.shouldShowFreeAds) {
        _isLoading = false;
        debugPrint(
          '[AdMob] banner: skipped — premium=${premium.isPremium.value} '
          'shouldShowFreeAds=${premium.shouldShowFreeAds}',
        );
        return;
      }
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    AdSize? adaptiveSize;
    if (width > 0) {
      try {
        adaptiveSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
        debugPrint('[AdMob] banner: adaptive size resolved to ${adaptiveSize?.width}x${adaptiveSize?.height} (screenWidth=$width)');
      } catch (e) {
        debugPrint('[AdMob] banner: adaptive size resolution failed: $e');
      }
    } else {
      debugPrint('[AdMob] banner: screen width=$width, skipping adaptive size');
    }
    final adSize = adaptiveSize ?? AdSize.banner;
    debugPrint('[AdMob] banner: final adSize=${adSize.width}x${adSize.height}');

    if (!mounted || _disposed) {
      _isLoading = false;
      debugPrint('[AdMob] banner: aborted after adaptive size — unmounted or disposed');
      return;
    }

    // Attempt 1: If collapsible is requested and adaptiveSize is available, try collapsible banner.
    if (widget.isCollapsible && adaptiveSize != null) {
      final collapsibleRequest = AdRequest(
        extras: {'collapsible': widget.collapsibleDirection},
      );
      debugPrint(
        '[AdMob] banner: loading collapsible unit=${AdMobService.instance.bannerAdUnitId} '
        'size=${adSize.width}x${adSize.height}',
      );
      _createAndLoadAd(
        adSize: adSize,
        request: collapsibleRequest,
        onFailed: () {
          // Fallback Attempt 2: Standard adaptive banner without collapsible extra
          debugPrint('[AdMob] banner: collapsible request failed, falling back to standard adaptive');
          _loadStandardFallback(adSize);
        },
      );
    } else {
      _loadStandardFallback(adSize);
    }
  }

  void _loadStandardFallback(AdSize preferredSize) {
    if (_disposed || !mounted) {
      _isLoading = false;
      return;
    }
    _createAndLoadAd(
      adSize: preferredSize,
      request: const AdRequest(),
      onFailed: () {
        // Fallback Attempt 3: Standard 320x50 fixed banner
        if (preferredSize != AdSize.banner && mounted && !_disposed) {
          debugPrint('[AdMob] banner: adaptive failed, falling back to standard 320x50');
          _createAndLoadAd(
            adSize: AdSize.banner,
            request: const AdRequest(),
            onFailed: () {
              _isLoading = false;
            },
          );
        } else {
          _isLoading = false;
        }
      },
    );
  }

  void _createAndLoadAd({
    required AdSize adSize,
    required AdRequest request,
    required VoidCallback onFailed,
  }) {
    if (_disposed || !mounted) {
      _isLoading = false;
      return;
    }

    final ad = BannerAd(
      adUnitId: AdMobService.instance.bannerAdUnitId,
      size: adSize,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          final bannerAd = loadedAd as BannerAd;
          debugPrint(
            '[AdMob] banner: loaded successfully\n'
            '  unit        : ${AdMobService.instance.bannerAdUnitId}\n'
            '  size        : ${bannerAd.size.width}x${bannerAd.size.height}\n'
            '  responseInfo: ${bannerAd.responseInfo}',
          );
          if (!mounted || _disposed) {
            debugPrint('[AdMob] banner: loaded but widget already unmounted/disposed — disposing ad');
            bannerAd.dispose();
            return;
          }
          setState(() {
            _ad = bannerAd;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          debugPrint(
            '[AdMob] banner load failed:\n'
            '  unit   : ${AdMobService.instance.bannerAdUnitId}\n'
            '  code   : ${error.code}\n'
            '  domain : ${error.domain}\n'
            '  message: ${error.message}',
          );
          onFailed();
        },
      ),
    );

    ad.load();
  }

  @override
  void dispose() {
    _disposed = true;
    debugPrint('[AdMob] banner: widget disposed (hadAd=${_ad != null})');
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    if (ad == null) {
      // Silent: loading in progress or not yet triggered — don't log here (called every frame)
      return const SizedBox.shrink();
    }

    if (Get.isRegistered<PremiumController>()) {
      final premium = Get.find<PremiumController>();
      if (premium.isPremium.value || !premium.shouldShowFreeAds) {
        debugPrint('[AdMob] banner build: hiding loaded ad — user is premium or ad-free');
        return const SizedBox.shrink();
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        top: widget.topPadding,
        bottom: widget.bottomPadding,
      ),
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
