import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class SelectedVideoPreview extends StatefulWidget {
  const SelectedVideoPreview({
    super.key,
    required this.file,
    this.enabled = true,
    this.onAspectRatio,
  });

  final File file;
  final bool enabled;
  final ValueChanged<double>? onAspectRatio;

  @override
  State<SelectedVideoPreview> createState() => _SelectedVideoPreviewState();
}

class _SelectedVideoPreviewState extends State<SelectedVideoPreview> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);
    _controller.addListener(_refresh);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _ready = true);
        final ratio = _controller.value.aspectRatio;
        if (ratio.isFinite && ratio > 0) widget.onAspectRatio?.call(ratio);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant SelectedVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled && _ready) {
      _controller.pause();
    }
  }

  void _refresh() {
    if (mounted && _ready) setState(() {});
  }

  Future<void> _togglePlayback() async {
    if (!_ready || !widget.enabled) return;
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(child: Text('Video preview unavailable'));
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final size = _controller.value.size;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55)
              ],
              stops: const [0.58, 1],
            ),
          ),
        ),
        Center(
          child: IconButton.filled(
            tooltip: _controller.value.isPlaying ? 'Pause video' : 'Play video',
            onPressed: widget.enabled ? _togglePlayback : null,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.55),
              foregroundColor: Colors.white,
              minimumSize: const Size(56, 56),
            ),
            icon: Icon(_controller.value.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 18,
          child: Text(
            widget.file.uri.pathSegments.last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
