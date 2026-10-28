import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_review_dialog.dart';

class AppReviewService {
  AppReviewService._();
  static final AppReviewService instance = AppReviewService._();

  static const String _keyHasReviewed = 'has_reviewed_app';
  static const String _keyCreationCount = 'review_prompt_creation_count';
  static const String _keyLastPromptTime = 'review_prompt_last_time_ms';

  /// Cooldown between subsequent prompts after user dismisses with "Maybe Later".
  static const Duration _subsequentPromptCooldown = Duration(hours: 24);

  /// Delay after a feature completes before showing the review prompt.
  static const Duration _happyMomentDelay = Duration(seconds: 7);

  /// For testing: set to true to bypass counts and cooldowns.
  bool? debugAlwaysShow;

  Future<bool> hasReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasReviewed) ?? false;
  }

  Future<void> markAsReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasReviewed, true);
    debugPrint('[AppReviewService] User marked as reviewed. Prompts disabled permanently.');
  }

  Future<int> getCreationCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCreationCount) ?? 0;
  }

  /// Called after a successful creative action (Image Generation, Image Edit, Photo/Video Enhance).
  Future<void> onFeatureCompleted(BuildContext? context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAlreadyReviewed = prefs.getBool(_keyHasReviewed) ?? false;

      if (debugAlwaysShow != true && hasAlreadyReviewed) {
        return;
      }

      final newCount = (prefs.getInt(_keyCreationCount) ?? 0) + 1;
      await prefs.setInt(_keyCreationCount, newCount);

      final lastPromptMs = prefs.getInt(_keyLastPromptTime) ?? 0;
      final timeSinceLast = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastPromptMs),
      );

      // Milestone trigger: 1st time, or every 5th time (5, 10, 15, 20...)
      final isMilestone = newCount == 1 || (newCount % 5 == 0);
      final cooldownMet = newCount == 1 || timeSinceLast >= _subsequentPromptCooldown;

      debugPrint(
        '[AppReviewService] Creative action completed: count=$newCount '
        'isMilestone=$isMilestone cooldownMet=$cooldownMet',
      );

      if (debugAlwaysShow == true || (isMilestone && cooldownMet)) {
        await Future<void>.delayed(_happyMomentDelay);

        // Re-check review status after the delay
        final reviewedNow = prefs.getBool(_keyHasReviewed) ?? false;
        if (debugAlwaysShow != true && reviewedNow) {
          return;
        }

        // Resolve the active mounted BuildContext. If the user popped back
        // to the previous screen before the delay elapsed, fallback to the
        // active navigator/overlay context so the review dialog displays cleanly.
        BuildContext? activeContext;
        if (context != null && context.mounted) {
          activeContext = context;
        } else if (Get.overlayContext != null && (Get.overlayContext?.mounted ?? false)) {
          activeContext = Get.overlayContext;
        } else if (Get.context != null && (Get.context?.mounted ?? false)) {
          activeContext = Get.context;
        } else if (Get.key.currentContext != null && (Get.key.currentContext?.mounted ?? false)) {
          activeContext = Get.key.currentContext;
        }

        if (activeContext == null || !activeContext.mounted) {
          debugPrint('[AppReviewService] No mounted context available after delay.');
          return;
        }

        await prefs.setInt(
          _keyLastPromptTime,
          DateTime.now().millisecondsSinceEpoch,
        );

        await showAppReviewDialog(activeContext);
      }
    } catch (e) {
      debugPrint('[AppReviewService] Error during onFeatureCompleted: $e');
    }
  }
}
