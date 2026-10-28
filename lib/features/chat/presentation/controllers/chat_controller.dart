import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/media_failure.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/review/app_review_service.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';

import '../../domain/entities/app_mode.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_thread.dart';
import '../../domain/entities/plagiarism_result.dart';
import '../../domain/usecases/analyze_plagiarism_use_case.dart';
import '../../domain/usecases/cancel_active_request_use_case.dart';
import '../../domain/usecases/check_grammar_use_case.dart';
import '../../domain/usecases/classify_message_use_case.dart';
import '../../domain/usecases/generate_image_use_case.dart';
import '../../domain/usecases/generate_image_edit_use_case.dart';
import '../../domain/usecases/generate_meme_use_case.dart';
import '../../domain/usecases/get_chat_thread_use_case.dart';
import '../../domain/usecases/load_chat_threads_use_case.dart';
import '../../domain/usecases/save_chat_thread_use_case.dart';
import '../../domain/usecases/send_message_use_case.dart';
import '../../domain/utils/chat_source_extractor.dart';

class ChatSubmissionOutcome {
  const ChatSubmissionOutcome({
    this.plagiarismResult,
    this.analyzedText,
    this.errorMessage,
    this.shouldOpenSettings = false,
    this.wasCancelled = false,
  });

  final PlagiarismResult? plagiarismResult;
  final String? analyzedText;
  final String? errorMessage;
  final bool shouldOpenSettings;
  final bool wasCancelled;
}

class ChatController extends GetxController {
  ChatController({
    required SendMessageUseCase sendMessageUseCase,
    required CheckGrammarUseCase checkGrammarUseCase,
    required AnalyzePlagiarismUseCase analyzePlagiarismUseCase,
    required LoadChatThreadsUseCase loadChatThreadsUseCase,
    required SaveChatThreadUseCase saveChatThreadUseCase,
    required GetChatThreadUseCase getChatThreadUseCase,
    required CancelActiveRequestUseCase cancelActiveRequestUseCase,
    required ClassifyMessageUseCase classifyMessageUseCase,
    required GenerateImageUseCase generateImageUseCase,
    required GenerateImageEditUseCase generateImageEditUseCase,
    required GenerateMemeUseCase generateMemeUseCase,
  })  : _sendMessageUseCase = sendMessageUseCase,
        _checkGrammarUseCase = checkGrammarUseCase,
        _analyzePlagiarismUseCase = analyzePlagiarismUseCase,
        _loadChatThreadsUseCase = loadChatThreadsUseCase,
        _saveChatThreadUseCase = saveChatThreadUseCase,
        _getChatThreadUseCase = getChatThreadUseCase,
        _cancelActiveRequestUseCase = cancelActiveRequestUseCase,
        _classifyMessageUseCase = classifyMessageUseCase,
        _generateImageUseCase = generateImageUseCase,
        _generateImageEditUseCase = generateImageEditUseCase,
        _generateMemeUseCase = generateMemeUseCase;

  final SendMessageUseCase _sendMessageUseCase;
  final CheckGrammarUseCase _checkGrammarUseCase;
  final AnalyzePlagiarismUseCase _analyzePlagiarismUseCase;
  final LoadChatThreadsUseCase _loadChatThreadsUseCase;
  final SaveChatThreadUseCase _saveChatThreadUseCase;
  final GetChatThreadUseCase _getChatThreadUseCase;
  final CancelActiveRequestUseCase _cancelActiveRequestUseCase;
  final ClassifyMessageUseCase _classifyMessageUseCase;
  final GenerateImageUseCase _generateImageUseCase;
  final GenerateImageEditUseCase _generateImageEditUseCase;
  final GenerateMemeUseCase _generateMemeUseCase;

  final Rx<AppMode> mode = AppMode.home.obs;
  final RxBool isLoading = false.obs;
  final RxBool isGeneratingImage = false.obs;
  final RxBool isGeneratingMeme = false.obs;
  final RxString selectedMemeFormat = 'image'.obs; // 'image' | 'video' | 'gif'
  final RxBool showSourceField = false.obs;
  final RxInt wordCount = 0.obs;
  final RxList<ChatMessage> chatMessages = <ChatMessage>[].obs;
  final RxList<ChatAttachment> imageAttachments = <ChatAttachment>[].obs;
  final RxList<ChatAttachment> fileAttachments = <ChatAttachment>[].obs;
  final RxList<ChatThread> chatThreads = <ChatThread>[].obs;
  final RxnString activeConversationId = RxnString();
  final RxString activeThreadTitle = 'New Chat'.obs;
  final RxString sourceText = ''.obs;
  final RxBool isListening = false.obs;
  final RxBool shouldKeepListening = false.obs;
  final RxString voiceTranscript = ''.obs;
  final RxBool isSubmittingVoiceResult = false.obs;
  final Rx<Duration> recordingDuration = Rx<Duration>(Duration.zero);
  final RxInt scrollSignal = 0.obs;
  final Rx<ChatMessage?> streamingMessage = Rx<ChatMessage?>(null);

  static const int _maxDisplayTextCharacters = 2500;
  static const Duration _duplicateSubmitWindow = Duration(milliseconds: 900);

  // Normal conversation should start streaming immediately. Only invoke the
  // remote intent classifier when a typed prompt could reasonably be asking
  // for generated media; explicit action-card modes are routed separately.
  static final RegExp _mediaIntentPattern = RegExp(
    r'\b(image|images|picture|pictures|photo|photos|photograph|photographs|'
    r'illustration|illustrations|artwork|poster|wallpaper|background|logo|'
    r'icon|thumbnail|portrait|headshot|selfie|avatar|banner|flyer|brochure|'
    r'cover art|infographic|graphic|visual|mockup|sticker|video|videos|'
    r'animation|animations|clip|clips|movie|footage|reel|reels|trailer|'
    r'timelapse|meme|memes|gif|gifs|draw|drawing|sketch|paint|painting|'
    r'illustrate|render|visualize|animate)\b',
    caseSensitive: false,
  );
  static final RegExp _possibleCreationCommandPattern = RegExp(
    r'^\s*(please\s+)?((can|could|would|will)\s+you\s+)?'
    r'(create|generate|make|design|edit|transform)\b',
    caseSensitive: false,
  );
  static final RegExp _mediaFollowUpPattern = RegExp(
    r'\b(another|again|same|similar|edit|modify|change|variation|version|'
    r'one more|make it|turn it)\b',
    caseSensitive: false,
  );

  bool _didCancelRequest = false;
  DateTime? _lastSubmitAt;
  String? _lastSubmitFingerprint;
  int _activeRequestId = 0;
  final Map<int, String> _fullPromptCache = <int, String>{};

  List<ChatAttachment> get allAttachments => [
        ...imageAttachments,
        ...fileAttachments,
      ];

  void updateWordCount(String text) {
    final trimmed = text.trim();
    wordCount.value = _countWordsFast(trimmed);
  }

  void setSourceText(String value) {
    sourceText.value = value;
  }

  void setShowSourceField(bool value) {
    showSourceField.value = value;
  }

  void toggleSourceField() {
    showSourceField.value = !showSourceField.value;
  }

  void addImageAttachment({
    required String path,
    required String name,
  }) {
    imageAttachments.add(
      ChatAttachment(
        path: path,
        name: name,
        type: ChatAttachmentType.image,
      ),
    );
  }

  void addFileAttachment({
    required String path,
    required String name,
    String? extension,
  }) {
    fileAttachments.add(
      ChatAttachment(
        path: path,
        name: name,
        extension: extension,
        type: ChatAttachmentType.file,
      ),
    );
  }

  void removeImageAttachment(ChatAttachment attachment) {
    imageAttachments.remove(attachment);
  }

  void removeFileAttachment(ChatAttachment attachment) {
    fileAttachments.remove(attachment);
  }

  void clearAttachments() {
    imageAttachments.clear();
    fileAttachments.clear();
  }

  void clearComposerState() {
    clearAttachments();
    voiceTranscript.value = '';
    recordingDuration.value = Duration.zero;
    wordCount.value = 0;
    showSourceField.value = false;
    sourceText.value = '';
  }

  Future<void> loadChatThreads() async {
    chatThreads.assignAll(await _loadChatThreadsUseCase());
  }

  Future<void> startNewChat({
    AppMode nextMode = AppMode.chat,
    bool clearAttachments = true,
  }) async {
    if (clearAttachments) {
      clearComposerState();
    } else {
      voiceTranscript.value = '';
      recordingDuration.value = Duration.zero;
      wordCount.value = 0;
      showSourceField.value = false;
      sourceText.value = '';
    }
    streamingMessage.value = null;
    activeConversationId.value = _generateConversationId();
    activeThreadTitle.value = 'New Chat';
    chatMessages.clear();
    _fullPromptCache.clear();
    mode.value = nextMode;
    isLoading.value = false;
    isGeneratingImage.value = false;
    isGeneratingMeme.value = false;
    _emitScrollSignal();
  }

  Future<void> returnToHome() async {
    clearComposerState();
    streamingMessage.value = null;
    mode.value = AppMode.home;
    activeConversationId.value = null;
    activeThreadTitle.value = 'New Chat';
    chatMessages.clear();
    _fullPromptCache.clear();
    isLoading.value = false;
    isGeneratingImage.value = false;
    isGeneratingMeme.value = false;
    _emitScrollSignal();
  }

  Future<void> openThread(ChatThread thread) async {
    clearComposerState();
    streamingMessage.value = null;
    activeConversationId.value = thread.conversationId;
    activeThreadTitle.value = thread.title;
    mode.value = thread.mode;
    chatMessages.assignAll(thread.messages);
    _fullPromptCache.clear();
    _emitScrollSignal();
  }

  void setSelectedMemeFormat(String format) {
    selectedMemeFormat.value = format;
  }

  Future<void> loadAndOpenThread(String conversationId) async {
    final thread = await _getChatThreadUseCase(conversationId);
    if (thread != null) {
      openThread(thread);
    }
    // Refresh the drawer history to include recent companion chats
    loadChatThreads();
  }

  void setListening(bool value) {
    isListening.value = value;
  }

  void setShouldKeepListening(bool value) {
    shouldKeepListening.value = value;
  }

  void setVoiceTranscript(String value) {
    voiceTranscript.value = value;
  }

  void setSubmittingVoiceResult(bool value) {
    isSubmittingVoiceResult.value = value;
  }

  void setRecordingDuration(Duration value) {
    recordingDuration.value = value;
  }

  void incrementRecordingDuration() {
    recordingDuration.value =
        recordingDuration.value + const Duration(seconds: 1);
  }

  Future<ChatSubmissionOutcome> submit({
    required String baseText,
    String? currentSourceText,
    GenerationMode generationMode = GenerationMode.none,
    String? imageSize,
    String? imagePromptInstruction,
  }) async {
    final trimmedText = baseText.trim();
    if (trimmedText.isEmpty && allAttachments.isEmpty) {
      return const ChatSubmissionOutcome();
    }

    if (isLoading.value) {
      return const ChatSubmissionOutcome(
        errorMessage: 'Please wait for the current response to finish.',
      );
    }

    final fingerprint = _submissionFingerprint(trimmedText);
    final now = DateTime.now();
    if (_lastSubmitFingerprint == fingerprint &&
        _lastSubmitAt != null &&
        now.difference(_lastSubmitAt!) < _duplicateSubmitWindow) {
      return const ChatSubmissionOutcome();
    }
    _lastSubmitFingerprint = fingerprint;
    _lastSubmitAt = now;

    final premiumController = Get.find<PremiumController>();
    // Explicit image creation is governed by its own image allowance. Do not
    // let an exhausted text-chat allowance hide the image-limit reward flow.
    if (generationMode != GenerationMode.image &&
        !premiumController.canSendChat()) {
      return const ChatSubmissionOutcome(errorMessage: 'CHAT_LIMIT_REACHED');
    }

    _didCancelRequest = false;
    final requestId = ++_activeRequestId;
    final currentMode = mode.value == AppMode.home ? AppMode.chat : mode.value;
    if (currentMode == AppMode.chat) {
      mode.value = AppMode.chat;
      activeConversationId.value ??= _generateConversationId();
    } else if (activeConversationId.value == null) {
      activeConversationId.value = _generateConversationId();
    }

    final attachmentsSnapshot = allAttachments.toList(growable: false);
    final createdAt = DateTime.now();
    final apiUserMessage = ChatMessage(
      text: trimmedText,
      isUser: true,
      attachments: attachmentsSnapshot,
      createdAt: createdAt,
    );
    final displayUserMessage = ChatMessage(
      text: _displayTextForUser(trimmedText, attachmentsSnapshot),
      isUser: true,
      attachments: attachmentsSnapshot,
      createdAt: createdAt,
    );
    if (displayUserMessage.text != trimmedText) {
      _fullPromptCache[createdAt.microsecondsSinceEpoch] = trimmedText;
    }
    final previousMessages = chatMessages.toList(growable: false);

    isLoading.value = true;
    clearAttachments();
    if (currentMode != AppMode.plagiarism) {
      chatMessages.add(displayUserMessage);
    }

    _emitScrollSignal();

    // Upload user-attached images to Firebase Storage in the background
    // so they persist permanently in the chat. We do this AFTER displaying
    // the message (using local paths) so the UI feels instant.
    if (attachmentsSnapshot.any((a) => a.isImage)) {
      _uploadAttachmentsInBackground(
        attachmentsSnapshot: attachmentsSnapshot,
        displayMessage: displayUserMessage,
      );
    }

    try {
      switch (currentMode) {
        case AppMode.plagiarism:
          final result = await _analyzePlagiarismUseCase(
            message: apiUserMessage,
            sourceText: currentSourceText ?? '',
          );
          if (_isStaleRequest(requestId)) {
            return const ChatSubmissionOutcome(wasCancelled: true);
          }
          return ChatSubmissionOutcome(
            plagiarismResult: result.result,
            analyzedText: result.analyzedText,
          );
        case AppMode.grammar:
          final result = await _checkGrammarUseCase(
            message: apiUserMessage,
            conversationId: activeConversationId.value,
          );
          if (_isStaleRequest(requestId)) {
            return const ChatSubmissionOutcome(wasCancelled: true);
          }
          final response = _requireNonEmptyResponse(result.response);
          final extracted = ChatSourceExtractor.extract(response);
          chatMessages.add(
            ChatMessage(
              text: extracted.cleanedText,
              sources: extracted.sources,
              isUser: false,
              mode: AppMode.grammar,
              animate: true,
              createdAt: DateTime.now(),
            ),
          );
          AppHaptics.responseCompleted();
          await premiumController.incrementChatCount();
          await _persistCurrentThread(preferredTitle: trimmedText);
          _emitScrollSignal();
          return const ChatSubmissionOutcome();
        case AppMode.home:
        case AppMode.chat:
          await _classifyAndRespond(
            requestId: requestId,
            apiUserMessage: apiUserMessage,
            trimmedText: trimmedText,
            previousMessages: previousMessages,
            explicitMode: generationMode,
            imageSize: imageSize,
            imagePromptInstruction: imagePromptInstruction,
          );
          return const ChatSubmissionOutcome();
      }
    } catch (error) {
      if (_didCancelRequest || _isStaleRequest(requestId)) {
        return const ChatSubmissionOutcome(wasCancelled: true);
      }

      final message = _normalizeError(error);
      if (currentMode == AppMode.chat || currentMode == AppMode.grammar) {
        chatMessages.add(
          ChatMessage(
            text: 'Error: $message',
            isUser: false,
            isError: true,
            createdAt: DateTime.now(),
          ),
        );
        _emitScrollSignal();
      }
      return ChatSubmissionOutcome(errorMessage: message);
    } finally {
      if (!_isStaleRequest(requestId)) {
        isLoading.value = false;
        isGeneratingImage.value = false;
        isGeneratingMeme.value = false;
        _emitScrollSignal();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Classification → routing
  // ---------------------------------------------------------------------------

  Future<void> _classifyAndRespond({
    required int requestId,
    required ChatMessage apiUserMessage,
    required String trimmedText,
    required List<ChatMessage> previousMessages,
    GenerationMode explicitMode = GenerationMode.none,
    String? imageSize,
    String? imagePromptInstruction,
  }) async {
    // If the user explicitly tapped an action card, route directly without LLM classification
    if (explicitMode == GenerationMode.meme) {
      await _generateAndAppendMeme(
        requestId: requestId,
        memePrompt: trimmedText,
        trimmedText: trimmedText,
        attachments: apiUserMessage.attachments,
        previousMessages: previousMessages,
      );
      return;
    } else if (explicitMode == GenerationMode.image) {
      await _generateAndAppendImage(
        requestId: requestId,
        imagePrompt: imagePromptInstruction == null
            ? trimmedText
            : '$trimmedText\n\n$imagePromptInstruction',
        imageSize: imageSize,
        textContent: '',
        trimmedText: trimmedText,
        attachments: apiUserMessage.attachments,
        previousMessages: previousMessages,
      );
      return;
    }

    // Avoid an extra Cloud Function + model round trip for ordinary chat.
    // Image attachments still need classification because the request may be
    // asking either a question about the image or for an image transformation.
    final mayRequestMedia = _mayRequestGeneratedMedia(
      message: apiUserMessage,
      text: trimmedText,
      previousMessages: previousMessages,
    );
    if (!mayRequestMedia) {
      await _streamChatResponse(
        requestId: requestId,
        apiUserMessage: apiUserMessage,
        trimmedText: trimmedText,
        previousMessages: previousMessages,
      );
      return;
    }

    // Step 1: classify the user's intent.
    final classification = await _classifyMessageUseCase(
      message: trimmedText,
      history: previousMessages,
    );

    if (kDebugMode)
      debugPrint(
        '[MemeCreation/ChatController] Classification result: '
        'isMeme=${classification.isMeme}, isImage=${classification.isImage}',
      );

    if (_isStaleRequest(requestId)) return;

    if (classification.isMeme) {
      // AI Meme generation via Veo 3.1 & Gemini
      await _generateAndAppendMeme(
        requestId: requestId,
        memePrompt: classification.memePrompt.isNotEmpty
            ? classification.memePrompt
            : trimmedText,
        trimmedText: trimmedText,
        attachments: apiUserMessage.attachments,
        previousMessages: previousMessages,
      );
    } else if (classification.isImage) {
      // Pure image response — no text stream.
      await _generateAndAppendImage(
        requestId: requestId,
        imagePrompt: classification.imagePrompt.isNotEmpty
            ? classification.imagePrompt
            : trimmedText,
        textContent: '',
        trimmedText: trimmedText,
        attachments: apiUserMessage.attachments,
        previousMessages: previousMessages,
      );
    } else if (classification.isMixed) {
      // Text + image — run both in parallel.
      await _streamChatAndImage(
        requestId: requestId,
        apiUserMessage: apiUserMessage,
        trimmedText: trimmedText,
        previousMessages: previousMessages,
        imagePrompt: classification.imagePrompt.isNotEmpty
            ? classification.imagePrompt
            : trimmedText,
        classificationText: classification.text,
      );
    } else {
      // Plain text — existing streaming pipeline.
      await _streamChatResponse(
        requestId: requestId,
        apiUserMessage: apiUserMessage,
        trimmedText: trimmedText,
        previousMessages: previousMessages,
      );
    }
  }

  bool _mayRequestGeneratedMedia({
    required ChatMessage message,
    required String text,
    required List<ChatMessage> previousMessages,
  }) {
    if (message.attachments.any((attachment) => attachment.isImage) ||
        _mediaIntentPattern.hasMatch(text) ||
        _possibleCreationCommandPattern.hasMatch(text)) {
      return true;
    }

    final recentMedia = previousMessages.reversed
        .take(4)
        .any((item) => item.hasGeneratedImage || item.hasGeneratedVideo);
    return recentMedia && _mediaFollowUpPattern.hasMatch(text);
  }

  Future<void> _streamChatAndImage({
    required int requestId,
    required ChatMessage apiUserMessage,
    required String trimmedText,
    required List<ChatMessage> previousMessages,
    required String imagePrompt,
    required String classificationText,
  }) async {
    // Start text streaming and image generation concurrently.
    await Future.wait([
      _streamChatResponse(
        requestId: requestId,
        apiUserMessage: apiUserMessage,
        trimmedText: trimmedText,
        previousMessages: previousMessages,
      ),
      _generateAndAppendImage(
        requestId: requestId,
        imagePrompt: imagePrompt,
        textContent: classificationText,
        trimmedText: trimmedText,
        standalone: false,
        attachments: apiUserMessage.attachments,
        previousMessages: previousMessages,
      ),
    ]);
    return;
  }

  /// Uploads user-attached image files to Firebase Storage in the background
  /// after the message has been displayed. On completion, replaces the local
  /// file path reference with permanent Firebase Storage URLs so the photo
  /// persists across sessions.
  void _uploadAttachmentsInBackground({
    required List<ChatAttachment> attachmentsSnapshot,
    required ChatMessage displayMessage,
  }) {
    Future.microtask(() async {
      try {
        final imageFiles = attachmentsSnapshot.where((a) => a.isImage).toList();
        if (imageFiles.isEmpty) return;

        final urls = <String>[];
        for (final attachment in imageFiles) {
          try {
            final file = File(attachment.path);
            if (!await file.exists()) continue;
            final bytes = await file.readAsBytes();
            final ext = attachment.extension?.replaceAll('.', '') ?? 'jpg';
            final contentType = 'image/$ext';
            final url = await _generateImageEditUseCase.uploadAttachment(
              bytes: bytes,
              filename:
                  attachment.name.isNotEmpty ? attachment.name : 'photo.$ext',
              contentType: contentType,
            );
            if (url.isNotEmpty) {
              urls.add(url);
              debugPrint('[ChatController] Attachment uploaded: $url');
            }
          } catch (e) {
            debugPrint('[ChatController] Failed to upload attachment: $e');
          }
        }

        if (urls.isEmpty) return;

        // Find the displayed message in the list and patch it with persisted URLs
        final idx = chatMessages.indexWhere(
          (m) => m.isUser && m.createdAt == displayMessage.createdAt,
        );
        if (idx >= 0) {
          chatMessages[idx] = chatMessages[idx].copyWithPersistedUrls(urls);
          debugPrint(
              '[ChatController] User message patched with ${urls.length} persisted URLs');
          await _persistCurrentThread();
        }
      } catch (e) {
        debugPrint('[ChatController] _uploadAttachmentsInBackground error: $e');
      }
    });
  }

  List<Map<String, dynamic>> _buildRecentHistoryContext(
    List<ChatMessage> previousMessages, {
    int maxTurns = 10,
  }) {
    final history = <Map<String, dynamic>>[];
    final nonError = previousMessages.where((m) => !m.isError).toList();
    final window = nonError.length > maxTurns
        ? nonError.sublist(nonError.length - maxTurns)
        : nonError;

    for (final msg in window) {
      if (msg.isUser) {
        final text = msg.text.trim();
        if (text.isNotEmpty) {
          history.add({'role': 'user', 'content': text});
        }
      } else {
        String content = msg.text.trim();
        if (content.isEmpty) {
          if (msg.hasGeneratedImage &&
              msg.imagePrompt != null &&
              msg.imagePrompt!.isNotEmpty) {
            content = '[Generated Image: "${msg.imagePrompt}"]';
          } else if (msg.hasGeneratedVideo &&
              msg.videoPrompt != null &&
              msg.videoPrompt!.isNotEmpty) {
            content = '[Generated Video: "${msg.videoPrompt}"]';
          }
        }
        if (content.isNotEmpty) {
          history.add({'role': 'assistant', 'content': content});
        }
      }
    }
    return history;
  }

  Future<void> _generateAndAppendImage({
    required int requestId,
    required String imagePrompt,
    required String textContent,
    required String trimmedText,
    String? imageSize,
    bool standalone = true,
    List<ChatAttachment> attachments = const [],
    List<ChatMessage> previousMessages = const [],
  }) async {
    if (imagePrompt.isEmpty) return;

    final premiumController = Get.find<PremiumController>();
    if (!premiumController.canGenerateImage()) {
      throw const AppException('IMAGE_LIMIT_REACHED');
    }

    isGeneratingImage.value = true;
    _emitScrollSignal();

    final chatHistory = _buildRecentHistoryContext(previousMessages);
    final imgAttachList = attachments.isNotEmpty
        ? attachments.where((a) => a.isImage).toList()
        : imageAttachments.toList();

    if (kDebugMode) debugPrint('[ImagePrompt] started requestId=$requestId');
    String? priorImageUrl;
    for (final msg in previousMessages.reversed) {
      if (msg.generatedImageUrl != null && msg.generatedImageUrl!.isNotEmpty) {
        priorImageUrl = msg.generatedImageUrl;
        break;
      }
      if (msg.persistedImageUrls.isNotEmpty) {
        priorImageUrl = msg.persistedImageUrls.first;
        break;
      }
      if (msg.attachments.isNotEmpty) {
        for (final att in msg.attachments) {
          if (att.isImage && att.path.isNotEmpty) {
            priorImageUrl = att.path;
            break;
          }
        }
        if (priorImageUrl != null) break;
      }
    }

    if (kDebugMode)
      debugPrint('[ImagePrompt] context '
          'hasAttachment=${imgAttachList.isNotEmpty} '
          'hasPriorImage=${priorImageUrl != null} historyTurns=${chatHistory.length}');

    try {
      // If the user attached a photo, use the image EDIT API so the actual
      // uploaded photo is sent to OpenAI and the AI edits/transforms it.
      // Otherwise fall back to text-to-image generation with prior image context.
      String imageUrl;
      final editInstruction =
          trimmedText.isNotEmpty ? trimmedText : imagePrompt;

      if (imgAttachList.isNotEmpty) {
        final hasReferencePair = imgAttachList.length >= 2;
        final userImg = hasReferencePair ? imgAttachList[1] : imgAttachList.first;
        final refImg = hasReferencePair ? imgAttachList.first : null;

        final file = File(userImg.path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final base64Str = base64Encode(bytes);
          final ext = userImg.extension?.replaceAll('.', '') ?? 'jpeg';
          final mimeType = 'image/$ext';

          String? refBase64Str;
          String? refMimeType;
          if (refImg != null) {
            final rFile = File(refImg.path);
            if (await rFile.exists()) {
              final rBytes = await rFile.readAsBytes();
              refBase64Str = base64Encode(rBytes);
              final rExt = refImg.extension?.replaceAll('.', '') ?? 'png';
              refMimeType = 'image/$rExt';
            }
          }

          if (kDebugMode) {
            debugPrint(
              '[ImageEdit][ChatController] using uploaded photo '
              '(hasRef=${refBase64Str != null})',
            );
          }
          imageUrl = await _generateImageEditUseCase(
            prompt: editInstruction,
            imageBase64: base64Str,
            referenceImageBase64: refBase64Str,
            referenceMimeType: refMimeType,
            mimeType: mimeType,
            chatHistory: chatHistory,
          );
        } else {
          imageUrl = await _generateImageUseCase(
            prompt: imagePrompt,
            size: imageSize,
            chatHistory: chatHistory,
            imageUrl: priorImageUrl,
          );
        }
      } else if (priorImageUrl != null && priorImageUrl.isNotEmpty) {
        if (kDebugMode)
          debugPrint('[ImageEdit][ChatController] using prior image');
        imageUrl = await _generateImageEditUseCase(
          prompt: editInstruction,
          imageUrl: priorImageUrl,
          chatHistory: chatHistory,
        );
      } else {
        imageUrl = await _generateImageUseCase(
          prompt: imagePrompt,
          size: imageSize,
          chatHistory: chatHistory,
        );
      }

      if (_isStaleRequest(requestId)) return;

      if (kDebugMode) debugPrint('[ImagePrompt] generation succeeded');

      await premiumController.incrementImageCount();

      chatMessages.add(
        ChatMessage(
          text: textContent,
          isUser: false,
          animate: true,
          createdAt: DateTime.now(),
          generatedImageUrl: imageUrl,
          imagePrompt: imagePrompt,
        ),
      );
      AppHaptics.success();
      unawaited(AppReviewService.instance.onFeatureCompleted(Get.context));

      if (standalone) {
        await _persistCurrentThread(preferredTitle: trimmedText);
      }
      _emitScrollSignal();
    } catch (error) {
      if (_isStaleRequest(requestId)) return;

      final rawMessage = _normalizeError(error);
      if (rawMessage.contains('free image limit') ||
          rawMessage.contains('IMAGE_LIMIT_REACHED')) {
        throw const AppException('IMAGE_LIMIT_REACHED');
      }
      final message =
          MediaFailure.message(error, media: 'image', action: 'create');
      if (kDebugMode)
        debugPrint('[ImagePrompt] generation failed type=${error.runtimeType}');
      AppHaptics.error();

      chatMessages.add(
        ChatMessage(
          text: 'Error: $message',
          isUser: false,
          isError: true,
          createdAt: DateTime.now(),
        ),
      );
      if (standalone) {
        await _persistCurrentThread(preferredTitle: trimmedText);
      }
      _emitScrollSignal();
    } finally {
      isGeneratingImage.value = false;
    }
  }

  Future<void> _generateAndAppendMeme({
    required int requestId,
    required String memePrompt,
    required String trimmedText,
    List<ChatAttachment> attachments = const [],
    String? format,
    List<ChatMessage> previousMessages = const [],
  }) async {
    isGeneratingMeme.value = true;
    _emitScrollSignal();

    final chosenFormat = format ?? selectedMemeFormat.value;
    if (kDebugMode)
      debugPrint(
        '[MemeCreation][ChatController] starting format=$chosenFormat '
        'attachments=${attachments.length}',
      );

    final chatHistory = _buildRecentHistoryContext(previousMessages);

    try {
      String? imageBase64;
      String? mimeType;

      // Find first image attachment if available
      final imgAttachment = attachments.firstWhereOrNull(
            (a) =>
                a.isImage ||
                a.path.toLowerCase().endsWith('.png') ||
                a.path.toLowerCase().endsWith('.jpg') ||
                a.path.toLowerCase().endsWith('.jpeg') ||
                a.path.toLowerCase().endsWith('.webp'),
          ) ??
          imageAttachments.firstOrNull;

      if (imgAttachment != null && imgAttachment.path.isNotEmpty) {
        final file = File(imgAttachment.path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          imageBase64 = base64Encode(bytes);
          final ext = imgAttachment.extension?.replaceAll('.', '') ?? 'jpeg';
          mimeType = 'image/$ext';
          debugPrint(
              '[MemeCreation][ChatController] Attached image encoded, size: ${bytes.length} bytes');
        }
      }

      Map<String, dynamic> meme;
      try {
        meme = await _generateMemeUseCase(
          prompt: memePrompt,
          imageBase64: imageBase64,
          mimeType: mimeType,
          format: chosenFormat,
          chatHistory: chatHistory,
        );
      } catch (backendError) {
        if (kDebugMode)
          debugPrint(
            '[MemeCreation][ChatController] backend failed '
            'type=${backendError.runtimeType}; checking fallback',
          );
        final isImageFormat = chosenFormat == 'image' ||
            chosenFormat == 'png' ||
            chosenFormat == 'jpg';

        if (isImageFormat) {
          String fallbackUrl;
          if (imageBase64 != null && imageBase64.isNotEmpty) {
            final editInstruction =
                'Transform this reference image into a viral, hilarious social media meme based on: $memePrompt. Add a bold meme caption header at the top. CRITICAL: Exactly preserve the person\'s face, facial features, and identity.';
            fallbackUrl = await _generateImageEditUseCase(
              prompt: editInstruction,
              imageBase64: imageBase64,
              mimeType: mimeType ?? 'image/jpeg',
              chatHistory: chatHistory,
            );
          } else {
            fallbackUrl = await _generateImageUseCase(
              prompt:
                  'A viral, hilarious social media meme with bold top caption: $memePrompt',
              chatHistory: chatHistory,
            );
          }
          meme = {
            'imageUrl': fallbackUrl,
            'format': 'image',
            'success': true,
          };
        } else {
          rethrow;
        }
      }

      if (_isStaleRequest(requestId)) return;

      final memeImageUrl = (meme['imageUrl'] ?? '').toString();
      final memeVideoUrl = (meme['videoUrl'] ?? '').toString();
      final memeFormat = (meme['format'] ?? chosenFormat).toString();
      final memeDuration = meme['duration'] is int
          ? meme['duration'] as int
          : int.tryParse(meme['duration']?.toString() ?? '') ?? 5;

      if (kDebugMode)
        debugPrint(
          '[MemeCreation][ChatController] generated format=$memeFormat',
        );

      final isImage = memeFormat == 'image' ||
          memeFormat == 'png' ||
          memeFormat == 'jpg' ||
          chosenFormat == 'image';
      final isGif = memeFormat == 'gif' || chosenFormat == 'gif';
      final mediaUrl = memeVideoUrl.isNotEmpty ? memeVideoUrl : memeImageUrl;

      chatMessages.add(
        ChatMessage(
          text: '', // No caption shown — only the generated media
          isUser: false,
          createdAt: DateTime.now(),
          animate: true,
          generatedImageUrl: (isImage || isGif) ? mediaUrl : null,
          generatedVideoUrl: (isImage || isGif)
              ? null
              : (memeVideoUrl.isNotEmpty ? memeVideoUrl : null),
          imagePrompt: memePrompt,
          videoPrompt: (isImage || isGif) ? null : memePrompt,
          videoDuration: memeDuration,
        ),
      );

      await _persistCurrentThread(
        preferredTitle: trimmedText,
      );
      AppHaptics.success();
      unawaited(AppReviewService.instance.onFeatureCompleted(Get.context));
      _emitScrollSignal();
    } catch (error) {
      if (_isStaleRequest(requestId)) {
        if (kDebugMode)
          debugPrint(
              '[MemeCreation][ChatController] stale request error ignored');
        return;
      }

      final message =
          MediaFailure.message(error, media: 'meme', action: 'create');
      if (kDebugMode)
        debugPrint(
            '[MemeCreation][ChatController] generation failed type=${error.runtimeType}');
      AppHaptics.error();

      chatMessages.add(
        ChatMessage(
          text: 'Meme Generation Error: $message',
          isUser: false,
          isError: true,
          createdAt: DateTime.now(),
        ),
      );
      await _persistCurrentThread(preferredTitle: trimmedText);
      _emitScrollSignal();
    } finally {
      isGeneratingMeme.value = false;
      debugPrint(
          '[MemeCreation][ChatController] isGeneratingMeme set to false');
    }
  }

  Future<void> _streamChatResponse({
    required int requestId,
    required ChatMessage apiUserMessage,
    required String trimmedText,
    required List<ChatMessage> previousMessages,
  }) async {
    final buffer = StringBuffer();
    final createdAt = DateTime.now();

    streamingMessage.value = ChatMessage(
      text: '',
      isUser: false,
      createdAt: createdAt,
    );
    _emitScrollSignal();

    try {
      await for (final chunk in _sendMessageUseCase.callStreaming(
        messages: <ChatMessage>[
          ...previousMessages.where((m) => !m.isError),
          apiUserMessage,
        ],
      )) {
        if (_isStaleRequest(requestId)) return;

        buffer.write(chunk);
        streamingMessage.value = ChatMessage(
          text: buffer.toString(),
          isUser: false,
          createdAt: createdAt,
        );
      }

      if (_isStaleRequest(requestId)) return;

      final response = buffer.toString().trim();
      streamingMessage.value = null;

      if (response.isEmpty) {
        throw const AppException(
          'The AI returned an empty response. Please try again with a shorter file or prompt.',
        );
      }

      final extracted = ChatSourceExtractor.extract(response);

      chatMessages.add(
        ChatMessage(
          text: extracted.cleanedText,
          sources: extracted.sources,
          isUser: false,
          animate: true,
          createdAt: createdAt,
        ),
      );

      AppHaptics.responseCompleted();

      await Get.find<PremiumController>().incrementChatCount();
      await _persistCurrentThread(preferredTitle: trimmedText);
      _emitScrollSignal();
    } catch (error) {
      streamingMessage.value = null;
      if (_didCancelRequest || _isStaleRequest(requestId)) return;

      final message = _normalizeError(error);
      if (message.contains('free chat limit')) {
        throw const AppException('CHAT_LIMIT_REACHED');
      }
      AppHaptics.error();
      chatMessages.add(
        ChatMessage(
          text: 'Error: $message',
          isUser: false,
          isError: true,
          createdAt: DateTime.now(),
        ),
      );
      await _persistCurrentThread(preferredTitle: trimmedText);
      _emitScrollSignal();
    }
  }

  Future<ChatSubmissionOutcome> retryLastFailedMessage() async {
    if (isLoading.value) {
      return const ChatSubmissionOutcome(
        errorMessage: 'Please wait for the current response to finish.',
      );
    }
    if (chatMessages.isEmpty || !chatMessages.last.isError) {
      return const ChatSubmissionOutcome();
    }

    ChatMessage? retryMessage;
    for (final message in chatMessages.reversed) {
      if (message.isUser) {
        retryMessage = message;
        break;
      }
    }
    if (retryMessage == null) {
      return const ChatSubmissionOutcome();
    }

    final premiumController = Get.find<PremiumController>();
    if (!premiumController.canSendChat()) {
      return const ChatSubmissionOutcome(errorMessage: 'CHAT_LIMIT_REACHED');
    }

    _didCancelRequest = false;
    final requestId = ++_activeRequestId;
    chatMessages.removeLast();
    isLoading.value = true;
    _emitScrollSignal();
    final apiRetryMessage = _hydrateFullPrompt(retryMessage);

    try {
      final currentMode =
          mode.value == AppMode.home ? AppMode.chat : mode.value;
      if (currentMode == AppMode.grammar) {
        final result = await _checkGrammarUseCase(
          message: apiRetryMessage,
          conversationId: activeConversationId.value,
        );
        if (_isStaleRequest(requestId)) {
          return const ChatSubmissionOutcome(wasCancelled: true);
        }
        final response = _requireNonEmptyResponse(result.response);
        chatMessages.add(
          ChatMessage(
            text: response,
            isUser: false,
            mode: AppMode.grammar,
            animate: true,
            createdAt: DateTime.now(),
          ),
        );
        AppHaptics.responseCompleted();
        await premiumController.incrementChatCount();
      } else {
        final result = await _sendMessageUseCase(
          messages: <ChatMessage>[
            ...chatMessages.where(
                (message) => !message.isError && message != retryMessage),
            apiRetryMessage,
          ],
          conversationId: activeConversationId.value,
        );
        if (_isStaleRequest(requestId)) {
          return const ChatSubmissionOutcome(wasCancelled: true);
        }
        final response = _requireNonEmptyResponse(result.response);
        chatMessages.add(
          ChatMessage(
            text: response,
            isUser: false,
            animate: true,
            createdAt: DateTime.now(),
          ),
        );
        AppHaptics.responseCompleted();
        await premiumController.incrementChatCount();
      }

      await _persistCurrentThread(preferredTitle: retryMessage.text);
      _emitScrollSignal();
      return const ChatSubmissionOutcome();
    } catch (error) {
      if (_didCancelRequest || _isStaleRequest(requestId)) {
        return const ChatSubmissionOutcome(wasCancelled: true);
      }
      final message = _normalizeError(error);

      AppHaptics.error();

      chatMessages.add(
        ChatMessage(
          text: 'Error: $message',
          isUser: false,
          isError: true,
          createdAt: DateTime.now(),
        ),
      );
      _emitScrollSignal();
      return ChatSubmissionOutcome(errorMessage: message);
    } finally {
      if (!_isStaleRequest(requestId)) {
        isLoading.value = false;
        isGeneratingImage.value = false;
        isGeneratingMeme.value = false;
        _emitScrollSignal();
      }
    }
  }

  void cancelActiveRequest() {
    AppHaptics.warning();

    _didCancelRequest = true;
    _activeRequestId++;
    streamingMessage.value = null;
    isGeneratingImage.value = false;
    isGeneratingMeme.value = false;
    _cancelActiveRequestUseCase();
    isLoading.value = false;
    _emitScrollSignal();
  }

  Future<void> _persistCurrentThread({String? preferredTitle}) async {
    if (chatMessages.isEmpty) {
      return;
    }

    final threadId = activeConversationId.value ?? _generateConversationId();
    String firstUserText = '';
    for (final message in chatMessages) {
      if (message.isUser && message.text.trim().isNotEmpty) {
        firstUserText = message.text.trim();
        break;
      }
    }
    final rawTitle =
        (preferredTitle != null && preferredTitle.trim().isNotEmpty)
            ? preferredTitle.trim()
            : (firstUserText.isEmpty
                ? activeThreadTitle.value
                : firstUserText.split('\n').first);
    final title =
        rawTitle.length > 42 ? '${rawTitle.substring(0, 42)}...' : rawTitle;

    final thread = ChatThread(
      conversationId: threadId,
      title: title,
      mode: mode.value == AppMode.home ? AppMode.chat : mode.value,
      updatedAt: DateTime.now().toIso8601String(),
      messages: chatMessages.toList(growable: false),
    );

    await _saveChatThreadUseCase(thread);
    activeConversationId.value = threadId;
    activeThreadTitle.value = title;
    await loadChatThreads();
  }

  void _emitScrollSignal() {
    scrollSignal.value++;
  }

  bool _isStaleRequest(int requestId) => requestId != _activeRequestId;

  String _generateConversationId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  String _submissionFingerprint(String text) {
    final attachmentNames = allAttachments.map((item) => item.name).join('|');
    return '${mode.value.index}:${text.length}:${text.hashCode}:$attachmentNames';
  }

  String _normalizeError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _requireNonEmptyResponse(String response) {
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      throw const AppException(
        'The AI returned an empty response. Please try again with a shorter file or prompt.',
      );
    }
    return trimmed;
  }

  int _countWordsFast(String text) {
    if (text.isEmpty) {
      return 0;
    }

    var count = 0;
    var inWord = false;
    for (var i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      final isWhitespace = codeUnit <= 32;
      if (isWhitespace) {
        inWord = false;
      } else if (!inWord) {
        count++;
        inWord = true;
      }
    }
    return count;
  }

  String _displayTextForUser(
    String text,
    List<ChatAttachment> attachments,
  ) {
    if (text.length <= _maxDisplayTextCharacters) {
      return text;
    }
    final omitted = text.length - _maxDisplayTextCharacters;
    final attachmentLabel = attachments.isEmpty
        ? ''
        : '\n\nAttached files: ${attachments.map((item) => item.name).join(', ')}';
    return '${text.substring(0, _maxDisplayTextCharacters)}\n\n[$omitted more characters included in the request]$attachmentLabel';
  }

  ChatMessage _hydrateFullPrompt(ChatMessage message) {
    final key = message.createdAt?.microsecondsSinceEpoch;
    final fullText = key == null ? null : _fullPromptCache[key];
    if (fullText == null) {
      return message;
    }
    return ChatMessage(
      text: fullText,
      isUser: message.isUser,
      isError: message.isError,
      mode: message.mode,
      attachments: message.attachments,
      animate: message.animate,
      createdAt: message.createdAt,
    );
  }
}
