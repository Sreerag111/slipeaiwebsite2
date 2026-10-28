import 'package:flutter/material.dart';

import 'photo_comparison_view.dart';

class PhotoZoomView extends StatelessWidget {
  const PhotoZoomView({
    super.key,
    required this.image,
    this.transparentBackground = false,
  });

  final ImageProvider image;
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          Positioned.fill(
            child: transparentBackground
                ? const CustomPaint(painter: TransparencyCheckerboard())
                : const ColoredBox(color: Colors.black),
          ),
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(80),
              child: Center(
                child: Image(image: image, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton.filledTonal(
              tooltip: 'Close zoom view',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Text(
              'Pinch to zoom · Drag to explore',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ]),
      ),
    );
  }
}
