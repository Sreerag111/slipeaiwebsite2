import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/pages/premium_screen.dart';
import 'enhancement_history_screen.dart';

class VideoEnhanceCategory {
  const VideoEnhanceCategory({
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

const videoEnhanceCategories = <VideoEnhanceCategory>[
  VideoEnhanceCategory(
    id: 'motion_deblur',
    title: 'Motion Deblur',
    description: 'Recover clarity in moving footage.',
    baseName: 'motion_deblur',
    icon: Icons.motion_photos_off_outlined,
  ),
  VideoEnhanceCategory(
    id: 'creative',
    title: 'Creative Detail',
    description: 'Add expressive texture & fine detail.',
    baseName: 'creative',
    icon: Icons.brush_rounded,
  ),
  VideoEnhanceCategory(
    id: 'auto',
    title: 'Enhance Videos',
    description: 'Restore overall clarity, consistency & detail.',
    baseName: 'auto',
    icon: Icons.auto_awesome_rounded,
  ),
  VideoEnhanceCategory(
    id: 'slow_motion',
    title: 'Slow Motion',
    description: 'Smoother frame motion at half speed.',
    baseName: 'slow_motion',
    icon: Icons.slow_motion_video_rounded,
  ),
  VideoEnhanceCategory(
    id: 'precision',
    title: 'Upscale Quality',
    description: 'Sharper video, true to the original.',
    baseName: 'precision',
    icon: Icons.zoom_out_map_rounded,
  ),
  VideoEnhanceCategory(
    id: 'colorize',
    title: 'Colourize Videos',
    description: 'Bring black & white video to vibrant color.',
    baseName: 'colorize',
    icon: Icons.color_lens_outlined,
  ),
  VideoEnhanceCategory(
    id: 'denoise',
    title: 'Denoise',
    description: 'Reduce grain and low-light video noise.',
    baseName: 'denoise',
    icon: Icons.grain_rounded,
  ),
  VideoEnhanceCategory(
    id: 'hdr',
    title: 'HDR',
    description: 'Expand highlights and dynamic color range.',
    baseName: 'hdr',
    icon: Icons.hdr_on_rounded,
  ),
];

class VideoEnhancerCategoriesScreen extends StatefulWidget {
  const VideoEnhancerCategoriesScreen({
    super.key,
    required this.onSelectCategory,
  });

  final ValueChanged<VideoEnhanceCategory> onSelectCategory;

  @override
  State<VideoEnhancerCategoriesScreen> createState() =>
      _VideoEnhancerCategoriesScreenState();
}

class _VideoEnhancerCategoriesScreenState
    extends State<VideoEnhancerCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = dark ? Colors.white60 : const Color(0xFF64748B);

    return CustomScrollView(
      cacheExtent: 60.0,
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
                        'AI Video Remaster',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Select an enhancement to transform your video',
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
                final category = videoEnhanceCategories[index];
                return _VideoCategoryGridItem(
                  index: index,
                  category: category,
                  onTap: () {
                    AppHaptics.selection();
                    final premium = Get.find<PremiumController>();
                    if (!premium.hasProAccess) {
                      PremiumScreen.open(context, initialPlanId: 'pro_monthly');
                      return;
                    }
                    widget.onSelectCategory(category);
                  },
                );
              },
              childCount: videoEnhanceCategories.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoCategoryGridItem extends StatelessWidget {
  const _VideoCategoryGridItem({
    required this.index,
    required this.category,
    required this.onTap,
  });

  final int index;
  final VideoEnhanceCategory category;
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
              child: RepaintBoundary(
                child: VideoCategoryAnimCard(
                  index: index,
                  category: category,
                ),
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

class VideoCategoryAnimCard extends StatelessWidget {
  const VideoCategoryAnimCard({
    super.key,
    required this.index,
    required this.category,
  });

  final int index;
  final VideoEnhanceCategory category;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isRouteActive = ModalRoute.of(context)?.isCurrent ?? true;
    final webpPath =
        'assets/videos/remaster_categories/${category.baseName}.webp';

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF141416) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: isRouteActive
            ? Image.asset(
                webpPath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                filterQuality: FilterQuality.low,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return _buildShimmerPlaceholder(dark);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildShimmerPlaceholder(dark);
                },
              )
            : _buildShimmerPlaceholder(dark),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(bool dark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _VideoTopLeftShimmer(isDark: dark),
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

class _VideoTopLeftShimmer extends StatefulWidget {
  const _VideoTopLeftShimmer({required this.isDark});

  final bool isDark;

  @override
  State<_VideoTopLeftShimmer> createState() => _VideoTopLeftShimmerState();
}

class _VideoTopLeftShimmerState extends State<_VideoTopLeftShimmer>
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
