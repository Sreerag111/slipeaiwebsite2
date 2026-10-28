import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/image_preset.dart';
import '../widgets/preset_thumbnail.dart';

class ImagePresetSelection {
  const ImagePresetSelection({required this.preset, required this.photoPath});

  final ImagePreset preset;
  final String photoPath;
}

class ImagePresetGalleryPage extends StatefulWidget {
  const ImagePresetGalleryPage({super.key, this.onPhotoSelected});

  final Future<void> Function(ImagePresetSelection)? onPhotoSelected;

  @override
  State<ImagePresetGalleryPage> createState() => _ImagePresetGalleryPageState();
}

class _ImagePresetGalleryPageState extends State<ImagePresetGalleryPage> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    if (!ImagePresetService.instance.isLoaded) {
      unawaited(ImagePresetService.instance.fetchPresets());
    }
  }

  Future<void> _selectPreset(ImagePreset preset) async {
    if (_picking) return;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Take or choose a photo'),
        content: const Text('Select one clear photo to use with this look.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ImageSource.camera),
            child: const Text('Take a photo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ImageSource.gallery),
            child: const Text('Choose a photo'),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _picking = true);
    try {
      if (source == ImageSource.camera) {
        var permission = await Permission.camera.status;
        if (!permission.isGranted)
          permission = await Permission.camera.request();
        if (!permission.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Camera permission is required to take a photo.'),
            ));
          }
          return;
        }
      }
      final photo = await _picker.pickImage(source: source);
      if (photo == null || !mounted) return;
      final selection = ImagePresetSelection(
        preset: preset,
        photoPath: photo.path,
      );
      if (widget.onPhotoSelected != null) {
        await widget.onPhotoSelected!(selection);
      } else {
        Navigator.pop(context, selection);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open your photos. Please try again.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final background = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Try an image look')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Text(
                'Choose a look, then add your photo',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<ImagePreset>>(
                valueListenable: ImagePresetService.instance.presetsNotifier,
                builder: (context, presetsList, _) {
                  return RefreshIndicator(
                    onRefresh: () => ImagePresetService.instance
                        .fetchPresets(forceRefresh: true),
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: presetThumbnailAspectRatio,
                      ),
                      itemCount: presetsList.length,
                      itemBuilder: (context, index) {
                        final preset = presetsList[index];
                        return Semantics(
                          button: true,
                          label: preset.title,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: ValueKey('preset_${preset.id}'),
                                onTap: _picking
                                    ? null
                                    : () => _selectPreset(preset),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    PresetThumbnail(preset: preset),
                                    const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.center,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Color(0xB3000000)
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 14,
                                      right: 12,
                                      bottom: 14,
                                      child: Text(
                                        preset.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
