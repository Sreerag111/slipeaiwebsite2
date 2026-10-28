import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shows the actual source or result in enhancement/save dialogs.
class PremiumMediaPreview extends StatefulWidget {
  const PremiumMediaPreview({
    super.key,
    required this.source,
    this.isVideo = false,
  });

  final String source;
  final bool isVideo;

  @override
  State<PremiumMediaPreview> createState() => _PremiumMediaPreviewState();
}

class _PremiumMediaPreviewState extends State<PremiumMediaPreview> {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _failed = false;

  bool get _remote =>
      widget.source.startsWith('https://') ||
      widget.source.startsWith('http://');

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = _remote
        ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
        : VideoPlayerController.file(File(widget.source));
    _video = controller;
    try {
      await controller.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height =
        (MediaQuery.sizeOf(context).height * 0.36).clamp(160.0, 340.0);
    final error = Center(
      child: Icon(
          widget.isVideo
              ? Icons.videocam_off_outlined
              : Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    Widget content;
    if (widget.isVideo) {
      if (_failed) {
        content = error;
      } else if (!_ready) {
        content =
            const Center(child: CircularProgressIndicator(strokeWidth: 2));
      } else {
        final size = _video!.value.size;
        content = FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(_video!)),
        );
      }
    } else {
      content = _remote
          ? CachedNetworkImage(
              imageUrl: widget.source,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => error,
              placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)))
          : Image.file(File(widget.source),
              fit: BoxFit.contain, errorBuilder: (_, __, ___) => error);
    }
    return SizedBox(width: double.infinity, height: height, child: content);
  }
}
