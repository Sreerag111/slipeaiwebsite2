import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/theme_controller.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_theme.dart';
import '../../../focus_mode/presentation/pages/focus_mode_screen.dart';
import '../../../enhancer/presentation/pages/photo_enhancer_screen.dart';
import '../../../enhancer/presentation/pages/photo_enhancer_categories_screen.dart';
import '../../../enhancer/presentation/pages/video_enhancer_screen.dart';
import '../../../enhancer/presentation/pages/video_enhancer_categories_screen.dart';
import '../../domain/entities/app_mode.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_thread.dart';
import '../../domain/entities/image_aspect_ratio.dart';
import '../../data/services/upload_processing_service.dart';
import '../controllers/chat_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/creative_bottom_bar.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/home_content.dart';
import '../widgets/home_top_bar.dart';
import 'result_screen.dart';
import 'created_images_screen.dart';
import 'image_preset_gallery_page.dart';
import '../../../settings/presentation/pages/settings_screen.dart';
import '../../../auth/presentation/pages/profile_screen.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../settings/presentation/pages/floating_bubble_screen.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../../core/version/app_version_service.dart';
import '../../../../core/version/app_update_screen.dart';

import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/widgets/get_pro_badge.dart';
import '../../../premium/presentation/widgets/premium_dialog.dart';

/// A separate route so Back returns to the preset gallery, not the home tab.
class PresetCreationPage extends StatelessWidget {
  const PresetCreationPage({super.key, required this.selection});

  final ImagePresetSelection selection;

  @override
  Widget build(BuildContext context) => HomeScreen(presetSelection: selection);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.presetSelection});

  /// When present, this instance is the dedicated chat route above the gallery.
  final ImagePresetSelection? presetSelection;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const int _maxInlineTextFileCharacters = 12000;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _inputScrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  final SpeechToText _speechToText = SpeechToText();
  final UploadProcessingService _uploadProcessingService =
      UploadProcessingService();
  late final ChatController _chatController;
  late final Worker _scrollWorker;
  bool _speechAvailable = false;
  Timer? _recordingTimer;
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _attachBtnKey = GlobalKey();
  UploadCancellationToken? _activeUploadToken;
  bool _isPickingAttachment = false;
  bool _isUploadingAttachment = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';
  bool _showScrollToBottomBtn = false;
  final Rx<GenerationMode> _selectedGenerationMode = GenerationMode.image.obs;
  ImageAspectRatio _selectedAspectRatio = ImageAspectRatio.portrait;
  int _selectedTab = 0;

  AppMode get _mode => _chatController.mode.value;
  bool get _isLoading => _chatController.isLoading.value;
  bool get _showSourceField => _chatController.showSourceField.value;
  int get _wordCount => _chatController.wordCount.value;
  List<ChatMessage> get _chatMessages => _chatController.chatMessages;
  bool get _isListening => _chatController.isListening.value;
  bool get _shouldKeepListening => _chatController.shouldKeepListening.value;
  String get _voiceTranscript => _chatController.voiceTranscript.value;
  bool get _isSubmittingVoiceResult =>
      _chatController.isSubmittingVoiceResult.value;
  Duration get _recordingDuration => _chatController.recordingDuration.value;
  List<ChatAttachment> get _attachedImages =>
      _chatController.imageAttachments.toList();
  List<ChatAttachment> get _attachedFiles =>
      _chatController.fileAttachments.toList();
  // ignore: unused_element
  List<ChatThread> get _chatThreads => _chatController.chatThreads;
  String? get _activeConversationId =>
      _chatController.activeConversationId.value;
  // ignore: unused_element
  String get _activeThreadTitle => _chatController.activeThreadTitle.value;
  String get _sourceText => _chatController.sourceText.value;

  @override
  void initState() {
    super.initState();
    _chatController = Get.find<ChatController>();
    WidgetsBinding.instance.addObserver(this);
    _chatScrollController.addListener(_scrollListener);
    _inputController.addListener(
        () => _chatController.updateWordCount(_inputController.text));
    _sourceController.addListener(
        () => _chatController.setSourceText(_sourceController.text));
    _inputFocus.addListener(() => setState(() {}));
    _scrollWorker = ever<int>(_chatController.scrollSignal, (_) {
      _scrollToBottom();
    });

    // _initSpeech() removed: audio/speech is disabled in Photo/Video flow to prevent startup permission popup.
    _chatController.loadChatThreads();
    if (widget.presetSelection == null) {
      _setupFloatingBubbleChannel();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initializePresetCreation(widget.presetSelection!);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final status = await AppVersionService.instance.checkUpdateStatus();
      if (status == AppUpdateStatus.forceUpdateRequired && mounted) {
        await showAppUpdateDialog(context, isMandatory: true);
      } else if (status == AppUpdateStatus.softUpdateAvailable && mounted) {
        await showAppUpdateDialog(context, isMandatory: false);
      }
    });
  }

  void _setupFloatingBubbleChannel() {
    const channel = MethodChannel('com.blide.ai/floating_bubble');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openConversation') {
        final conversationId = call.arguments as String?;
        if (conversationId != null && conversationId.isNotEmpty) {
          await _chatController.loadAndOpenThread(conversationId);
        }
      } else if (call.method == 'openFocusMode') {
        _openFocusModeScreen();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final conversationId =
            await channel.invokeMethod<String>('getLaunchConversationId');
        if (conversationId != null && conversationId.isNotEmpty) {
          await _chatController.loadAndOpenThread(conversationId);
        }
        final openFocusMode =
            await channel.invokeMethod<bool>('getLaunchOpenFocusMode') ?? false;
        if (openFocusMode) {
          _openFocusModeScreen();
        }
      } catch (_) {}
    });
  }

  void _openFocusModeScreen() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FocusModeScreen()),
    );
  }

  // ignore: unused_element
  void _openCompanionModeScreen() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FloatingBubbleScreen()),
    );
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldKeepListening) {
      _restartListeningIfNeeded();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatScrollController.removeListener(_scrollListener);
    _scrollWorker.dispose();
    _recordingTimer?.cancel();
    _speechToText.cancel();
    _inputController.dispose();
    _sourceController.dispose();
    _chatScrollController.dispose();
    _inputScrollController.dispose();
    _inputFocus.dispose();
    _activeUploadToken?.cancel();
    super.dispose();
  }

  void _clearComposerState() {
    _inputController.clear();
    _sourceController.clear();
    _selectedAspectRatio = ImageAspectRatio.portrait;
    _selectedGenerationMode.value =
        _selectedTab == 0 ? GenerationMode.image : GenerationMode.none;
    _chatController.clearComposerState();
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  void _startRecordingTimer() {
    _stopRecordingTimer();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isListening) return;
      _chatController.incrementRecordingDuration();
    });
  }

  // ignore: unused_element
  Future<void> _selectMode(AppMode nextMode) async {
    if (nextMode == AppMode.home) {
      await _returnToHome();
    } else {
      await _startNewChat(mode: nextMode);
    }
    if (!mounted) return;
    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          _inputFocus.requestFocus();
        }
      },
    );
  }

  Future<void> _returnToHome() async {
    await _stopListeningSafely(submitTranscript: false);
    _clearComposerState();
    await _chatController.returnToHome();
  }

  Future<void> _leaveCreateImageChat() async {
    if (_isLoading) _chatController.cancelActiveRequest();
    if (_isUploadingAttachment) _cancelActiveUpload();
    await _returnToHome();
    if (widget.presetSelection != null && mounted) Navigator.pop(context);
  }

  Future<String?> _extractAssetToTempFile(String assetPath, String id) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final ext = assetPath.toLowerCase().endsWith('.jpg') ||
              assetPath.toLowerCase().endsWith('.jpeg')
          ? 'jpg'
          : 'png';
      final file = File('${tempDir.path}/ref_preset_$id.$ext');
      await file.writeAsBytes(byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ));
      return file.path;
    } catch (e) {
      debugPrint('[PresetCreation] Failed to extract asset $assetPath: $e');
      return null;
    }
  }

  Future<void> _initializePresetCreation(ImagePresetSelection selection) async {
    await _stopListeningSafely(submitTranscript: false);
    _clearComposerState();
    _selectedGenerationMode.value = GenerationMode.image;
    await _chatController.startNewChat(nextMode: AppMode.chat);
    if (!mounted) return;

    // 1. Attach Image 1: Reference Style Artwork from preset assets
    final refPath = await _extractAssetToTempFile(
      selection.preset.imagePath,
      selection.preset.id,
    );
    if (refPath != null && mounted) {
      await _processPickedUpload(
        path: refPath,
        name: 'reference_${selection.preset.id}.${refPath.split('.').last}',
        extension: refPath.split('.').last,
        isImage: true,
        replaceAttachments: true,
      );
    }

    if (!mounted) return;

    // 2. Attach Image 2: User's Uploaded Photo (Identity to edit)
    final path = selection.photoPath;
    final attached = await _processPickedUpload(
      path: path,
      name: _basename(path),
      extension: _basename(path).split('.').last,
      isImage: true,
      replaceAttachments: refPath == null,
    );
    if (!attached || !mounted) return;

    // Reuse the existing image-edit submission, including limits and ads.
    debugPrint(
      '[ImagePreset] Try-It triggered for preset="${selection.preset.id}" ("${selection.preset.title}") '
      'len=${selection.preset.prompt.length} chars:\n${selection.preset.prompt}',
    );
    await _submitText(selection.preset.prompt);
  }

  Future<void> _startNewChat({AppMode mode = AppMode.chat}) async {
    await _stopListeningSafely(submitTranscript: false);
    _clearComposerState();
    await _chatController.startNewChat(nextMode: mode);
    _inputFocus.requestFocus();
  }

  Future<void> _openImagePresetGallery() async {
    if (_isLoading || _isUploadingAttachment) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePresetGalleryPage(
          onPhotoSelected: (selection) async {
            if (!mounted) return;
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => PresetCreationPage(selection: selection),
              ),
            );
          },
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _openThread(ChatThread thread) async {
    await _stopListeningSafely(submitTranscript: false);
    _clearComposerState();
    await _chatController.openThread(thread);
    _scrollToBottom();
  }

  Future<void> _showAttachmentSheet() async {
    if (_isPickingAttachment || _isUploadingAttachment) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.lightImpact();
    final val = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      barrierDismissible: !_isUploadingAttachment,
      builder: (_) => UploadPickerSheet(
        imageOnly: true,
        onCancelUpload: _cancelActiveUpload,
        isUploading: _isUploadingAttachment,
        progress: _uploadProgress,
        status: _uploadStatus,
      ),
    );

    if (val == null || !mounted) return;

    HapticFeedback.selectionClick();
    _isPickingAttachment = true;
    try {
      if (val == 'camera') {
        await _pickCameraImage();
      } else if (val == 'gallery') {
        await _pickGalleryImage();
      } else if (val == 'files') {
        await _pickFiles();
      }
    } finally {
      _isPickingAttachment = false;
    }
  }

  Future<void> _pickCameraImage() async {
    PermissionStatus perm = await Permission.camera.status;
    if (!perm.isGranted) {
      perm = await Permission.camera.request();
    }
    if (!mounted) return;
    if (perm.isPermanentlyDenied) {
      _showSnackBar(
        'Camera permission denied. Enable in Settings.',
        AppTheme.danger,
      );
      await openAppSettings();
      return;
    }
    if (!perm.isGranted) {
      _showSnackBar('Camera permission required', AppTheme.danger);
      return;
    }
    final xf = await _imagePicker.pickImage(source: ImageSource.camera);
    if (xf != null && mounted) {
      await _processPickedUpload(
        path: xf.path,
        name: _basename(xf.path),
        extension: 'jpg',
        isImage: true,
      );
    }
  }

  Future<void> _pickGalleryImage() async {
    final images = await _imagePicker.pickMultiImage();
    if (!mounted) return;

    for (final xf in images) {
      await _processPickedUpload(
        path: xf.path,
        name: _basename(xf.path),
        extension: _basename(xf.path).split('.').last,
        isImage: true,
      );
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: UploadProcessingService.supportedExtensions.toList(),
    );
    if (result == null || !mounted) return;
    for (final file in result.files) {
      if (file.path == null) continue;
      await _processPickedUpload(
        path: file.path!,
        name: file.name,
        extension: file.extension,
        isImage: false,
      );
    }
  }

  // Screen share is exclusive to Companion Mode

  Future<bool> _processPickedUpload({
    required String path,
    required String name,
    required String? extension,
    required bool isImage,
    bool replaceAttachments = false,
  }) async {
    final premiumController = Get.find<PremiumController>();
    if (!premiumController.isPremium.value && !replaceAttachments) {
      final currentCount = _chatController.imageAttachments.length +
          _chatController.fileAttachments.length;
      if (currentCount >= 3) {
        showPremiumDialog(context);
        return false;
      }
    }

    final token = UploadCancellationToken();
    _activeUploadToken = token;
    setState(() {
      _isUploadingAttachment = true;
      _uploadProgress = 0;
      _uploadStatus = 'Preparing $name';
    });
    try {
      final processed = await _uploadProcessingService.preparePickedFile(
        path: path,
        name: name,
        extension: extension,
        isImage: isImage,
        token: token,
        onProgress: (progress) {
          if (!mounted || token.isCancelled) return;
          setState(() {
            _uploadStatus = progress.label;
            _uploadProgress = progress.progress;
          });
        },
      );
      if (!mounted || token.isCancelled) return false;
      if (processed.isImage) {
        if (replaceAttachments) _chatController.clearAttachments();
        _chatController.addImageAttachment(
          path: processed.path,
          name: processed.name,
        );
      } else {
        _chatController.addFileAttachment(
          path: processed.path,
          name: processed.name,
          extension: processed.extension,
        );
        final preview = await _uploadProcessingService.readTextPreview(
          path: processed.path,
          token: token,
          maxCharacters: _maxInlineTextFileCharacters,
        );
        if (preview != null &&
            preview.isNotEmpty &&
            _inputController.text.isEmpty) {
          _inputController.text = preview;
        }
      }
      return true;
    } on UploadCancelledException {
      _showSnackBar('Upload cancelled', AppTheme.card);
    } on UploadProcessingException catch (error) {
      _showSnackBar(error.message, AppTheme.danger);
    } catch (error) {
      _showSnackBar('Upload failed. Please try again.', AppTheme.danger);
    } finally {
      if (mounted && identical(_activeUploadToken, token)) {
        setState(() {
          _isUploadingAttachment = false;
          _uploadProgress = 0;
          _uploadStatus = '';
        });
        _activeUploadToken = null;
      }
    }
    return false;
  }

  void _cancelActiveUpload() {
    HapticFeedback.mediumImpact();
    _activeUploadToken?.cancel();
    setState(() {
      _isUploadingAttachment = false;
      _uploadProgress = 0;
      _uploadStatus = '';
    });
  }

  String _basename(String path) =>
      path.split(RegExp(r'[\\/]')).where((item) => item.isNotEmpty).last;

  Future<void> _toggleListening() async {
    // Microphone is disabled in this Photo/Video release.
    _showSnackBar('Voice messaging is not available in this version');
  }

  Future<void> _startListeningSession() async {
    if (!_speechAvailable) return;
    _chatController.setListening(true);
    _startRecordingTimer();
    await _speechToText.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(minutes: 5),
      ),
      onResult: (result) {
        if (!mounted) return;
        _chatController.setVoiceTranscript(result.recognizedWords);
      },
    );
  }

  Future<void> _restartListeningIfNeeded() async {
    if (!_shouldKeepListening || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!_shouldKeepListening || !mounted || _speechToText.isListening) return;
    await _startListeningSession();
  }

  Future<void> _stopListeningSafely({required bool submitTranscript}) async {
    final wasListening = _isListening || _shouldKeepListening;
    _chatController.setShouldKeepListening(false);
    if (!wasListening) return;
    if (submitTranscript && _isSubmittingVoiceResult) return;

    _stopRecordingTimer();
    await _speechToText.stop();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    _chatController.setListening(false);

    final text = _voiceTranscript.trim();
    _chatController.setVoiceTranscript('');

    if (!submitTranscript) {
      return;
    }

    if (text.isEmpty) {
      _showSnackBar('No speech detected', AppTheme.danger);
      return;
    }

    _chatController.setSubmittingVoiceResult(true);
    try {
      await _submitText(text);
    } finally {
      _chatController.setSubmittingVoiceResult(false);
    }
  }

  Future<void> _submit() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && _attachedImages.isEmpty && _attachedFiles.isEmpty)
      return;

    AppHaptics.send();
    await _submitText(text);
  }

  Future<void> _submitText(String baseText) async {
    String finalSubmitText = baseText.trim();
    if (_isLoading) {
      _showSnackBar(
        'Please wait for the current response to finish.',
        AppTheme.danger,
      );
      return;
    }

    final generationMode = _selectedGenerationMode.value;
    final premiumController = Get.find<PremiumController>();
    debugPrint(
      '[HomeScreen] submit: generationMode=$generationMode '
      'imageCount=${premiumController.imageGenerationCount.value} '
      'canGenerateImage=${premiumController.canGenerateImage()}',
    );
    if (generationMode == GenerationMode.image &&
        !premiumController.canGenerateImage()) {
      debugPrint(
        '[AdMob] create image precheck: limit reached '
        'imageCount=${premiumController.imageGenerationCount.value} '
        'rewardCredits=${premiumController.rewardedImageCredits.value}',
      );
      await showPremiumDialog(
        context,
        initialPlanId: 'lite_monthly',
        offerRewardedImage: true,
        onRewardedImageGranted: () async {
          if (!mounted) return;
          await _submitText(baseText);
        },
      );
      return;
    }

    // Save text in case we need to restore it on limit hit
    final savedInputText = _inputController.text;
    final wasHome = _mode == AppMode.home;
    final selectedRatio = _selectedAspectRatio;
    final useSelectedRatio = wasHome &&
        generationMode == GenerationMode.image &&
        _attachedImages.isEmpty &&
        _attachedFiles.isEmpty;

    _selectedGenerationMode.value =
        _selectedTab == 0 ? GenerationMode.image : GenerationMode.none;
    _inputController.clear();

    if (wasHome) {
      await _chatController.startNewChat(
        nextMode: AppMode.chat,
        clearAttachments: false,
      );
    }

    final outcome = await _chatController.submit(
      baseText: finalSubmitText,
      currentSourceText: _sourceController.text.trim(),
      generationMode: generationMode,
      imageSize: useSelectedRatio ? selectedRatio.apiSize : null,
      imagePromptInstruction:
          useSelectedRatio ? selectedRatio.promptInstruction : null,
    );
    if (generationMode == GenerationMode.meme) {
      debugPrint(
          '[HomeScreen] Submit completed with outcome error: ${outcome.errorMessage}');
    }
    await _handleSubmissionOutcome(
      outcome,
      onLimitReached: () async {
        // Step 1: Return to home FIRST (this calls _clearComposerState internally)
        if (wasHome) {
          await _returnToHome();
        }
        // Step 2: NOW restore the generation mode AFTER home is set
        setState(() {
          _selectedGenerationMode.value = generationMode;
          _selectedAspectRatio = selectedRatio;
        });
        if (savedInputText.isNotEmpty) {
          _inputController.text = savedInputText;
        }
      },
      onRewardedImageGranted: () async {
        if (!mounted) return;
        await _submitText(baseText);
      },
    );
  }

  Future<void> _retryFailedMessage() async {
    final outcome = await _chatController.retryLastFailedMessage();
    await _handleSubmissionOutcome(outcome);
  }

  Future<void> _handleSubmissionOutcome(
    ChatSubmissionOutcome outcome, {
    Future<void> Function()? onLimitReached,
    Future<void> Function()? onRewardedImageGranted,
  }) async {
    final errorMessage = outcome.errorMessage;
    final isImageLimit = errorMessage?.contains('IMAGE_LIMIT_REACHED') == true;
    final isUsageLimit = errorMessage == 'CHAT_LIMIT_REACHED' || isImageLimit;
    if (isUsageLimit) {
      // Await the restore (returnToHome + setState) before showing dialog
      await onLimitReached?.call();
      if (!mounted) return;
      await showPremiumDialog(
        context,
        initialPlanId: 'lite_monthly',
        offerRewardedImage: isImageLimit,
        onRewardedImageGranted: isImageLimit ? onRewardedImageGranted : null,
      );
      return;
    }
    if (outcome.shouldOpenSettings) {
      _showSnackBar(
        'Set your OpenAI API key in Settings first',
        AppTheme.danger,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      }
      return;
    }
    if (outcome.plagiarismResult != null && outcome.analyzedText != null) {
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => ResultScreen(
              result: outcome.plagiarismResult!,
              originalText: outcome.analyzedText!,
            ),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
          ),
        );
      }
      return;
    }
    if (!outcome.wasCancelled && outcome.errorMessage != null) {
      _showSnackBar(outcome.errorMessage!, AppTheme.danger);
    }
  }

  void _scrollToBottom() {
    // wait for layout to settle
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  void _scrollListener() {
    if (!_chatScrollController.hasClients) return;
    final maxScroll = _chatScrollController.position.maxScrollExtent;
    final currentScroll = _chatScrollController.position.pixels;
    final showBtn = (maxScroll - currentScroll) > 200;
    if (showBtn != _showScrollToBottomBtn) {
      setState(() {
        _showScrollToBottomBtn = showBtn;
      });
    }
  }

  void _showSnackBar(String msg, [Color? color]) {
    showTopSnackBar(context, msg, color: color ?? Colors.white);
  }

  void _stopActiveRequest() {
    _chatController.cancelActiveRequest();
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    AppHaptics.tap();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedTab = index);
    if (index == 0) _selectedGenerationMode.value = GenerationMode.image;
  }

  Widget _buildCreationChatTopBar(bool isDark) {
    final foreground = isDark ? Colors.white : Colors.black;
    final buttonBackground = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: buttonBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.12),
                      blurRadius: 8,
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
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _leaveCreateImageChat,
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Icon(Icons.arrow_back_rounded,
                          color: foreground, size: 20),
                    ),
                  ),
                ),
              ),
            ),
            if (Get.find<PremiumController>().shouldShowUpgrade)
              const GetProBadge(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final backgroundColor = isDark ? Colors.black : const Color(0xFFF8FAFC);
      final isImageChat = _selectedTab == 0 &&
          (widget.presetSelection != null || _mode == AppMode.chat);

      final canSystemPop = _selectedTab == 0 &&
          widget.presetSelection == null &&
          _mode == AppMode.home;

      return PopScope(
        canPop: canSystemPop,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (widget.presetSelection != null) {
            if (_isLoading) _chatController.cancelActiveRequest();
            _activeUploadToken?.cancel();
            _chatController.returnToHome();
          } else if (_selectedTab != 0) {
            _selectTab(0);
          } else if (isImageChat) {
            _leaveCreateImageChat();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: backgroundColor,
          drawerEnableOpenDragGesture: !isImageChat,
          drawer: AppDrawer(
            onOpenProfile: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Get.find<AuthController>().isLoggedIn
                          ? const ProfileScreen()
                          : const LoginScreen(),
                    ),
                  );
                }
              });
            },
            onOpenSettings: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()));
                }
              });
            },
            onOpenCreatedImages: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreatedImagesScreen(),
                    ),
                  );
                }
              });
            },
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SafeArea(
              child: Column(children: [
                if (isImageChat)
                  _buildCreationChatTopBar(isDark)
                else
                  HomeTopBar(
                    mode: AppMode.home,
                    activeThreadTitle: '',
                    onMenuOrBack: () {
                      AppHaptics.menu();
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    onNewChat: _returnToHome,
                  ),
                if (_selectedTab == 0) ...[
                  Expanded(
                    child:
                        _mode == AppMode.home && widget.presetSelection == null
                            ? HomeContent(
                                isMemeMode: _selectedGenerationMode.value ==
                                    GenerationMode.meme,
                                onTryImagePresets: _openImagePresetGallery,
                                onMemeSuggestionTap: (prompt) {
                                  _inputController.text = prompt;
                                  _inputFocus.requestFocus();
                                },
                              )
                            : ChatMessageList(
                                mode: isImageChat ? AppMode.chat : _mode,
                                hideEmptyChatPrompt: isImageChat,
                                chatMessages: _chatMessages,
                                chatController: _chatController,
                                activeConversationId: _activeConversationId,
                                isLoading: _isLoading,
                                showSourceField: _showSourceField,
                                sourceController: _sourceController,
                                onToggleSourceField:
                                    _chatController.toggleSourceField,
                                onRetryFailedMessage: _retryFailedMessage,
                                scrollController: _chatScrollController,
                                scrollToBottomVisible: _showScrollToBottomBtn,
                                onScrollToBottom: _scrollToBottom,
                                onSuggestionTap: (text) {
                                  _inputController.text = text;
                                  _inputFocus.requestFocus();
                                },
                              ),
                  ),
                  if (_mode == AppMode.plagiarism) _buildPlagSourceBar(isDark),
                  ChatInputBar(
                    mode: isImageChat ? AppMode.chat : _mode,
                    inputController: _inputController,
                    inputFocus: _inputFocus,
                    inputScrollController: _inputScrollController,
                    attachBtnKey: _attachBtnKey,
                    isLoading: _isLoading,
                    isListening: _isListening,
                    recordingDuration: _recordingDuration,
                    attachedImages: _attachedImages,
                    attachedFiles: _attachedFiles,
                    isUploadingAttachment: _isUploadingAttachment,
                    uploadProgress: _uploadProgress,
                    selectedGenerationMode: _selectedGenerationMode.value,
                    imageAspectRatio: _selectedAspectRatio,
                    onImageAspectRatioSelected: (ratio) =>
                        setState(() => _selectedAspectRatio = ratio),
                    selectedMemeFormat:
                        _chatController.selectedMemeFormat.value,
                    onMemeFormatChanged: (format) =>
                        _chatController.setSelectedMemeFormat(format),
                    onComingSoon: (msg) => _showSnackBar(msg),
                    hasText: _wordCount > 0,
                    onToggleListening: _toggleListening,
                    onShowAttachmentSheet: _showAttachmentSheet,
                    onCancelUpload: _cancelActiveUpload,
                    onSubmit: _submit,
                    onStopActiveRequest: _stopActiveRequest,
                    onRemoveImageAttachment:
                        _chatController.removeImageAttachment,
                    onRemoveFileAttachment:
                        _chatController.removeFileAttachment,
                    onClearGenerationMode: () {
                      _selectedGenerationMode.value = GenerationMode.image;
                    },
                    imageOnly: true,
                  ),
                ] else if (_selectedTab == 1)
                  Expanded(
                    child: PhotoEnhancerCategoriesScreen(
                      onSelectCategory: (category) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PhotoEnhancerScreen(
                              initialCategory: category.id,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else if (_selectedTab == 2)
                  Expanded(
                    child: VideoEnhancerCategoriesScreen(
                      onSelectCategory: (category) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => VideoEnhancerScreen(
                              initialCategory: category.id,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Expanded(child: _buildCreateVideoPage(isDark)),
                if (!isImageChat)
                  CreativeBottomBar(
                    selectedIndex: _selectedTab,
                    onSelected: _selectTab,
                  ),
              ]),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCreateVideoPage(bool isDark) {
    final foreground = isDark ? Colors.white : const Color(0xFF141820);
    final muted = isDark ? Colors.white54 : const Color(0xFF64748B);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white10 : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE4E8EF),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(29),
                child: Image.asset(
                  'assets/icons/create_video.png',
                  color: foreground,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Create video',
                style: AppTextStyles.displaySmall.copyWith(
                  fontSize: 30,
                  color: foreground,
                )),
            const SizedBox(height: 12),
            Text('Coming soon',
                style: AppTextStyles.titleMedium.copyWith(
                  color: muted,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlagSourceBar(bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isDark
            ? AppTheme.accentSecondary.withValues(alpha: 0.07)
            : const Color(0xFFF1F5F9),
        child: Row(children: [
          Icon(Icons.compare_arrows_rounded,
              size: 14, color: AppTheme.accentSecondary),
          const SizedBox(width: 6),
          Text(
              _showSourceField && _sourceText.isNotEmpty
                  ? 'Source attached'
                  : 'No source text',
              style: AppTextStyles.microNumber.copyWith(
                  fontWeight: FontWeight.normal,
                  color: isDark ? AppTheme.accentSecondary : Colors.black)),
          const Spacer(),
          GestureDetector(
            onTap: _chatController.toggleSourceField,
            child: Text(_showSourceField ? 'Hide' : 'Add source',
                style: AppTextStyles.microNumber.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentSecondary)),
          ),
        ]),
      );
}
