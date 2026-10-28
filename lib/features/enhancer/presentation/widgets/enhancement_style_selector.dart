import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EnhancementStyle {
  const EnhancementStyle(this.id, this.label, this.description, this.icon);

  final String id;
  final String label;
  final String description;
  final IconData icon;
}

// User-facing capabilities. The server owns the model and endpoint mapping.
const photoEnhancementStyles = <EnhancementStyle>[
  EnhancementStyle('remove_background', 'Remove Background',
      'Cut out subjects with transparent background',
      Icons.layers_clear_rounded),
  EnhancementStyle('auto', 'Enhance Photo Quality',
      'Boost overall clarity, details & resolution',
      Icons.auto_awesome_rounded),
  EnhancementStyle('color_balance', 'Balance Colour',
      'Correct color casts, tones & saturation', Icons.palette_outlined),
  EnhancementStyle('colorize', 'B/W to Color',
      'Transform black & white photos into vibrant color',
      Icons.color_lens_outlined),
  EnhancementStyle('creative', 'Refine Photos',
      'Enhance creative textures & details', Icons.brush_rounded),
  EnhancementStyle('precision', 'Upscale Photos',
      'Enlarge photo without losing quality', Icons.zoom_out_map_rounded),
  EnhancementStyle('denoise', 'Cleanup Photos',
      'Clean up grain and low-light noise', Icons.grain_rounded),
  EnhancementStyle('restore', 'Fix Dust & Scratches',
      'Repair old, scratched or damaged photos', Icons.auto_fix_high_rounded),
  EnhancementStyle('relight', 'Fix Lighting',
      'Balance exposure and brighten dark photos', Icons.wb_sunny_outlined),
  EnhancementStyle('sharpen', 'Sharpen Photos',
      'Fix blur and bring soft details into focus',
      Icons.center_focus_strong_rounded),
];

const videoEnhancementStyles = <EnhancementStyle>[
  EnhancementStyle('motion_deblur', 'Motion Deblur',
      'Recover clarity in moving footage', Icons.motion_photos_off_outlined),
  EnhancementStyle('creative', 'Creative Detail',
      'Add expressive texture & fine detail', Icons.brush_rounded),
  EnhancementStyle('auto', 'Enhance Videos',
      'Restore overall clarity, consistency & detail', Icons.auto_awesome_rounded),
  EnhancementStyle('slow_motion', 'Slow Motion',
      'Smoother frame motion at half speed', Icons.slow_motion_video_rounded),
  EnhancementStyle('precision', 'Upscale Quality',
      'Sharper video, true to the original', Icons.zoom_out_map_rounded),
  EnhancementStyle('colorize', 'Colourize Videos',
      'Bring black & white video to vibrant color', Icons.color_lens_outlined),
  EnhancementStyle('denoise', 'Denoise',
      'Reduce grain and low-light video noise', Icons.grain_rounded),
  EnhancementStyle('hdr', 'HDR',
      'Expand highlights and dynamic color range', Icons.hdr_on_rounded),
];

class EnhancementStyleSelector extends StatelessWidget {
  const EnhancementStyleSelector({
    super.key,
    required this.styles,
    required this.selectedId,
    required this.onSelected,
    required this.mediaName,
    this.enabled = true,
  });

  final List<EnhancementStyle> styles;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String mediaName;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 12),
          for (final style in styles)
            SizedBox(
              width: 108,
              child: Material(
                key: ValueKey('enhancement_${style.id}'),
                color: style.id == selectedId
                    ? (isDark
                        ? const Color(0xFF343434)
                        : const Color(0xFFF0EEE9))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                surfaceTintColor: Colors.transparent,
                elevation: style.id == selectedId ? 4 : 0,
                shadowColor:
                    Colors.black.withValues(alpha: isDark ? 0.5 : 0.22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: enabled ? () => onSelected(style.id) : null,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: style.id == selectedId
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark
                                    ? const Color(0xFF363636)
                                    : Colors.white),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.28 : 0.13),
                                blurRadius: 9,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(style.icon,
                              size: 23,
                              color: style.id == selectedId
                                  ? (isDark ? Colors.black : Colors.white)
                                  : scheme.onSurface),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          style.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: style.id == selectedId
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: style.id == selectedId
                                ? (isDark ? Colors.white : Colors.black)
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
