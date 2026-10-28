import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreativeBottomBar extends StatelessWidget {
  const CreativeBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <(Object, String)>[
    ('assets/icons/create_image.png', 'Generate'),
    (Icons.photo_filter_rounded, 'Enhance'),
    (Icons.movie_filter_rounded, 'Remaster'),
    ('assets/icons/create_video.png', 'Videos'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = dark ? Colors.black : Colors.white;
    final inactive = dark ? Colors.white54 : const Color(0xFF64748B);
    final selectedBackground = dark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: (dark ? Colors.white : Colors.black)
                  .withValues(alpha: dark ? 0.11 : 0.10),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: (dark ? Colors.white : Colors.black)
                  .withValues(alpha: dark ? 0.05 : 0.04),
              blurRadius: 3,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 330),
                    curve: Curves.easeOutCubic,
                    left: tabWidth * selectedIndex,
                    top: 2,
                    bottom: 2,
                    width: tabWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selectedBackground,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: selectedBackground.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: selectedBackground.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(_items.length, (index) {
                      final selected = selectedIndex == index;
                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: _items[index].$2,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelected(index),
                            child: TweenAnimationBuilder<Color?>(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOut,
                              tween: ColorTween(
                                end: selected ? active : inactive,
                              ),
                              builder: (context, color, child) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_items[index].$1 is String)
                                    Image.asset(
                                      _items[index].$1 as String,
                                      width: 24,
                                      height: 24,
                                      color: color,
                                    )
                                  else
                                    Icon(_items[index].$1 as IconData,
                                        size: 24, color: color),
                                  const SizedBox(height: 4),
                                  Text(
                                    _items[index].$2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      height: 1.1,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
