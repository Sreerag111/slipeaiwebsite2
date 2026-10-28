import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/pages/premium_screen.dart';
import 'enhancement_history_screen.dart';

class PhotoEnhanceCategory {
  const PhotoEnhanceCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.baseName,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String baseName;
  final IconData icon;
}

const photoEnhanceCategories = <PhotoEnhanceCategory>[
  PhotoEnhanceCategory(
    id: 'remove_background',
    title: 'Remove Background',
    description: 'Cut out subjects with transparent background.',
    baseName: 'remove_background',
    icon: Icons.layers_clear_rounded,
  ),
  PhotoEnhanceCategory(
    id: 'auto',
    title: 'Enhance Photo Quality',
    description: 'Boost overall clarity, details & resolution.',
    baseName: 'enhance_photos_quality',
    icon: Icons.auto_awesome_rounded,
  ),
  PhotoEnhanceCategory(
    id: 'color_balance',
    title: 'Balance Colour',
    description: 'Correct color casts, tones & saturation.',
    baseName: 'balance_colour',
    icon: Icons.palette_outlined,
  ),
  PhotoEnhanceCategory(
    id: 'colorize',
    title: 'B/W to Color',
    description: 'Transform black & white photos into vibrant color.',
    baseName: 'bw_to_color',
    icon: Icons.color_lens_outlined,
  ),
  PhotoEnhanceCategory(
    id: 'creative',
    title: 'Refine Photos',
    description: 'Enhance creative textures & details.',
    baseName: 'refine_photos',
    icon: Icons.brush_rounded,
  ),
  PhotoEnhanceCategory(
    id: 'precision',
    title: 'Upscale Photos',
    description: 'Enlarge photo without losing quality.',
    baseName: 'upscale_photos',
    icon: Icons.zoom_out_map_rounded,
  ),
  PhotoEnhanceCategory(
    id: 'denoise',
    title: 'Cleanup Photos',
    description: 'Clean up grain and low-light noise.',
    baseName: 'cleanup_photos',
    icon: Icons.grain_rounded,
  ),
  PhotoEnhanceCategory(
    id: 'restore',
    title: 'Fix Dust & Scratches',
    description: 'Repair old, scratched or damaged photos.',
    baseName: 'fix_dust_and_scratches',
    icon: Icons.auto_fix_high_rounded,
  ),
  PhotoEnhanceCategory(
    id: 'relight',
    title: 'Fix Lighting',
    description: 'Balance exposure and brighten dark photos.',
    baseName: 'fix_lighting',
    icon: Icons.wb_sunny_outlined,
  ),
  PhotoEnhanceCategory(
    id: 'sharpen',
    title: 'Sharpen Photos',
    description: 'Fix blur and bring soft details into focus.',
    baseName: 'sharp_photos',
    icon: Icons.center_focus_strong_rounded,
  ),
];

class PhotoEnhancerCategoriesScreen extends StatefulWidget {
  const PhotoEnhancerCategoriesScreen({
    super.key,
    required this.onSelectCategory,
  });

  final ValueChanged<PhotoEnhanceCategory> onSelectCategory;

  @override
  State<PhotoEnhancerCategoriesScreen> createState() =>
      _PhotoEnhancerCategoriesScreenState();
}

class _PhotoEnhancerCategoriesScreenState
    extends State<PhotoEnhancerCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = dark ? Colors.white60 : const Color(0xFF64748B);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Photo Enhancer',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Select an enhancement to transform your photo',
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        AppHaptics.tap();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EnhancementHistoryScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1F1F1F) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                dark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (dark ? Colors.white : Colors.black)
                                  .withValues(alpha: dark ? 0.05 : 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          size: 20,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
                childAspectRatio: 0.73,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = photoEnhanceCategories[index];
                  return _CategoryGridItem(
                    index: index,
                    category: category,
                    onTap: () {
                      AppHaptics.selection();
                      final premium = Get.find<PremiumController>();
                      if (!premium.hasPhotoAccess) {
                        PremiumScreen.open(
                          context,
                          initialPlanId: 'lite_monthly',
                        );
                        return;
                      }
                      widget.onSelectCategory(category);
                    },
                  );
                },
                childCount: photoEnhanceCategories.length,
              ),
            ),
          ),
        ],
      );
  }
}

class _CategoryGridItem extends StatelessWidget {
  const _CategoryGridItem({
    required this.index,
    required this.category,
    required this.onTap,
  });

  final int index;
  final PhotoEnhanceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark ? Colors.white : const Color(0xFF0F172A);
    final descColor = dark ? Colors.white60 : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CategoryVideoCard(
                index: index,
                category: category,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: titleColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            category.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w400,
              color: descColor,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryVideoCard extends StatelessWidget {
  const CategoryVideoCard({
    super.key,
    required this.index,
    required this.category,
    this.scrollEpoch,
  });

  final int index;
  final PhotoEnhanceCategory category;
  final ValueNotifier<int>? scrollEpoch;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final webpPath =
        'assets/videos/enhance_categories/${category.baseName}.webp';

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF141416) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          webpPath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return _buildShimmerPlaceholder(dark);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildShimmerPlaceholder(dark);
          },
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(bool dark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        TopLeftShimmer(isDark: dark),
        Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.07),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Icon(
                category.icon,
                color: dark ? Colors.white70 : const Color(0xFF64748B),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A smooth neutral shimmer effect running strictly from top-left to bottom-right.
class TopLeftShimmer extends StatefulWidget {
  const TopLeftShimmer({super.key, required this.isDark});

  final bool isDark;

  @override
  State<TopLeftShimmer> createState() => _TopLeftShimmerState();
}

class _TopLeftShimmerState extends State<TopLeftShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final baseColor =
        isDark ? const Color(0xFF1E222A) : const Color(0xFFEAEEF4);
    final highlightColor =
        isDark ? const Color(0xFF2E3544) : const Color(0xFFFFFFFF);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = -1.5 + (_controller.value * 3.5);
        return Container(
          decoration: BoxDecoration(
            color: baseColor,
            gradient: LinearGradient(
              begin: Alignment(pos - 1.0, pos - 1.0),
              end: Alignment(pos + 1.0, pos + 1.0),
              colors: [
                baseColor,
                highlightColor.withValues(alpha: isDark ? 0.40 : 0.70),
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
