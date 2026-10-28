import 'dart:convert';
import 'package:plagiarism_checker/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/theme_controller.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/haptics/app_haptics.dart';
import 'image_viewer_dialog.dart';
import 'media_shimmer.dart';
import 'report_sheet.dart';

class GeneratedImageBubble extends StatefulWidget {
  const GeneratedImageBubble({
    super.key,
    required this.imageUrl,
    this.imagePrompt,
  });

  final String imageUrl;
  final String? imagePrompt;

  @override
  State<GeneratedImageBubble> createState() => _GeneratedImageBubbleState();
}

class _GeneratedImageBubbleState extends State<GeneratedImageBubble> {
  bool _isDownloading = false;
  int _feedbackStatus = 0; // 0: none, 1: up, -1: down

  static bool _isDataUri(String uri) => uri.startsWith('data:image');

  bool get isGif {
    final lower = widget.imageUrl.toLowerCase();
    return lower.contains('.gif') ||
        lower.contains('/gif') ||
        lower.contains('format=gif') ||
        lower.contains('mime=image%2fgif');
  }

  static Widget _buildImageWidget(
    String url, {
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
  }) {
    if (_isDataUri(url)) {
      final base64 = url.split(',').last;
      try {
        return Image.memory(
          base64Decode(base64),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _buildErrorState(),
        );
      } catch (_) {
        return _buildErrorState();
      }
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: 1080,
      placeholder: (_, __) => _buildImagePlaceholder(),
      errorWidget: (_, __, ___) => _buildErrorState(),
    );
  }

  static Widget _buildErrorState() {
    final isDark = ThemeController.instance.isDarkMode;
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded,
              color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
              size: 36),
          const SizedBox(height: 8),
          Text(
            'Image could not be loaded',
            style: GoogleFonts.montserrat(
                fontSize: 13, color: isDark ? Colors.white38 : Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gifMode = isGif;

    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openFullScreen(context),
            child: Hero(
              tag: widget.imageUrl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: gifMode ? 260 : double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121214)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildImageWidget(
                        widget.imageUrl,
                        width: gifMode ? 260 : double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                      // Telegram-style GIF badge
                      if (gifMode)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'GIF',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      // Tap-to-expand overlay hint
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.open_in_full_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Action row
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionChip(
                icon: _isDownloading
                    ? Icons.hourglass_top_rounded
                    : Icons.download_rounded,
                onTap: () => _downloadImage(context),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.share_rounded,
                onTap: () => _shareImage(context),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: _feedbackStatus == 1
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                onTap: () {
                  AppHaptics.selection();
                  if (_feedbackStatus == 1) {
                    setState(() => _feedbackStatus = 0);
                  } else {
                    setState(() => _feedbackStatus = 1);
                    _submitPositiveFeedback();
                    _showSnack(context, 'Thanks for your feedback!');
                  }
                },
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: _feedbackStatus == -1
                    ? Icons.thumb_down_alt_rounded
                    : Icons.thumb_down_alt_outlined,
                onTap: () {
                  if (_feedbackStatus == -1) {
                    setState(() => _feedbackStatus = 0);
                    return;
                  }
                  ReportSheet.show(
                    context,
                    contentUrl: widget.imageUrl,
                    contentPrompt: widget.imagePrompt,
                    contentType: 'image',
                    onSubmit: () {
                      if (mounted) {
                        setState(() => _feedbackStatus = -1);
                        _showSnack(context, 'Feedback submitted successfully');
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ],
      );
    });
  }

  static Widget _buildImagePlaceholder() {
    final isDark = ThemeController.instance.isDarkMode;

    return MediaShimmer(
      isDark: isDark,
      label: 'Loading image…',

      // GeneratedImageBubble already provides its border/frame.
      showFrame: false,
    );
  }

  void _openFullScreen(BuildContext context) {
    ImageViewerDialog.show(
      context,
      imagePathOrUrl: widget.imageUrl,
      caption: widget.imagePrompt,
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    if (_isDownloading) return;
    AppHaptics.tap();
    setState(() => _isDownloading = true);

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request) {
          if (context.mounted) {
            _showPermissionDialog(context, 'images');
          }
          return;
        }
      }

      final bytes = await _fetchImageBytes();
      final isGifFile = isGif ||
          (bytes.length > 3 &&
              bytes[0] == 0x47 &&
              bytes[1] == 0x49 &&
              bytes[2] == 0x46);
      final ext = isGifFile ? 'gif' : 'png';

      final tempDir = await getTemporaryDirectory();
      final fileName = 'slipe_ai_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Gal.putImage(file.path, album: 'Slipe AI');

      if (context.mounted) {
        _showSnack(
          context,
          isGifFile ? '✓ GIF saved to gallery' : '✓ Image saved to gallery',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Failed to save file. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    AppHaptics.tap();
    try {
      final bytes = await _fetchImageBytes();
      final isGifFile = isGif ||
          (bytes.length > 3 &&
              bytes[0] == 0x47 &&
              bytes[1] == 0x49 &&
              bytes[2] == 0x46);
      final ext = isGifFile ? 'gif' : 'png';
      final mime = isGifFile ? 'image/gif' : 'image/png';

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/slipe_ai_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await tempFile.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path, mimeType: mime)],
          text: widget.imagePrompt != null && widget.imagePrompt!.isNotEmpty
              ? 'Created with Slipe AI: $widget.imagePrompt'
              : 'Created with Slipe AI',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Failed to share file. Please try again.');
      }
    }
  }

  Future<Uint8List> _fetchImageBytes() async {
    if (_isDataUri(widget.imageUrl)) {
      final base64 = widget.imageUrl.split(',').last;
      try {
        return base64Decode(base64);
      } catch (_) {
        throw Exception('Failed to decode image data');
      }
    }
    final response = await http.get(Uri.parse(widget.imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch image');
    }
    return response.bodyBytes;
  }

  void _showSnack(BuildContext context, String message) {
    final isDark = ThemeController.instance.isDarkMode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.caption.copyWith(
            color: isDark ? Colors.white : Colors.white,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitPositiveFeedback() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user?.uid ?? 'anonymous',
        'contentUrl': widget.imageUrl,
        'contentPrompt': widget.imagePrompt,
        'contentType': 'image',
        'isPositive': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to submit positive feedback: $e');
    }
  }

  void _showPermissionDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Permission Required',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Gallery permission is required to save $type. Please enable it in your device settings.',
          style: const TextStyle(color: Colors.white70),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Action chip button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16, color: isDark ? Colors.white60 : Colors.black),
            ],
          ),
        ),
      );
    });
  }
}
