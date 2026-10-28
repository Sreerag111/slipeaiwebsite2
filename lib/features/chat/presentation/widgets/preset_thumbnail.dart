import 'package:flutter/material.dart';

import '../../domain/entities/image_preset.dart';

/// The supplied preset artwork is 1122 x 1402 (approximately 4:5).
const presetThumbnailAspectRatio = 1122 / 1402;

/// Displays a preset thumbnail from either PNG or JPG without surfacing an
/// image-loading exception if an older app bundle lacks one format.
class PresetThumbnail extends StatelessWidget {
  const PresetThumbnail({super.key, required this.preset});

  final ImagePreset preset;

  @override
  Widget build(BuildContext context) {
    final paths = preset.imageAssetCandidates;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fallback = ColoredBox(
      color: dark ? const Color(0xFF242424) : const Color(0xFFEAEAEA),
      child: Center(
        child: Icon(Icons.image_outlined,
            color: dark ? Colors.white70 : Colors.black54),
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final pixelWidth =
          (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
              .ceil()
              .clamp(1, 2048);
      return Image.asset(
        paths[0],
        fit: BoxFit.cover,
        cacheWidth: pixelWidth,
        errorBuilder: (_, __, ___) => Image.asset(
          paths[1],
          fit: BoxFit.cover,
          cacheWidth: pixelWidth,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    });
  }
}
