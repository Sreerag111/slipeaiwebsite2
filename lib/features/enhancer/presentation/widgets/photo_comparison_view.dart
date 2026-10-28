import 'package:flutter/material.dart';

class PhotoComparisonView extends StatefulWidget {
  const PhotoComparisonView({
    super.key,
    required this.before,
    required this.after,
    this.transparentBackground = false,
    this.fit = BoxFit.cover,
  });

  final ImageProvider before;
  final ImageProvider after;
  final bool transparentBackground;
  final BoxFit fit;

  @override
  State<PhotoComparisonView> createState() => _PhotoComparisonViewState();
}

class _PhotoComparisonViewState extends State<PhotoComparisonView> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, size) => GestureDetector(
          onHorizontalDragUpdate: (details) => setState(() {
            _position =
                (details.localPosition.dx / size.maxWidth).clamp(0.0, 1.0);
          }),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: widget.before,
                fit: widget.fit,
              ),
              ClipRect(
                clipper: _RightClipper(_position),
                child: Stack(fit: StackFit.expand, children: [
                  if (widget.transparentBackground)
                    const CustomPaint(painter: TransparencyCheckerboard())
                  else
                    ColoredBox(color: Theme.of(context).colorScheme.surface),
                  Image(
                    image: widget.after,
                    fit: widget.fit,
                  ),
                ]),
              ),
              Positioned(
                left: size.maxWidth * _position - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                left: size.maxWidth * _position - 19,
                top: size.maxHeight / 2 - 19,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                      )
                    ],
                  ),
                  child: const Icon(Icons.drag_handle_rounded,
                      color: Colors.black, size: 22),
                ),
              ),
              const Positioned(left: 12, bottom: 12, child: _Tag('Before')),
              const Positioned(right: 12, bottom: 12, child: _Tag('After')),
            ],
          ),
        ),
      );
}

class TransparencyCheckerboard extends CustomPainter {
  const TransparencyCheckerboard();

  @override
  void paint(Canvas canvas, Size size) {
    const tile = 14.0;
    final light = Paint()..color = const Color(0xFFF3F3F3);
    final dark = Paint()..color = const Color(0xFFDCDCDC);
    for (var row = 0; row * tile < size.height; row++) {
      for (var column = 0; column * tile < size.width; column++) {
        canvas.drawRect(
          Rect.fromLTWH(column * tile, row * tile, tile, tile),
          (row + column).isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TransparencyCheckerboard oldDelegate) => false;
}

class _RightClipper extends CustomClipper<Rect> {
  const _RightClipper(this.position);
  final double position;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
      size.width * position, 0, size.width * (1 - position), size.height);

  @override
  bool shouldReclip(_RightClipper oldClipper) =>
      oldClipper.position != position;
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
      );
}
