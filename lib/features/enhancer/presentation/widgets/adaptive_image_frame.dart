import 'package:flutter/material.dart';

/// Sizes a full-width preview from the source image without cropping it.
class AdaptiveImageFrame extends StatefulWidget {
  const AdaptiveImageFrame({
    super.key,
    required this.image,
    required this.imageKey,
    required this.fallbackHeight,
    required this.maxHeight,
    required this.child,
    this.minHeight = 200,
  });

  final ImageProvider? image;
  final Object? imageKey;
  final double fallbackHeight;
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  State<AdaptiveImageFrame> createState() => _AdaptiveImageFrameState();
}

class _AdaptiveImageFrameState extends State<AdaptiveImageFrame> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant AdaptiveImageFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageKey != oldWidget.imageKey) _resolveImage();
  }

  void _resolveImage() {
    _removeListener();
    _aspectRatio = null;
    final provider = widget.image;
    if (provider == null) return;
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((imageInfo, _) {
      final width = imageInfo.image.width.toDouble();
      final height = imageInfo.image.height.toDouble();
      if (mounted && width > 0 && height > 0) {
        setState(() => _aspectRatio = width / height);
      }
      stream.removeListener(listener);
      if (_stream == stream) {
        _stream = null;
        _listener = null;
      }
    }, onError: (_, __) {
      stream.removeListener(listener);
      if (_stream == stream) {
        _stream = null;
        _listener = null;
      }
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _removeListener() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final ratio = _aspectRatio;
          final height = ratio == null
              ? widget.fallbackHeight
              : (constraints.maxWidth / ratio)
                  .clamp(widget.minHeight, widget.maxHeight);
          final width = ratio == null
              ? constraints.maxWidth
              : (height * ratio).clamp(0.0, constraints.maxWidth);
          return AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: widget.child,
              ),
            ),
          );
        },
      );
}
