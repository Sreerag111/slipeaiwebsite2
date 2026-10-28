import 'dart:io';
import 'package:plagiarism_checker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageViewerDialog extends StatefulWidget {
  const ImageViewerDialog({
    super.key,
    required this.imagePathOrUrl,
    this.caption,
  });

  final String imagePathOrUrl;
  final String? caption;

  static void show(
    BuildContext context, {
    required String imagePathOrUrl,
    String? caption,
  }) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (_) => ImageViewerDialog(
        imagePathOrUrl: imagePathOrUrl,
        caption: caption,
      ),
    );
  }

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  final TransformationController _transformController =
      TransformationController();
  bool _isSaving = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  bool get _isRemote =>
      widget.imagePathOrUrl.startsWith('http://') ||
      widget.imagePathOrUrl.startsWith('https://');

  Future<void> _shareImage() async {
    HapticFeedback.selectionClick();
    try {
      if (_isRemote) {
        final res = await http.get(Uri.parse(widget.imagePathOrUrl));
        final tmp = await getTemporaryDirectory();
        final ext = widget.imagePathOrUrl.contains('.png') ? 'png' : 'jpg';
        final file = File(
            '${tmp.path}/shared_preview_${DateTime.now().millisecondsSinceEpoch}.$ext');
        await file.writeAsBytes(res.bodyBytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: widget.caption,
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(widget.imagePathOrUrl)],
            text: widget.caption,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ImageViewerDialog] Share failed: $e');
    }
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;
    HapticFeedback.selectionClick();
    setState(() => _isSaving = true);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request) {
          if (mounted) {
            _showPermissionDialog(context);
          }
          return;
        }
      }

      if (_isRemote) {
        final res = await http.get(Uri.parse(widget.imagePathOrUrl));
        final ext = widget.imagePathOrUrl.contains('.png') ? 'png' : 'jpg';
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/temp_slipe_ai_${DateTime.now().millisecondsSinceEpoch}.$ext');
        await tempFile.writeAsBytes(res.bodyBytes);
        await Gal.putImage(tempFile.path, album: 'Slipe AI');
      } else {
        await Gal.putImage(widget.imagePathOrUrl, album: 'Slipe AI');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Image saved to gallery'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ImageViewerDialog] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Permission Required',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Gallery permission is required to save images. Please enable it in your device settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child:
                Text('Open Settings', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F11),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.file_download_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
            tooltip: 'Save image',
            onPressed: _saveImage,
          ),
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Share image',
            onPressed: _shareImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformController,
        minScale: 1.0,
        maxScale: 4.0,
        child: SizedBox.expand(
          child: _isRemote
              ? CachedNetworkImage(
                  imageUrl: widget.imagePathOrUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white70,
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
                )
              : Image.file(
                  File(widget.imagePathOrUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
