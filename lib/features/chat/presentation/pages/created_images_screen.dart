import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/theme_controller.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/widgets/get_pro_badge.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../controllers/chat_controller.dart';
import '../widgets/image_viewer_dialog.dart';

class CreatedImagesScreen extends StatefulWidget {
  const CreatedImagesScreen({super.key});

  @override
  State<CreatedImagesScreen> createState() => _CreatedImagesScreenState();
}

class _CreatedImagesScreenState extends State<CreatedImagesScreen> {
  late Future<List<_CreatedImage>> _images;

  @override
  void initState() {
    super.initState();
    _images = _loadImages();
  }

  Future<List<_CreatedImage>> _loadImages() async {
    final threads = await Get.find<ChatRepository>().getChatThreads();
    final images = <_CreatedImage>[];
    final seenUrls = <String>{};

    void addMessages(Iterable<ChatMessage> messages) {
      for (final message in messages) {
        final url = message.generatedImageUrl;
        if (message.isUser || url == null || url.isEmpty) continue;
        if (!seenUrls.add(url)) continue;
        images.add(_CreatedImage(
          url: url,
          prompt: message.imagePrompt,
          createdAt: message.createdAt,
        ));
      }
    }

    for (final thread in threads) {
      addMessages(thread.messages);
    }
    // Include an image that has just finished generating before its thread
    // finishes saving, or one that can only be shown in the current session.
    addMessages(Get.find<ChatController>().chatMessages);
    images.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return images;
  }

  Future<void> _refresh() async {
    final next = _loadImages();
    setState(() {
      _images = next;
    });
    try {
      await next;
    } catch (error, stackTrace) {
      // FutureBuilder displays the retry state; complete the refresh gesture.
      log('Unable to refresh created images',
          error: error, stackTrace: stackTrace);
    }
  }

  Widget _image(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image/')) {
      try {
        return Image.memory(
          base64Decode(url.split(',').last),
          fit: fit,
          errorBuilder: (_, __, ___) => const _ImageError(),
        );
      } catch (_) {
        return const _ImageError();
      }
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: fit == BoxFit.cover ? 600 : null,
      placeholder: (_, __) => const _ImageLoading(),
      errorWidget: (_, __, ___) => const _ImageError(),
    );
  }

  void _openImage(_CreatedImage image) {
    if (!image.url.startsWith('data:image/')) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ImageViewerDialog(
            imagePathOrUrl: image.url,
            caption: image.prompt,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: SizedBox.expand(
              child: _image(image.url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dark = ThemeController.instance.isDarkMode;
      final background = dark ? Colors.black : const Color(0xFFF8FAFC);
      final foreground = dark ? Colors.white : const Color(0xFF161A22);
      final muted = dark ? Colors.white60 : const Color(0xFF64748B);
      final showGetPro = Get.find<PremiumController>().shouldShowUpgrade;

      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          toolbarHeight: 60,
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: showGetPro ? const GetProBadge() : null,
        ),
        body: FutureBuilder<List<_CreatedImage>>(
          future: _images,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _GalleryMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load your images',
                subtitle: 'Check your connection and try again.',
                action: TextButton(
                  onPressed: _refresh,
                  child: const Text('Try again'),
                ),
              );
            }
            final images = snapshot.data ?? const <_CreatedImage>[];
            if (images.isEmpty) {
              return _GalleryMessage(
                icon: Icons.auto_awesome_rounded,
                title: 'Your creations will appear here',
                subtitle: 'Create an image to start your collection.',
                action: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Create image'),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created images',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${images.length} ${images.length == 1 ? 'image' : 'images'}',
                            style:
                                GoogleFonts.inter(fontSize: 14, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    sliver: SliverGrid.builder(
                      itemCount: images.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final image = images[index];
                        return Material(
                          color: dark
                              ? const Color(0xFF191B20)
                              : const Color(0xFFE8EDF3),
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openImage(image),
                            child: _image(image.url),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class _CreatedImage {
  const _CreatedImage({required this.url, this.prompt, this.createdAt});

  final String url;
  final String? prompt;
  final DateTime? createdAt;
}

class _GalleryMessage extends StatelessWidget {
  const _GalleryMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: dark ? Colors.white54 : Colors.black45),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14)),
            const SizedBox(height: 14),
            action,
          ],
        ),
      ),
    );
  }
}

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(Icons.broken_image_outlined, size: 32),
      );
}
