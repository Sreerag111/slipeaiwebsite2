import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_text_styles.dart';
import '../../../../theme/theme_controller.dart';
import 'image_viewer_dialog.dart';
import 'voice_waveform.dart';
import 'waveform_mic_button.dart';
import '../../domain/entities/app_mode.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/image_aspect_ratio.dart';
import 'image_aspect_ratio_selector.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.mode,
    required this.inputController,
    required this.inputFocus,
    required this.inputScrollController,
    required this.attachBtnKey,
    required this.isLoading,
    required this.isListening,
    required this.recordingDuration,
    required this.attachedImages,
    required this.attachedFiles,
    required this.isUploadingAttachment,
    required this.uploadProgress,
    required this.selectedGenerationMode,
    this.selectedMemeFormat = 'image',
    this.onMemeFormatChanged,
    this.onComingSoon,
    required this.onToggleListening,
    required this.onShowAttachmentSheet,
    required this.onCancelUpload,
    required this.onSubmit,
    required this.onStopActiveRequest,
    required this.onRemoveImageAttachment,
    required this.onRemoveFileAttachment,
    required this.onClearGenerationMode,
    this.imageOnly = false,
    this.imageAspectRatio = ImageAspectRatio.portrait,
    this.onImageAspectRatioSelected,
    required this.hasText,
  });

  final AppMode mode;
  final TextEditingController inputController;
  final FocusNode inputFocus;
  final ScrollController inputScrollController;
  final GlobalKey attachBtnKey;
  final bool isLoading;
  final bool isListening;
  final Duration recordingDuration;
  final List<ChatAttachment> attachedImages;
  final List<ChatAttachment> attachedFiles;
  final bool isUploadingAttachment;
  final double uploadProgress;
  final GenerationMode selectedGenerationMode;
  final String selectedMemeFormat;
  final ValueChanged<String>? onMemeFormatChanged;
  final ValueChanged<String>? onComingSoon;
  final VoidCallback onToggleListening;
  final VoidCallback onShowAttachmentSheet;
  final VoidCallback onCancelUpload;
  final VoidCallback onSubmit;
  final VoidCallback onStopActiveRequest;
  final ValueChanged<ChatAttachment> onRemoveImageAttachment;
  final ValueChanged<ChatAttachment> onRemoveFileAttachment;
  final VoidCallback onClearGenerationMode;
  final bool imageOnly;
  final ImageAspectRatio imageAspectRatio;
  final ValueChanged<ImageAspectRatio>? onImageAspectRatioSelected;
  final bool hasText;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with WidgetsBindingObserver {
  bool _keyboardVisible = false;
  final GlobalKey _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final bottomInset = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom;

    final visible = bottomInset > 0;

    // Keyboard just got dismissed
    if (_keyboardVisible && !visible) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    _keyboardVisible = visible;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final hasAttachments =
        widget.attachedImages.isNotEmpty || widget.attachedFiles.isNotEmpty;
    final showImageRatioToggle = widget.imageOnly &&
        widget.mode == AppMode.home &&
        widget.selectedGenerationMode == GenerationMode.image &&
        !hasAttachments &&
        !widget.isListening &&
        widget.onImageAspectRatioSelected != null;
    final attachmentPreviewHeight =
        (screenHeight * 0.09).clamp(60.0, 76.0).toDouble();
    final textFieldMaxHeight =
        (screenHeight * 0.26).clamp(96.0, 220.0).toDouble();

    final safeScreenWidth = screenWidth.clamp(0.0, double.infinity);
    final containerWidth = widget.imageOnly
        ? double.infinity
        : safeScreenWidth < 360
            ? safeScreenWidth * 0.88
            : safeScreenWidth < 420
                ? safeScreenWidth * 0.86
                : safeScreenWidth * 0.70;

    final isGenerativeMode =
        widget.selectedGenerationMode != GenerationMode.none;
    final useStackedLayout = isGenerativeMode || hasAttachments;

    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final inputBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
      final shadowColor = isDark ? Colors.white : Colors.black;
      final inputShadow = [
        BoxShadow(
          color: shadowColor.withValues(alpha: isDark ? 0.11 : 0.10),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: isDark ? 0.05 : 0.04),
          blurRadius: 3,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];
      final inputTextColor = isDark ? Colors.white : Colors.black;
      final inputHintColor =
          isDark ? Colors.white.withValues(alpha: 0.48) : Colors.black54;

      final sendBtnActiveBg = isDark ? Colors.white : Colors.black;
      final sendBtnInactiveBg =
          isDark ? Colors.white12 : const Color(0xFFE2E8F0);
      final sendBtnActiveIconColor =
          isDark ? const Color(0xFF0D0D0D) : Colors.white;
      final sendBtnInactiveIconColor = isDark ? Colors.white : Colors.black45;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment preview chips (separate container)
          // if (hasAttachments)
          //   Container(
          //     width: containerWidth,
          //     margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          //     decoration: BoxDecoration(
          //       color: inputBg,
          //       borderRadius: BorderRadius.circular(20),
          //       border: inputBorder,
          //       boxShadow: inputShadow,
          //     ),
          //     padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          //     child: SizedBox(
          //       height: attachmentPreviewHeight,
          //       child: ListView(
          //         scrollDirection: Axis.horizontal,
          //         padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          //         children: [
          //           ...widget.attachedImages
          //               .asMap()
          //               .entries
          //               .map((e) => _buildImageChip(e.value, e.key, isDark)),
          //           ...widget.attachedFiles
          //               .asMap()
          //               .entries
          //               .map((e) => _buildFileChip(e.value, e.key, isDark)),
          //         ],
          //       ),
          //     ),
          //   ),
          // const SizedBox(height: 6),
          // // Input container (separate)
          Container(
            width: widget.imageOnly
                ? double.infinity
                : (containerWidth > 0 ? containerWidth : null),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(isGenerativeMode ? 24 : 40),
              boxShadow: inputShadow,
            ),
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasAttachments)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                    child: SizedBox(
                      height: attachmentPreviewHeight,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        children: [
                          ...widget.attachedImages.asMap().entries.map((e) =>
                              _buildImageChip(e.value, e.key, isDark,
                                  attachmentPreviewHeight)),
                          ...widget.attachedFiles.asMap().entries.map((e) =>
                              _buildFileChip(e.value, e.key, isDark,
                                  attachmentPreviewHeight)),
                        ],
                      ),
                    ),
                  ),
                if (widget.isUploadingAttachment)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              value: widget.uploadProgress <= 0
                                  ? null
                                  : widget.uploadProgress,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: widget.onCancelUpload,
                          child: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!widget.imageOnly &&
                    !widget.isListening &&
                    widget.selectedGenerationMode != GenerationMode.none)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 12, 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildGenerationModeChip(isDark),
                    ),
                  ),
                if (useStackedLayout) ...[
                  // ── Stacked layout: text field on top, icon row below ──
                  if (widget.isListening)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: VoiceWaveform(
                        isActive: true,
                        barCount: 18,
                        maxBarHeight: 30,
                        height: 36,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxHeight: textFieldMaxHeight),
                            child: Scrollbar(
                              controller: widget.inputScrollController,
                              thumbVisibility: widget.inputFocus.hasFocus,
                              child: TextField(
                                key: _textFieldKey,
                                controller: widget.inputController,
                                focusNode: widget.inputFocus,
                                scrollController: widget.inputScrollController,
                                minLines: 1,
                                maxLines: widget.selectedGenerationMode !=
                                        GenerationMode.none
                                    ? 1
                                    : null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                scrollPhysics: const ClampingScrollPhysics(),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: inputTextColor,
                                  height: 1.45,
                                ),
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText: _inputHint(),
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: inputHintColor,
                                    height: 1.45,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                              ),
                            ),
                          )),
                          if (showImageRatioToggle) ...[
                            const SizedBox(width: 8),
                            ImageAspectRatioSelector(
                              selected: widget.imageAspectRatio,
                              onSelected: widget.onImageAspectRatioSelected!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      KeyedSubtree(
                        key: widget.attachBtnKey,
                        child: _inputActionBtn(
                          onTap: widget.onShowAttachmentSheet,
                          assetPath: widget.imageOnly
                              ? null
                              : 'assets/icons/paperclip.png',
                          icon: widget.imageOnly
                              ? Icons.add_photo_alternate_outlined
                              : null,
                          size: 20,
                          isDark: isDark,
                        ),
                      ),
                      const Spacer(),
                      if (widget.isListening)
                        _buildMicButton()
                      else ...[
                        if (!widget.imageOnly &&
                            !widget.hasText &&
                            !hasAttachments)
                          _buildMicButton(),
                        const SizedBox(width: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 46,
                          height: 46,
                          margin: const EdgeInsets.only(right: 2, bottom: 2),
                          decoration: BoxDecoration(
                            color: widget.isLoading
                                ? sendBtnActiveBg
                                : (widget.hasText || hasAttachments)
                                    ? sendBtnActiveBg
                                    : sendBtnInactiveBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: isDark ? 0.10 : 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: isDark ? 0.05 : 0.04),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.isLoading
                                  ? widget.onStopActiveRequest
                                  : (widget.hasText || hasAttachments)
                                      ? widget.onSubmit
                                      : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: widget.isLoading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: sendBtnActiveIconColor,
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_upward_rounded,
                                        color:
                                            (widget.hasText || hasAttachments)
                                                ? sendBtnActiveIconColor
                                                : sendBtnInactiveIconColor,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    ],
                  ),
                ] else ...[
                  // ── Old inline layout: attach + textfield + mic/send in one row ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      KeyedSubtree(
                        key: widget.attachBtnKey,
                        child: _inputActionBtn(
                          onTap: widget.onShowAttachmentSheet,
                          assetPath: widget.imageOnly
                              ? null
                              : 'assets/icons/paperclip.png',
                          icon: widget.imageOnly
                              ? Icons.add_photo_alternate_outlined
                              : null,
                          size: 20,
                          isDark: isDark,
                        ),
                      ),
                      if (widget.isListening) ...[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: VoiceWaveform(
                              isActive: true,
                              barCount: 18,
                              maxBarHeight: 30,
                              height: 36,
                            ),
                          ),
                        ),
                        _buildMicButton(),
                      ] else ...[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: textFieldMaxHeight,
                              ),
                              child: Scrollbar(
                                controller: widget.inputScrollController,
                                thumbVisibility: widget.inputFocus.hasFocus,
                                child: TextField(
                                  controller: widget.inputController,
                                  focusNode: widget.inputFocus,
                                  scrollController:
                                      widget.inputScrollController,
                                  minLines: 1,
                                  maxLines: widget.selectedGenerationMode !=
                                          GenerationMode.none
                                      ? 1
                                      : null,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  scrollPhysics: const ClampingScrollPhysics(),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: inputTextColor,
                                    height: 1.45,
                                  ),
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    hintText: _inputHint(),
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: inputHintColor,
                                      height: 1.45,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!widget.imageOnly &&
                            !widget.hasText &&
                            !hasAttachments)
                          _buildMicButton(),
                      ],
                      const SizedBox(width: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 46,
                        height: 46,
                        margin: const EdgeInsets.only(right: 2, bottom: 2),
                        decoration: BoxDecoration(
                          color: widget.isLoading
                              ? sendBtnActiveBg
                              : (widget.hasText || hasAttachments)
                                  ? sendBtnActiveBg
                                  : sendBtnInactiveBg,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: isDark ? 0.12 : 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: isDark ? 0.05 : 0.04),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.isLoading
                                ? widget.onStopActiveRequest
                                : (widget.hasText || hasAttachments)
                                    ? widget.onSubmit
                                    : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Center(
                              child: widget.isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: sendBtnActiveIconColor,
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_upward_rounded,
                                      color: (widget.hasText || hasAttachments)
                                          ? sendBtnActiveIconColor
                                          : sendBtnInactiveIconColor,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildImageChip(
      ChatAttachment file, int index, bool isDark, double size) {
    return GestureDetector(
      onTap: () => ImageViewerDialog.show(
        context,
        imagePathOrUrl: file.path,
        caption: file.name,
      ),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141416) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(
                  File(file.path),
                  fit: BoxFit.cover,
                  cacheWidth: 180,
                  cacheHeight: 180,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.broken_image_rounded,
                        color:
                            isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        size: 20),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => widget.onRemoveImageAttachment(file),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6.0), // Expands tap hit area
                  child: Container(
                    width: 26, // Increased from 20
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2), width: 1),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16,
                        color: Colors.white), // Increased icon from 12
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileChip(
      ChatAttachment file, int index, bool isDark, double size) {
    return Container(
      height: size,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.10 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded,
              size: 22,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.microNumber.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black),
                ),
                Text(
                  file.extension?.toUpperCase() ?? 'FILE',
                  style: AppTextStyles.microAccent.copyWith(
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white38 : Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => widget.onRemoveFileAttachment(file),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6.0), // Expands tap hit area
              child: Container(
                width: 24, // Increased from 18
                height: 24,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    size: 14, // Increased from 11
                    color: isDark ? Colors.white54 : const Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputActionBtn({
    required VoidCallback onTap,
    IconData? icon,
    String? assetPath,
    double size = 20,
    bool active = false,
    Color? activeColor,
    required bool isDark,
  }) {
    final defaultActiveColor = isDark ? Colors.white : Colors.black;
    final effectiveActiveColor = activeColor ?? defaultActiveColor;
    final btnBg = active
        ? effectiveActiveColor.withValues(alpha: 0.14)
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F9));
    final btnIconColor =
        active ? effectiveActiveColor : (isDark ? Colors.white : Colors.black);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: btnBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.10 : 0.08),
              blurRadius: 5,
              offset: const Offset(0, 1.5),
            ),
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.05 : 0.03),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: assetPath != null
              ? Image.asset(
                  assetPath,
                  width: size,
                  height: size,
                  color: btnIconColor,
                )
              : Icon(
                  icon,
                  size: size,
                  color: btnIconColor,
                ),
        ),
      ),
    );
  }

  String _inputHint() {
    if (widget.selectedGenerationMode == GenerationMode.image) {
      return 'Describe your image';
    }
    if (widget.selectedGenerationMode == GenerationMode.meme) {
      return 'Describe your meme';
    }
    return switch (widget.mode) {
      AppMode.plagiarism => 'Paste text to check for plagiarism...',
      AppMode.grammar => 'Paste text to check grammar...',
      AppMode.chat => 'Ask anything...',
      AppMode.home => 'Ask anything...'
    };
  }

  Widget _buildGenerationModeChip(bool isDark) {
    final mode = widget.selectedGenerationMode;
    final label = switch (mode) {
      GenerationMode.image => 'Image',
      GenerationMode.meme => 'Meme',
      _ => '',
    };
    final icon = switch (mode) {
      GenerationMode.image => Icons.image_outlined,
      GenerationMode.meme => Icons.sentiment_satisfied_alt_rounded,
      _ => Icons.help_outline,
    };

    final chipBg =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final iconColor = isDark ? Colors.white70 : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;
    final closeCircleBg = isDark ? Colors.white : Colors.black;
    final closeIconColor = isDark ? Colors.black : Colors.white;

    final modeChip = GestureDetector(
      onTap: widget.onClearGenerationMode,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.07 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.03 : 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            Text(
              label,
              style: AppTextStyles.microNumber.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: closeCircleBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 13, color: closeIconColor),
            ),
          ],
        ),
      ),
    );

    if (mode == GenerationMode.meme) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          modeChip,
          _buildMemeFormatToggle(isDark),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: modeChip,
    );
  }

  Widget _buildMemeFormatToggle(bool isDark) {
    final format = widget.selectedMemeFormat;
    final isImage = format == 'image' ||
        format == 'png' ||
        format == 'jpg' ||
        format.isEmpty;
    final isVideo = format == 'video';
    final isGif = format == 'gif';

    final toggleBg = isDark ? const Color(0xFF141416) : const Color(0xFFF1F5F9);
    final unselectedColor = isDark ? Colors.white60 : Colors.black;
    final unselectedMutedColor = isDark ? Colors.white38 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: toggleBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.07 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.03 : 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. PNG / JPG Image Option (Active & Available)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onMemeFormatChanged?.call('image');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isImage
                    ? const Color(0xFFFF9800).withValues(alpha: 0.92)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_rounded,
                    size: 13,
                    color: isImage ? Colors.black : unselectedColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isImage ? FontWeight.w700 : FontWeight.w500,
                      color: isImage ? Colors.black : unselectedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),

          // 2. Video Option (Disabled / Coming Soon)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onComingSoon?.call('Video memes are coming soon!');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isVideo
                    ? const Color(0xFFFF9800).withValues(alpha: 0.92)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    size: 13,
                    color: isVideo ? Colors.black : unselectedMutedColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Video',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isVideo ? FontWeight.w700 : FontWeight.w500,
                      color: isVideo ? Colors.black : unselectedMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),

          // 3. GIF Option (Disabled / Coming Soon)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onComingSoon?.call('GIF memes are coming soon!');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isGif
                    ? const Color(0xFFFF9800).withValues(alpha: 0.92)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.gif_box_rounded,
                    size: 13,
                    color: isGif ? Colors.black : unselectedMutedColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'GIF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isGif ? FontWeight.w700 : FontWeight.w500,
                      color: isGif ? Colors.black : unselectedMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return WaveformMicButton(
      isListening: widget.isListening,
      onTap: widget.onToggleListening,
      recordingDuration: _formatRecordingDuration(widget.recordingDuration),
    );
  }

  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class UploadPickerSheet extends StatelessWidget {
  const UploadPickerSheet({
    this.imageOnly = false,
    required this.onCancelUpload,
    required this.isUploading,
    required this.progress,
    required this.status,
  });

  final VoidCallback onCancelUpload;
  final bool imageOnly;
  final bool isUploading;
  final double progress;
  final String status;

  @override
  Widget build(BuildContext context) {
    // We want the popup to float above the input bar.
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final paddingBottom = MediaQuery.paddingOf(context).bottom;

    // Approximate height of the input bar so the menu floats right above the paperclip icon
    final bottomOffset = viewInsets + paddingBottom + 90.0;

    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final popupBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
      final popupBorder = isDark
          ? Border.all(color: Colors.white.withValues(alpha: 0.08))
          : Border.all(color: const Color(0xFFE2E8F0));

      return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 16, bottom: bottomOffset),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 250, // Fixed width like ChatGPT's menu
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: popupBg,
                borderRadius: BorderRadius.circular(28),
                border: popupBorder,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UploadPickerRow(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    isDark: isDark,
                    onTap: () => Navigator.pop(context, 'camera'),
                  ),
                  _UploadPickerRow(
                    icon: Icons.photo_outlined,
                    label: 'Gallery',
                    isDark: isDark,
                    onTap: () => Navigator.pop(context, 'gallery'),
                  ),
                  if (!imageOnly)
                    _UploadPickerRow(
                      assetPath: 'assets/icons/paperclip.png',
                      label: 'Files',
                      isDark: isDark,
                      onTap: () => Navigator.pop(context, 'files'),
                    ),
                  // Screen share is exclusive to Companion Mode
                  if (isUploading) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progress <= 0 ? null : progress,
                              minHeight: 4,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation(
                                  isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: onCancelUpload,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                    if (status.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionMuted.copyWith(
                                color: isDark ? Colors.white54 : Colors.black),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            )
                .animate()
                .scaleXY(
                    begin: 0.9,
                    end: 1.0,
                    duration: 150.ms,
                    curve: Curves.easeOutBack)
                .fadeIn(duration: 150.ms),
          ),
        ),
      );
    });
  }
}

class _UploadPickerRow extends StatelessWidget {
  const _UploadPickerRow({
    this.icon,
    this.assetPath,
    required this.label,
    required this.onTap,
    required this.isDark,
  }) : assert(icon != null || assetPath != null);

  final IconData? icon;
  final String? assetPath;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final circleBg =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final iconColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: assetPath != null
                      ? Image.asset(
                          assetPath!,
                          width: 20,
                          height: 20,
                          color: iconColor,
                        )
                      : Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMediumBase.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
