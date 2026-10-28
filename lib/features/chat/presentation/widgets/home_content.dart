import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../../theme/app_text_styles.dart';
import '../../../../theme/theme_controller.dart';
import '../../domain/entities/image_preset.dart';
import 'preset_thumbnail.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.isMemeMode,
    required this.onMemeSuggestionTap,
    required this.onTryImagePresets,
  });

  final bool isMemeMode;
  final ValueChanged<String> onMemeSuggestionTap;
  final VoidCallback onTryImagePresets;

  static const _featuredPresetIds = [
    'twin_me',
    'personality_sketch',
    'barbie_me',
  ];

  static const List<Map<String, String>> _memeSuggestionItems = [
    {
      'icon': '✨',
      'label': 'Code First Try',
      'prompt': 'When code compiles on the first try'
    },
    {
      'icon': '🤖',
      'label': '2 AM Debugging',
      'prompt': 'Debugging at 2 AM with 50 browser tabs open'
    },
    {
      'icon': '😂',
      'label': 'Senior vs Junior',
      'prompt': 'Senior dev watching junior dev push to main'
    },
    {
      'icon': '☕',
      'label': 'Friday Deploy',
      'prompt': 'Deploying code on a Friday afternoon'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      if (isMemeMode) return _buildMemeCanvas(isDark);
      return _buildHomePage(isDark);
    });
  }

  Widget _buildHomePage(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Try a look with your photo or describe your own idea.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displaySmall.copyWith(
                        fontSize: 20,
                        color: isDark ? Colors.white : Colors.black,
                      )),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onTryImagePresets,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 15),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Try it',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: _featuredPresetIds.map((id) {
                      final preset = imagePresets.firstWhere(
                        (candidate) => candidate.id == id,
                      );
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            key: ValueKey('preview_${preset.id}'),
                            onTap: onTryImagePresets,
                            borderRadius: BorderRadius.circular(14),
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: presetThumbnailAspectRatio,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: PresetThumbnail(preset: preset),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 38,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Text(
                                      preset.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.labelSmall.copyWith(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemeCanvas(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Create an AI Meme',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 22,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOut),
                const SizedBox(height: 8),
                Text(
                  'Describe your idea, upload a photo or pick a suggestion',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? Colors.white70 : Colors.black,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms)
                    .slideY(begin: 0.08, curve: Curves.easeOut),
                const SizedBox(height: 36),
                ...List.generate(
                  _memeSuggestionItems.length,
                  (i) => _buildMemeSuggestionChip(i, isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemeSuggestionChip(int index, bool isDark) {
    final item = _memeSuggestionItems[index];
    final chipBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
    final chipBorder = isDark
        ? Border.all(
            color: Colors.white.withValues(alpha: 0.09),
            width: 1,
          )
        : Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          );
    final labelColor = isDark ? Colors.white60 : Colors.black;
    final arrowBg =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final arrowColor = isDark ? Colors.white54 : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onMemeSuggestionTap(item['prompt']!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(14),
            border: chipBorder,
          ),
          child: Row(
            children: [
              Text(item['icon']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['label']!,
                  style:
                      AppTextStyles.labelSmallMuted.copyWith(color: labelColor),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: arrowBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    Icon(Icons.north_east_rounded, size: 13, color: arrowColor),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 180 + index * 70))
            .slideY(begin: 0.06, curve: Curves.easeOut),
      ),
    );
  }
}
