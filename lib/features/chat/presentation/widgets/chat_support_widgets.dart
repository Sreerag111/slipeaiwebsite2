import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_text_styles.dart';
import '../../../../theme/theme_controller.dart';

class KeepAliveChatItem extends StatefulWidget {
  const KeepAliveChatItem({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<KeepAliveChatItem> createState() => KeepAliveChatItemState();
}

class KeepAliveChatItemState extends State<KeepAliveChatItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class ChatThinkingIndicator extends StatefulWidget {
  const ChatThinkingIndicator();

  @override
  State<ChatThinkingIndicator> createState() => ChatThinkingIndicatorState();
}

class ChatThinkingIndicatorState extends State<ChatThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final dotCount = 1 + (_controller.value * 3).floor().clamp(0, 2);
          final opacity = 0.55 +
              (_controller.value <= 0.5
                      ? _controller.value
                      : 1 - _controller.value) *
                  0.5;
          return Opacity(
            opacity: opacity,
            child: Text(
              List.filled(dotCount, '●').join(' '),
              style: AppTextStyles.bodyLargeW500.copyWith(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      );
    });
  }
}

class AssistantMessageText extends StatelessWidget {
  final String text;
  final bool isError;

  const AssistantMessageText({
    required this.text,
    required this.isError,
  });

  static final Map<int, String> _plainTextCache = <int, String>{};
  static const int _cacheMaxSize = 200;

  @override
  Widget build(BuildContext context) {
    if (_plainTextCache.length > _cacheMaxSize) {
      _plainTextCache.remove(_plainTextCache.keys.first);
    }
    final displayText = _plainTextCache.putIfAbsent(
      text.hashCode,
      () => _toReadableText(text),
    );
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return SelectableText(
        displayText,
        style: AppTextStyles.bodyLarge.copyWith(
            fontSize: 17,
            color: isError
                ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade700)
                : (isDark ? Colors.white : Colors.black),
            fontWeight: FontWeight.w500),
      );
    });
  }

  static String _toReadableText(String value) {
    return value
        .replaceAll(RegExp(r'```[a-zA-Z0-9_+-]*\n?'), '')
        .replaceAll('```', '')
        .replaceAll(RegExp(r'(^|\n)#{1,6}\s*'), '\n')
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1)!)
        .replaceAllMapped(RegExp(r'__(.*?)__'), (match) => match.group(1)!)
        .replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1)!)
        .trim();
  }
}
