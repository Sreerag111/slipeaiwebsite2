import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/meme_response.dart';
import '../../data/repositories/meme_repository_impl.dart';
import '../../domain/repositories/meme_repository.dart';
import '../../../premium/presentation/widgets/premium_dialog.dart';

class MemeController extends GetxController {
  final MemeRepository _repository;

  MemeController({MemeRepository? repository})
      : _repository = repository ?? MemeRepositoryImpl();

  final RxBool isLoading = false.obs;
  final RxBool hasText = false.obs;
  final Rx<MemeResponse?> memeResponse = Rx<MemeResponse?>(null);
  final RxnInt selectedPresetIndex = RxnInt(null);
  final RxString selectedFormat = 'video'.obs; // 'video' | 'gif'

  final TextEditingController promptController = TextEditingController();

  final List<String> presetPrompts = const [
    "When code compiles on the first try",
    "Debugging at 2 AM with 50 browser tabs open",
    "Senior dev watching junior dev push to main",
    "Deploying code on a Friday afternoon",
    "Fixing one bug and creating three new ones",
  ];

  @override
  void onInit() {
    super.onInit();
    hasText.value = promptController.text.trim().isNotEmpty;
    promptController.addListener(_onPromptChanged);
  }

  void _onPromptChanged() {
    hasText.value = promptController.text.trim().isNotEmpty;
  }

  void setFormat(String format) {
    selectedFormat.value = format;
  }

  @override
  void onClose() {
    promptController.removeListener(_onPromptChanged);
    promptController.dispose();
    super.onClose();
  }

  void selectPreset(int index, String prompt) {
    selectedPresetIndex.value = index;
    promptController.text = prompt;
    hasText.value = prompt.trim().isNotEmpty;
  }

  void clearPresetSelection() {
    selectedPresetIndex.value = null;
  }

  void _showTopSnackbar({
    required String title,
    required String message,
    bool isError = true,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: isError
          ? const Color(0xFF2E1A1D)
          : const Color(0xFF1C2A20),
      colorText: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      borderColor: isError
          ? const Color(0xFFFFB4AB).withValues(alpha: 0.3)
          : const Color(0xFF81C784).withValues(alpha: 0.3),
      borderWidth: 1,
      icon: Icon(
        isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
        color: isError ? const Color(0xFFFFB4AB) : const Color(0xFF81C784),
      ),
    );
  }

  Future<void> generateMeme(
    BuildContext context, [
    String? customPrompt,
    String? imageBase64,
    String? mimeType,
    String? format,
  ]) async {
    final prompt = (customPrompt ?? promptController.text).trim();

    if (prompt.isEmpty) {
      _showTopSnackbar(
        title: 'Missing Prompt',
        message: 'Please enter a prompt or select a preset idea.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showTopSnackbar(
        title: 'Authentication Required',
        message: 'Please log in to generate AI memes.',
      );
      return;
    }

    isLoading.value = true;

    try {
      final chosenFormat = format ?? selectedFormat.value;
      final response = await _repository.generateMeme(
        prompt,
        imageBase64: imageBase64,
        mimeType: mimeType,
        format: chosenFormat,
      );
      memeResponse.value = response;
      _showTopSnackbar(
        title: 'Meme Generated! 🎉',
        message: 'Your AI Meme was created successfully.',
        isError: false,
      );
    } on MemeRepositoryException catch (e) {
      if (e.code == 'permission-denied') {
        _showTopSnackbar(
          title: 'Premium Required',
          message: 'Premium subscription required for additional memes.',
        );
        if (context.mounted) {
          showPremiumDialog(context);
        }
      } else if (e.code == 'unauthenticated') {
        _showTopSnackbar(
          title: 'Authentication Required',
          message: 'Please log in to continue.',
        );
      } else if (e.code == 'invalid-argument') {
        _showTopSnackbar(
          title: 'Invalid Prompt',
          message: 'Please check your prompt and try again.',
        );
      } else if (e.code == 'deadline-exceeded') {
        _showTopSnackbar(
          title: 'Timeout',
          message: 'The AI server took too long to respond. Please try again.',
        );
      } else {
        _showTopSnackbar(
          title: 'Generation Failed',
          message: 'Unable to generate meme. Please try again.',
        );
      }
    } catch (_) {
      _showTopSnackbar(
        title: 'Error',
        message: 'Something went wrong. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void resetMeme() {
    memeResponse.value = null;
    promptController.clear();
    hasText.value = false;
    selectedPresetIndex.value = null;
  }
}
