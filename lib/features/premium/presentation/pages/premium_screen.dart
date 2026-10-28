import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plagiarism_checker/core/haptics/app_haptics.dart';
import 'package:plagiarism_checker/features/premium/presentation/controllers/premium_controller.dart';
import 'package:plagiarism_checker/theme/theme_controller.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({
    this.initialPlanId = 'lite_monthly',
    super.key,
  });

  final String initialPlanId;

  static Future<void> open(
    BuildContext context, {
    String initialPlanId = 'lite_monthly',
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumScreen(initialPlanId: initialPlanId),
      ),
    );
    if (Get.isRegistered<PremiumController>()) {
      await Get.find<PremiumController>().refreshPremiumStatus();
    }
  }

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late final PremiumController _controller;
  late String _selectedPlan;
  late String _selectedTier;

  // Features accurately matching client requirements
  static const _liteFeatures = [
    _PlanFeature('AI Image creation'),
    _PlanFeature('B&W photo to colour'),
    _PlanFeature('Upscale Photos'),
    _PlanFeature('Enhance Photos'),
    _PlanFeature('Remove Background'),
    _PlanFeature('Refine Photos'),
    _PlanFeature('Brightens Dark Photos'),
    _PlanFeature('Unblur Photos'),
    _PlanFeature('Sharpen Photos'),
    _PlanFeature('Balance Colour'),
    _PlanFeature(
      'Full Video enhancement features',
      isProOnly: true,
      isLocked: true,
    ),
  ];

  static const _proFeatures = [
    _PlanFeature('AI Image creation'),
    _PlanFeature('B&W photo to colour'),
    _PlanFeature('Upscale Photos'),
    _PlanFeature('Enhance Photos'),
    _PlanFeature('Remove Background'),
    _PlanFeature('Refine Photos'),
    _PlanFeature('Brightens Dark Photos'),
    _PlanFeature('Unblur Photos'),
    _PlanFeature('Sharpen Photos'),
    _PlanFeature('Balance Colour'),
    _PlanFeature('Full Video enhancement features'),
    _PlanFeature('Video Creations (Coming Soon)', isComingSoon: true),
  ];

  // Pricing Plans (Sorted from small to big amount)
  static const _liteWeekly = _PlanDetails(
    id: 'lite_weekly',
    shortName: 'Weekly',
    name: 'Slipe AI Lite',
    price: '₹49',
    interval: '/ week',
    description: 'One-time payment for 7 days. No automatic renewal.',
    features: _liteFeatures,
    isOneTime: true,
  );

  static const _liteMonthly = _PlanDetails(
    id: 'lite_monthly',
    shortName: 'Monthly',
    name: 'Slipe AI Lite',
    price: '₹99',
    interval: '/ month',
    description: 'Full Lite access, billed monthly.',
    features: _liteFeatures,
  );

  static const _liteYearly = _PlanDetails(
    id: 'lite_yearly',
    shortName: 'Yearly',
    name: 'Slipe AI Lite',
    price: '₹899',
    interval: '/ year',
    description: 'Full Lite access, billed yearly.',
    savePercent: '24% OFF',
    features: _liteFeatures,
  );

  static const _proMonthly = _PlanDetails(
    id: 'pro_monthly',
    shortName: 'Monthly',
    name: 'Slipe AI Pro',
    price: '₹599',
    interval: '/ month',
    description: 'Full Pro access with Video Remastering, billed monthly.',
    features: _proFeatures,
  );

  static const _proYearly = _PlanDetails(
    id: 'pro_yearly',
    shortName: 'Yearly',
    name: 'Slipe AI Pro',
    price: '₹1,799',
    interval: '/ year',
    description: 'Full Pro access with Video Remastering, billed yearly.',
    savePercent: '75% OFF',
    features: _proFeatures,
  );

  static const _litePlans = [_liteWeekly, _liteMonthly, _liteYearly];
  static const _proPlans = [_proMonthly, _proYearly];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<PremiumController>();
    final requested = widget.initialPlanId == 'monthly'
        ? _liteMonthly.id
        : widget.initialPlanId == 'max'
            ? _proYearly.id
            : widget.initialPlanId;
    final allPlans = [..._litePlans, ..._proPlans];
    _selectedPlan = allPlans.any((plan) => plan.id == requested)
        ? requested
        : _liteWeekly.id;
    _selectedTier = _selectedPlan.startsWith('pro_') ? 'pro' : 'lite';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Reactive theme binding: listens to GetX ThemeController AND device brightness
      final themeMode = Get.isRegistered<ThemeController>()
          ? ThemeController.instance.themeMode
          : ThemeMode.system;
      final isDark = themeMode == ThemeMode.dark ||
          (themeMode == ThemeMode.system &&
              Theme.of(context).brightness == Brightness.dark);
      final palette = _PremiumPalette(isDark);

      final plans = _selectedTier == 'lite' ? _litePlans : _proPlans;
      final plan = plans.firstWhere(
        (candidate) => candidate.id == _selectedPlan,
        orElse: () => plans.first,
      );

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: palette.bottomDockBg,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: palette.scaffoldBg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Top Bar with Close button on right
                _TopBar(palette: palette),

                // 2. Scrollable Middle Area (Showcase Photos + Punchy Headline + Checklist)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 4 Showcase Photos: Square, White Border, 2 on top & 2 below (Balanced 146dp)
                        _ShowcasePhotoGrid(palette: palette),
                        const SizedBox(height: 16),

                        // Client Headline (Bolder, Punchy & Impactful)
                        Text(
                          'Bring your photos back to life without losing original look!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: palette.textPrimary,
                            fontSize: 21,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subheading
                        Text(
                          'These enhancements are done in SlipeAI not fake',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: palette.subHeadingText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Segmented Tier Selector ([ Lite ] [ Pro ])
                        _TierSegmentedSelector(
                          selectedTier: _selectedTier,
                          palette: palette,
                          onSelected: (tier) {
                            AppHaptics.selection();
                            setState(() {
                              _selectedTier = tier;
                              _selectedPlan = tier == 'lite'
                                  ? _liteWeekly.id
                                  : _proMonthly.id;
                            });
                          },
                        ),
                        const SizedBox(height: 18),

                        // Clean Features Checklist
                        _FeaturesChecklist(
                          features: _selectedTier == 'lite'
                              ? _liteFeatures
                              : _proFeatures,
                          palette: palette,
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Docked Bottom Section
                // Horizontal Plan Cards with Omni-Directional 4-Way Glow & Inline Badges
                _DockedCheckoutFooter(
                  plans: plans,
                  selectedPlanId: plan.id,
                  palette: palette,
                  isLoading: _controller.isProcessingPayment.value,
                  onSelectPlan: (id) {
                    AppHaptics.selection();
                    setState(() => _selectedPlan = id);
                  },
                  onContinue: () => _controller.startPremiumPurchase(
                    context,
                    plan.id,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// =============================================================================
// TOP BAR (CLEAN CLOSE BUTTON ONLY)
// =============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({required this.palette});

  final _PremiumPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: palette.closeButtonBg,
            fixedSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(
            Icons.close_rounded,
            color: palette.closeIconColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 4 SHOWCASE PHOTOS: SQUARE, WHITE BORDER, 2 ON TOP & 2 BELOW
// =============================================================================

class _ShowcasePhotoGrid extends StatelessWidget {
  const _ShowcasePhotoGrid({required this.palette});

  final _PremiumPalette palette;

  static const _items = [
    (
      asset: 'assets/images/premium_showcase_1.jpg',
      angle: -2.0,
      label: 'Restore Photo',
    ),
    (
      asset: 'assets/images/premium_showcase_2.jpg',
      angle: 2.0,
      label: 'Remove BG',
    ),
    (
      asset: 'assets/images/premium_showcase_3.jpg',
      angle: 1.8,
      label: 'Enhance HD',
    ),
    (
      asset: 'assets/images/premium_showcase_4.jpg',
      angle: -1.8,
      label: 'B&W to Color',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          // Top Row: 2 Photos
          Row(
            children: [
              Expanded(child: _buildPhotoCard(_items[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildPhotoCard(_items[1])),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom Row: 2 Photos below that
          Row(
            children: [
              Expanded(child: _buildPhotoCard(_items[2])),
              const SizedBox(width: 12),
              Expanded(child: _buildPhotoCard(_items[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(
    ({String asset, double angle, String label}) item,
  ) {
    final radians = item.angle * (math.pi / 180.0);
    return Transform.rotate(
      angle: radians,
      child: Container(
        height: 146,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
          boxShadow: palette.standardContainerShadow,
        ),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                item.asset,
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SEGMENTED TIER SWITCHER ([ Lite ] [ Pro ]) WITH PROMINENT SELECTED GLOW
// =============================================================================

class _TierSegmentedSelector extends StatelessWidget {
  const _TierSegmentedSelector({
    required this.selectedTier,
    required this.palette,
    required this.onSelected,
  });

  final String selectedTier;
  final _PremiumPalette palette;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.segmentBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.segmentBorder),
        boxShadow: palette.standardContainerShadow,
      ),
      child: Row(
        children: [
          _TierSegmentPill(
            title: 'Lite',
            subtitle: 'AI Images & Photos',
            selected: selectedTier == 'lite',
            palette: palette,
            onTap: () => onSelected('lite'),
          ),
          const SizedBox(width: 4),
          _TierSegmentPill(
            title: 'Pro',
            subtitle: 'Photos + Video',
            selected: selectedTier == 'pro',
            palette: palette,
            onTap: () => onSelected('pro'),
          ),
        ],
      ),
    );
  }
}

class _TierSegmentPill extends StatelessWidget {
  const _TierSegmentPill({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final _PremiumPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? palette.segmentActive : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? palette.segmentActiveShadow : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: selected
                      ? palette.segmentActiveText
                      : palette.segmentInactiveText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: selected
                      ? palette.segmentActiveSubtitle
                      : palette.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CLEAN FEATURES CHECKLIST - MONOCHROME B&W
// =============================================================================

class _FeaturesChecklist extends StatelessWidget {
  const _FeaturesChecklist({
    required this.features,
    required this.palette,
  });

  final List<_PlanFeature> features;
  final _PremiumPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(
              children: [
                // Rounded square checkbox tile
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: feature.isLocked
                        ? palette.featureLockBg
                        : palette.featureIconBg,
                    borderRadius: BorderRadius.circular(7.5),
                    border: Border.all(
                      color: feature.isLocked
                          ? palette.featureLockBorder
                          : palette.featureIconBorder,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      feature.isLocked
                          ? Icons.lock_outline_rounded
                          : Icons.check_rounded,
                      size: feature.isLocked ? 14 : 15,
                      color: feature.isLocked
                          ? palette.featureLockColor
                          : palette.featureIconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature.label,
                    style: GoogleFonts.plusJakartaSans(
                      color: feature.isLocked
                          ? palette.textMuted
                          : palette.textPrimary,
                      fontSize: 13.5,
                      fontWeight:
                          feature.isLocked ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                ),
                if (feature.isLocked && feature.isProOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.badgeBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.badgeBorder),
                    ),
                    child: Text(
                      'PRO',
                      style: GoogleFonts.plusJakartaSans(
                        color: palette.badgeText,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                else if (feature.isComingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.badgeBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.badgeBorder),
                    ),
                    child: Text(
                      'SOON',
                      style: GoogleFonts.plusJakartaSans(
                        color: palette.badgeText,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// DOCKED BOTTOM SECTION - OMNI-DIRECTIONAL 4-WAY GLOWING PLAN CARDS
// =============================================================================

class _DockedCheckoutFooter extends StatelessWidget {
  const _DockedCheckoutFooter({
    required this.plans,
    required this.selectedPlanId,
    required this.palette,
    required this.isLoading,
    required this.onSelectPlan,
    required this.onContinue,
  });

  final List<_PlanDetails> plans;
  final String selectedPlanId;
  final _PremiumPalette palette;
  final bool isLoading;
  final ValueChanged<String> onSelectPlan;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        math.max(10.0, bottomInset),
      ),
      decoration: BoxDecoration(
        color: palette.bottomDockBg,
        border: Border(
          top: BorderSide(color: palette.bottomDockBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor
                .withValues(alpha: palette.isDark ? 0.30 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horizontal Plan Cards wrapped with padding so 4-way omni shadow shines on all sides
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < plans.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _HorizontalPlanCard(
                        plan: plans[i],
                        selected: plans[i].id == selectedPlanId,
                        palette: palette,
                        onTap: () => onSelectPlan(plans[i].id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // High-Contrast Monochrome Continue Button
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: isLoading ? null : onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: palette.ctaButtonBg,
                foregroundColor: palette.ctaButtonText,
                shape: const StadiumBorder(),
                elevation: 3,
                shadowColor: palette.shadowColor
                    .withValues(alpha: palette.isDark ? 0.35 : 0.25),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: palette.ctaButtonText,
                      ),
                    )
                  : Text(
                      'Continue',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),

          // Cancel anytime
          Text(
            'Cancel anytime.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: palette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HORIZONTAL PLAN CARD (4-WAY OMNI SHADOWS IN ALL DIRECTIONS & INLINE BADGE)
// =============================================================================

class _HorizontalPlanCard extends StatelessWidget {
  const _HorizontalPlanCard({
    required this.plan,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final _PlanDetails plan;
  final bool selected;
  final _PremiumPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discount = plan.savePercent;

    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.shortName}, ${plan.price}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? palette.cardBgSelected : palette.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? palette.cardBorderSelected : palette.cardBorder,
              width: selected ? 2.0 : 1.0,
            ),
            boxShadow: selected
                ? palette.selectedContainerShadow
                : palette.standardContainerShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row: Plan Name + Inline Discount Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      plan.shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: selected
                            ? palette.textPrimary
                            : palette.textSecondary,
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (discount != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.discountBadgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        discount,
                        style: GoogleFonts.plusJakartaSans(
                          color: palette.discountBadgeText,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),

              // Total Price (₹49, ₹99, ₹899 / ₹599, ₹1,799)
              Text(
                plan.price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: palette.textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),

              // Frequency subtext (7 days, per month, per year)
              Text(
                plan.isOneTime
                    ? '7 days'
                    : plan.interval.replaceAll('/', 'per '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: palette.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

class _PlanDetails {
  const _PlanDetails({
    required this.id,
    required this.shortName,
    required this.name,
    required this.price,
    required this.interval,
    required this.description,
    required this.features,
    this.savePercent,
    this.isOneTime = false,
  });

  final String id;
  final String shortName;
  final String name;
  final String price;
  final String interval;
  final String description;
  final List<_PlanFeature> features;
  final String? savePercent;
  final bool isOneTime;
}

class _PlanFeature {
  const _PlanFeature(
    this.label, {
    this.isLocked = false,
    this.isProOnly = false,
    this.isComingSoon = false,
  });

  final String label;
  final bool isLocked;
  final bool isProOnly;
  final bool isComingSoon;
}

// =============================================================================
// PURE BLACK & WHITE COLOR PALETTE WITH OMNI-DIRECTIONAL 4-WAY HALO SHADOWS
// =============================================================================

class _PremiumPalette {
  _PremiumPalette(this.isDark);

  final bool isDark;

  // Base Shadow Color: White for dark mode, Black for light mode
  Color get shadowColor => isDark ? Colors.white : Colors.black;

  // Omni-directional 4-way halo shadows (radiates evenly on top, bottom, left, right)
  List<BoxShadow> get standardContainerShadow => [
        BoxShadow(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.14 : 0.08),
          blurRadius: 8,
          spreadRadius: 0.8,
          offset: Offset.zero,
        ),
      ];

  List<BoxShadow> get selectedContainerShadow => [
        BoxShadow(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.32 : 0.18),
          blurRadius: 14,
          spreadRadius: 1.5,
          offset: Offset.zero,
        ),
      ];

  List<BoxShadow> get segmentActiveShadow => [
        BoxShadow(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.35 : 0.22),
          blurRadius: 10,
          spreadRadius: 1.2,
          offset: Offset.zero,
        ),
      ];

  // Scaffold & Background
  Color get scaffoldBg =>
      isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  // Bottom docked sheet
  Color get bottomDockBg =>
      isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF);

  Color get bottomDockBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.08);

  // Plan Cards
  Color get cardBg =>
      isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);

  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.10);

  Color get cardBgSelected =>
      isDark ? const Color(0xFF202020) : const Color(0xFFF7F7F8);

  Color get cardBorderSelected => isDark ? Colors.white : Colors.black;

  // Segmented switcher
  Color get segmentBg =>
      isDark ? const Color(0xFF141414) : const Color(0xFFF1F1F1);

  Color get segmentBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.08);

  Color get segmentActive => isDark ? Colors.white : Colors.black;

  Color get segmentActiveText => isDark ? Colors.black : Colors.white;

  Color get segmentActiveSubtitle => isDark ? Colors.black87 : Colors.white70;

  Color get segmentInactiveText => isDark
      ? Colors.white.withValues(alpha: 0.60)
      : Colors.black.withValues(alpha: 0.60);

  // Feature checklist
  Color get featureIconBg =>
      isDark ? const Color(0xFF181818) : const Color(0xFFF4F4F5);

  Color get featureIconBorder => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.10);

  Color get featureIconColor => isDark ? Colors.white : Colors.black;

  Color get featureLockBg =>
      isDark ? const Color(0xFF101010) : const Color(0xFFFAFAFA);

  Color get featureLockBorder => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.05);

  Color get featureLockColor => isDark ? Colors.white38 : Colors.black38;

  // Typography
  Color get textPrimary => isDark ? Colors.white : Colors.black;

  Color get textSecondary => isDark
      ? Colors.white.withValues(alpha: 0.55)
      : Colors.black.withValues(alpha: 0.55);

  Color get textMuted => isDark ? Colors.white38 : Colors.black38;

  // Subheading (light white in dark mode, soft muted in light mode)
  Color get subHeadingText => isDark
      ? Colors.white.withValues(alpha: 0.70)
      : Colors.black.withValues(alpha: 0.60);

  // Badges
  Color get badgeBg =>
      isDark ? const Color(0xFF222222) : const Color(0xFFE4E4E7);

  Color get badgeBorder => isDark
      ? Colors.white.withValues(alpha: 0.20)
      : Colors.black.withValues(alpha: 0.12);

  Color get badgeText => isDark ? Colors.white : Colors.black;

  Color get discountBadgeBg => isDark ? Colors.white : Colors.black;

  Color get discountBadgeText => isDark ? Colors.black : Colors.white;

  // CTA Button
  Color get ctaButtonBg => isDark ? Colors.white : Colors.black;

  Color get ctaButtonText => isDark ? Colors.black : Colors.white;

  // Close Button
  Color get closeButtonBg =>
      isDark ? const Color(0xFF1C1C1C) : const Color(0xFFEBEBEB);

  Color get closeIconColor => isDark ? Colors.white : Colors.black;
}
