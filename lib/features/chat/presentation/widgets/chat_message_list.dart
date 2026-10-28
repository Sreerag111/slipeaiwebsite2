import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/theme_controller.dart';
import '../../domain/entities/app_mode.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import '../controllers/chat_controller.dart';
import 'chat_sources_view.dart';
import 'chat_support_widgets.dart';
import 'generated_image_bubble.dart';
import 'image_viewer_dialog.dart';
import 'media_shimmer.dart';
import 'report_sheet.dart';
import 'scroll_to_bottom_button.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.mode,
    required this.chatMessages,
    required this.chatController,
    required this.activeConversationId,
    required this.isLoading,
    required this.showSourceField,
    required this.sourceController,
    required this.onToggleSourceField,
    required this.onRetryFailedMessage,
    required this.scrollController,
    required this.scrollToBottomVisible,
    required this.onScrollToBottom,
    required this.onSuggestionTap,
    this.hideEmptyChatPrompt = false,
  });

  final AppMode mode;
  final List<ChatMessage> chatMessages;
  final ChatController chatController;
  final String? activeConversationId;
  final bool isLoading;
  final bool showSourceField;
  final TextEditingController sourceController;
  final VoidCallback onToggleSourceField;
  final VoidCallback onRetryFailedMessage;
  final ScrollController scrollController;
  final bool scrollToBottomVisible;
  final VoidCallback onScrollToBottom;
  final ValueChanged<String> onSuggestionTap;
  final bool hideEmptyChatPrompt;

  @override
  Widget build(BuildContext context) {
    if (chatMessages.isEmpty && mode == AppMode.plagiarism) {
      return _buildPlagSetup();
    }
    if (chatMessages.isEmpty) return _buildEmptyChat();
    final streamingMsg = chatController.streamingMessage.value;
    final hasStreamingContent =
        streamingMsg != null && streamingMsg.text.trim().isNotEmpty;
    final isAwaitingFirstResponse = isLoading && chatMessages.last.isUser;

    final latestImageAlreadyArrived = chatMessages.isNotEmpty &&
        !chatMessages.last.isUser &&
        chatMessages.last.hasGeneratedImage;

    return Stack(
      children: [
        Scrollbar(
          controller: scrollController,
          child: ListView.builder(
            key: PageStorageKey<String>(
              'chat-list-${activeConversationId ?? mode.name}',
            ),
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            cacheExtent: 1600,
            addAutomaticKeepAlives: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: chatMessages.length +
                (hasStreamingContent
                    ? 1
                    : (chatController.isGeneratingMeme.value ||
                            (chatController.isGeneratingImage.value &&
                                !latestImageAlreadyArrived) ||
                            (isAwaitingFirstResponse &&
                                !latestImageAlreadyArrived &&
                                !chatController.isGeneratingImage.value &&
                                !chatController.isGeneratingMeme.value))
                        ? 1
                        : 0),
            itemBuilder: (_, i) {
              if (i == chatMessages.length) {
                if (hasStreamingContent) {
                  return _buildBubble(context, streamingMsg,
                      showActions: false);
                }
                if (chatController.isGeneratingMeme.value) {
                  return _buildMemeGeneratingBubble();
                }
                if (chatController.isGeneratingImage.value) {
                  return _buildImageGeneratingBubble();
                }
                return _buildTypingBubble();
              }
              final message = chatMessages[i];
              return KeepAliveChatItem(
                key: ValueKey<String>(
                  '${message.createdAt?.microsecondsSinceEpoch ?? i}'
                  '-${message.isUser}-${message.text.hashCode}',
                ),
                child: RepaintBoundary(child: _buildBubble(context, message)),
              );
            },
          ),
        ),
        ScrollToBottomButton(
          visible: scrollToBottomVisible,
          onTap: onScrollToBottom,
        ),
      ],
    );
  }

  Widget _buildEmptyChat() {
    if (mode == AppMode.chat && hideEmptyChatPrompt) {
      return const SizedBox.expand();
    }
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      if (mode == AppMode.chat) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Ask Anything!',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color: isDark ? Colors.white : Colors.black,
              ),
            )
                .animate()
                .fadeIn(duration: 450.ms)
                .slideY(begin: 0.08, curve: Curves.easeOut),
          ),
        );
      }

      final hints = {
        AppMode.grammar: [
          'Check this paragraph for grammar...',
          'Proofread my essay intro...',
          'Fix the writing style here...'
        ],
      };
      final list = hints[mode] ?? [];
      final color = _modeColor();
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Mode glow icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFE2E8F0),
                    width: 1),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                      blurRadius: 28,
                      spreadRadius: 2),
                ],
              ),
              child: Icon(_modeIcon(), color: color, size: 30),
            )
                .animate()
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 22),
            Text(
              _modeTitle(),
              style: AppTextStyles.titleLarge.copyWith(
                color: isDark ? Colors.white : Colors.black,
              ),
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 8),
            Text(
              _modeSubtitle(),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall
                  .copyWith(color: isDark ? Colors.white38 : Colors.black),
            ).animate().fadeIn(delay: 140.ms),
            const SizedBox(height: 32),
            // Suggestion chips
            ...List.generate(
                list.length,
                (i) => GestureDetector(
                      onTap: () => onSuggestionTap(list[i]),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.09)
                                  : const Color(0xFFE2E8F0),
                              width: 1),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(list[i],
                                style: AppTextStyles.labelSmallMuted.copyWith(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.north_east_rounded,
                                size: 13,
                                color: isDark ? Colors.white54 : Colors.black),
                          ),
                        ]),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 180 + i * 70))
                        .slideY(begin: 0.06, curve: Curves.easeOut)),
          ]),
        ),
      );
    });
  }

  Widget _buildPlagSetup() {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final cardBg = isDark ? AppTheme.card : Colors.white;
      final cardBorder = isDark ? AppTheme.border : const Color(0xFFE2E8F0);
      final textColor = isDark ? Colors.white : Colors.black;
      final textMuted = isDark ? Colors.white54 : Colors.black;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Row(children: [
            _tipChip(
                Icons.info_outline_rounded, 'Min 20 words', AppTheme.accent),
            const SizedBox(width: 8),
            _tipChip(Icons.language, 'Any language', AppTheme.success),
          ]).animate().fadeIn(),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: chatController.toggleSourceField,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: showSourceField
                    ? AppTheme.accentSecondary.withValues(alpha: 0.08)
                    : cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: showSourceField
                        ? AppTheme.accentSecondary.withValues(alpha: 0.5)
                        : cardBorder),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Row(children: [
                Icon(Icons.compare_arrows_rounded,
                    color:
                        showSourceField ? AppTheme.accentSecondary : textMuted,
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Compare with Source',
                          style: AppTextStyles.bodySmallW600
                              .copyWith(color: textColor)),
                      Text('Paste original to check against',
                          style: AppTextStyles.captionMuted
                              .copyWith(color: textMuted)),
                    ])),
                Switch(
                    value: showSourceField,
                    onChanged: chatController.setShowSourceField,
                    activeThumbColor: AppTheme.accentSecondary),
              ]),
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 100)),
          if (showSourceField) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.accentSecondary.withValues(alpha: 0.4))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOURCE TEXT',
                        style: AppTextStyles.microSection.copyWith(
                            color: AppTheme.accentSecondary,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: sourceController,
                      maxLines: 5,
                      style: AppTextStyles.captionLarge.copyWith(
                          fontSize: 13, height: 1.6, color: textColor),
                      decoration: InputDecoration(
                          hintText: 'Paste original source here...',
                          hintStyle: AppTextStyles.labelSmallMuted
                              .copyWith(color: textMuted),
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero),
                    ),
                  ]),
            ).animate().fadeIn().slideY(begin: -0.05),
          ],
          const SizedBox(height: 24),
          Text('Paste or type your text below ↓',
                  style:
                      AppTextStyles.labelSmallMuted.copyWith(color: textMuted))
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 200)),
        ]),
      );
    });
  }

  Widget _tipChip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.microNumber
                  .copyWith(fontWeight: FontWeight.w600, color: color)),
        ]),
      );

  Widget _buildBubble(BuildContext context, ChatMessage msg,
      {bool showActions = true}) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;

      if (msg.isUser) {
        final hasFiles = msg.files.isNotEmpty;
        final maxBubbleWidth = MediaQuery.sizeOf(context).width - 88;
        final imageList = msg.persistedImageUrls.isNotEmpty
            ? msg.persistedImageUrls
            : msg.images.map((img) => img.path).toList();
        final hasAnyImages = imageList.isNotEmpty;

        final userBubbleBg =
            isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF1F5F9);
        final userBubbleTextColor = isDark ? Colors.white : Colors.black;

        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 56),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Standalone Attached Images (ChatGPT / Gemini style: outside the prompt bubble)
                  if (hasAnyImages) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: imageList.map((item) {
                        final isRemote = item.startsWith('http://') ||
                            item.startsWith('https://');
                        return GestureDetector(
                          onTap: () => ImageViewerDialog.show(
                            context,
                            imagePathOrUrl: item,
                            caption: msg.text.isNotEmpty ? msg.text : null,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF161618)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.35 : 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          maxBubbleWidth.clamp(1.0, 180.0),
                                      maxHeight: 220,
                                    ),
                                    child: isRemote
                                        ? CachedNetworkImage(
                                            imageUrl: item,
                                            fit: BoxFit.contain,
                                            memCacheWidth: 520,
                                            errorWidget: (_, __, ___) =>
                                                const SizedBox(
                                              width: 84,
                                              height: 84,
                                              child: Icon(
                                                  Icons.broken_image_rounded),
                                            ),
                                          )
                                        : Image.file(
                                            File(item),
                                            fit: BoxFit.contain,
                                            cacheWidth: 520,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                              width: 84,
                                              height: 84,
                                              child: Icon(
                                                  Icons.broken_image_rounded),
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  right: 5,
                                  bottom: 5,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.65),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (msg.text.isNotEmpty || hasFiles)
                      const SizedBox(height: 8),
                  ],

                  // 2. Prompt Text & Files Bubble (Shrink-wraps tightly to text size like ChatGPT)
                  if (msg.text.isNotEmpty || hasFiles)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: userBubbleBg,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(6),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasFiles) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: msg.files
                                  .map(
                                    (f) => _buildMessageFileChip(
                                      f,
                                      maxWidth: maxBubbleWidth - 28,
                                      isDark: isDark,
                                    ),
                                  )
                                  .toList(),
                            ),
                            if (msg.text.isNotEmpty) const SizedBox(height: 8),
                          ],
                          if (msg.text.isNotEmpty)
                            SelectableText(
                              _previewLongUserText(msg.text),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: userBubbleTextColor,
                                height: 1.45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }

      // AI bubble: no container, just avatar and plain text.
      return Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text (skip if image-only with no text)
                  if (msg.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: AssistantMessageText(
                        text: msg.text,
                        isError: msg.isError,
                      ),
                    ),
                  // Generated image
                  if (msg.hasGeneratedImage) ...[
                    if (msg.text.isNotEmpty) const SizedBox(height: 12),
                    GeneratedImageBubble(
                      imageUrl: msg.generatedImageUrl!,
                      imagePrompt: msg.imagePrompt,
                    ),
                  ],
                  // Web research sources / citations
                  if (msg.hasSources) ChatSourcesView(sources: msg.sources),
                  // Action buttons
                  if (msg.isError) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: isLoading ? null : onRetryFailedMessage,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        'Retry',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ] else if (showActions &&
                      !msg.hasGeneratedImage &&
                      msg.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _TextMessageActions(
                      msg: msg,
                      isDark: isDark,
                    ),
                  ] else if (showActions &&
                      msg.hasGeneratedImage &&
                      msg.text.isNotEmpty) ...[
                    // For mixed messages with text: show copy for the text part
                    const SizedBox(height: 10),
                    _msgActionBtn(
                      assetPath: 'assets/icons/copy.png',
                      isDark: isDark,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: msg.text));
                        if (context.mounted) {
                          showTopSnackBar(
                            context,
                            'Copied to clipboard',
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.black,
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMessageFileChip(
    ChatAttachment file, {
    required double maxWidth,
    required bool isDark,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth.clamp(120.0, 240.0)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/paperclip.png',
              width: 14,
              height: 14,
              color: isDark ? Colors.white70 : Colors.black,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionMuted
                    .copyWith(color: isDark ? Colors.white70 : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _previewLongUserText(String text) {
    const maxVisibleCharacters = 2500;
    if (text.length <= maxVisibleCharacters) {
      return text;
    }
    final omitted = text.length - maxVisibleCharacters;
    return '${text.substring(0, maxVisibleCharacters)}\n\n[$omitted more characters attached]';
  }

  Widget _buildImageGeneratingBubble() {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;

      return Padding(
        padding: const EdgeInsets.only(
          bottom: 20,
          right: 16,
        ),
        child: MediaShimmer(
          isDark: isDark,
          label: 'Generating image…',
          subtitle: 'High-quality images may take 1–2 minutes.',
        ),
      );
    });
  }

  Widget _buildMemeGeneratingBubble() {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141416) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800)
                              .withValues(alpha: isDark ? 0.12 : 0.08),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFFF4081)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9800)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.sentiment_very_satisfied_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .scaleXY(
                                begin: 0.92,
                                end: 1.08,
                                duration: 900.ms,
                                curve: Curves.easeInOut,
                              )
                              .then()
                              .scaleXY(
                                begin: 1.08,
                                end: 0.92,
                                duration: 900.ms,
                                curve: Curves.easeInOut,
                              ),
                          const SizedBox(height: 16),
                          Text(
                            'Generating AI Meme…',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Crafting viral humor, meme captions & styling',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                                color: isDark ? Colors.white54 : Colors.black,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTypingBubble() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 18, right: 16),
      child: RepaintBoundary(child: ChatThinkingIndicator()),
    );
  }

  Widget _msgActionBtn({
    required String assetPath,
    required VoidCallback onTap,
    required bool isDark,
    double size = 18,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          color: isDark ? Colors.white70 : Colors.black,
        ),
      ),
    );
  }

  Color _modeColor() => switch (mode) {
        AppMode.plagiarism => AppTheme.accent,
        AppMode.grammar => const Color(0xFF10B981),
        AppMode.chat => const Color(0xFFF59E0B),
        AppMode.home => AppTheme.accent
      };
  IconData _modeIcon() => switch (mode) {
        AppMode.plagiarism => Icons.plagiarism_outlined,
        AppMode.grammar => Icons.spellcheck_rounded,
        AppMode.chat => Icons.chat_bubble_outline_rounded,
        AppMode.home => Icons.auto_awesome_rounded
      };
  String _modeTitle() => switch (mode) {
        AppMode.plagiarism => 'Detect AI',
        AppMode.grammar => 'Grammar Assistant',
        AppMode.chat => 'AI Chat',
        AppMode.home => 'Slipe AI'
      };
  String _modeSubtitle() => switch (mode) {
        AppMode.plagiarism =>
          'Paste or type your text below.\nAI will detect copied content & suspicious patterns.',
        AppMode.grammar =>
          'Paste your text below.\nGet instant grammar, spelling, and style corrections.',
        AppMode.chat => 'Ask me anything.',
        AppMode.home => 'Select a mode to get started.'
      };
}

class _TextMessageActions extends StatefulWidget {
  const _TextMessageActions({
    required this.msg,
    required this.isDark,
  });

  final ChatMessage msg;
  final bool isDark;

  @override
  State<_TextMessageActions> createState() => _TextMessageActionsState();
}

class _TextMessageActionsState extends State<_TextMessageActions> {
  int _feedbackStatus = 0; // 0: none, 1: up, -1: down

  void _showSnack(BuildContext context, String message) {
    showTopSnackBar(
      context,
      message,
      color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.black,
      duration: const Duration(seconds: 2),
    );
  }

  void _submitPositiveFeedback() async {
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'content': widget.msg.text,
        'contentType': 'text',
        'isPositive': true,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (_) {}
  }

  Widget _actionBtn({
    IconData? icon,
    String? assetPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: icon != null
            ? Icon(
                icon,
                size: 18,
                color: widget.isDark ? Colors.white70 : Colors.black,
              )
            : Image.asset(
                assetPath!,
                width: 18,
                height: 18,
                color: widget.isDark ? Colors.white70 : Colors.black,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _actionBtn(
          assetPath: 'assets/icons/copy.png',
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.msg.text));
            if (context.mounted) _showSnack(context, 'Copied to clipboard');
          },
        ),
        const SizedBox(width: 12),
        _actionBtn(
          assetPath: 'assets/icons/share.png',
          onTap: () =>
              SharePlus.instance.share(ShareParams(text: widget.msg.text)),
        ),
        const SizedBox(width: 12),
        _actionBtn(
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
        const SizedBox(width: 12),
        _actionBtn(
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
              contentUrl: '',
              contentPrompt: widget.msg.text,
              contentType: 'text',
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
    );
  }
}
