import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/image_aspect_ratio.dart';

class ImageAspectRatioSelector extends StatelessWidget {
  const ImageAspectRatioSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ImageAspectRatio selected;
  final ValueChanged<ImageAspectRatio> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF303030) : const Color(0xFFF1F1F1),
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final ratio in ImageAspectRatio.values)
              _ratioButton(ratio, dark),
          ],
        ),
      ),
    );
  }

  Widget _ratioButton(ImageAspectRatio ratio, bool dark) {
    final active = ratio == selected;
    final foreground = active
        ? (dark ? Colors.black : Colors.white)
        : (dark ? Colors.white : Colors.black);
    return InkWell(
      key: ValueKey('ratio_${ratio.label}'),
      onTap: () => onSelected(ratio),
      borderRadius: BorderRadius.circular(9),
      child: Ink(
        width: 46,
        height: 43,
        decoration: BoxDecoration(
          color: active
              ? (dark ? Colors.white : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 16,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: ratio == ImageAspectRatio.portrait ? 8 : 11,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(color: foreground, width: 1.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ratio.label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
