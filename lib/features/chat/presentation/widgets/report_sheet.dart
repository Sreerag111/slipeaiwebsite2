import 'dart:io';
import 'package:plagiarism_checker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/theme_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI-Content Report Sheet  (used from thumbs-down on image / video)
// ─────────────────────────────────────────────────────────────────────────────

class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.onSubmit,
    required this.contentUrl,
    this.contentPrompt,
    required this.contentType,
  });

  final VoidCallback onSubmit;
  final String contentUrl;
  final String? contentPrompt;
  final String contentType;

  static void show(
    BuildContext context, {
    required VoidCallback onSubmit,
    required String contentUrl,
    String? contentPrompt,
    required String contentType,
  }) {
    AppHaptics.selection();
    final isDark = ThemeController.instance.isDarkMode;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportSheet(
        onSubmit: onSubmit,
        contentUrl: contentUrl,
        contentPrompt: contentPrompt,
        contentType: contentType,
      ),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final List<String> _reasons = [
    'Offensive, abusive, or unsafe',
    'Inaccurate or irrelevant',
    'Poor quality',
    'Other'
  ];
  int? _selectedReasonIndex;
  final TextEditingController _commentController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReasonIndex == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user?.uid ?? 'anonymous',
        'contentUrl': widget.contentUrl,
        'contentPrompt': widget.contentPrompt,
        'contentType': widget.contentType,
        'reason': _reasons[_selectedReasonIndex!],
        'comments': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSubmit();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to submit report. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Report Content',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Why are you reporting this AI-generated content? This helps us improve our safety systems.',
            style: AppTextStyles.bodyMediumBase.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_reasons.length, (index) {
            final isSelected = _selectedReasonIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedReasonIndex = index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accent
                        : (isDark ? Colors.white24 : Colors.black12),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppTheme.accent
                          : (isDark ? Colors.white54 : Colors.black54),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _reasons[index],
                      style: GoogleFonts.montserrat(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            cursorColor: AppTheme.accent,
            decoration: InputDecoration(
              hintText: 'Additional comments (optional)',
              hintStyle:
                  TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedReasonIndex != null
                    ? AppTheme.accent
                    : (isDark ? Colors.white12 : Colors.black12),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (_selectedReasonIndex != null && !_isSubmitting)
                  ? _submitReport
                  : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Submit Report',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Issue Report Sheet  (used from Settings → Report an Issue)
// ─────────────────────────────────────────────────────────────────────────────

class AppIssueReportSheet extends StatefulWidget {
  const AppIssueReportSheet({super.key});

  static void show(BuildContext context) {
    AppHaptics.selection();
    final isDark = ThemeController.instance.isDarkMode;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AppIssueReportSheet(),
    );
  }

  @override
  State<AppIssueReportSheet> createState() => _AppIssueReportSheetState();
}

class _AppIssueReportSheetState extends State<AppIssueReportSheet> {
  final List<String> _categories = [
    'App crash or freeze',
    'Feature not working',
    'AI response issue',
    'Payment or subscription',
    'Performance issue',
    'Other',
  ];

  int? _selectedCategoryIndex;
  final TextEditingController _descriptionController = TextEditingController();
  File? _screenshotFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    AppHaptics.tap();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (picked != null && mounted) {
        setState(() => _screenshotFile = File(picked.path));
      }
    } catch (_) {}
  }

  void _removeScreenshot() {
    AppHaptics.tap();
    setState(() => _screenshotFile = null);
  }

  Future<String?> _uploadScreenshot(String reportId) async {
    if (_screenshotFile == null) return null;
    try {
      final ref =
          FirebaseStorage.instance.ref('issue_screenshots/$reportId.jpg');
      await ref.putFile(_screenshotFile!);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      // Create a temporary doc ref to get a stable ID for the screenshot path
      final docRef = FirebaseFirestore.instance.collection('reports').doc();

      final screenshotUrl = await _uploadScreenshot(docRef.id);

      await docRef.set({
        'type': 'app_issue',
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email,
        'category': _categories[_selectedCategoryIndex!],
        'description': description,
        'screenshotUrl': screenshotUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report submitted — thank you! We\'ll look into it.',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit. Please try again.',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;
    final inputFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final selectedColor = AppTheme.accent;

    final canSubmit = _descriptionController.text.trim().isNotEmpty &&
        _selectedCategoryIndex != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/icons/bug.png',
                    width: 20,
                    height: 20,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Report an Issue',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Describe what went wrong and we\'ll fix it as quickly as possible.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: mutedColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Category chips (horizontal scroll)
            Text(
              'Category',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: mutedColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final isSelected = _selectedCategoryIndex == i;
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.tap();
                      setState(
                          () => _selectedCategoryIndex = isSelected ? null : i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? selectedColor : inputFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? selectedColor : borderColor,
                        ),
                      ),
                      child: Text(
                        _categories[i],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Description field
            Text(
              'Description',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: mutedColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              onChanged: (_) => setState(() {}),
              maxLines: 5,
              cursorColor: selectedColor,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textColor,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'Describe the issue in detail — what you were doing, what happened, and what you expected...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: mutedColor.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                filled: true,
                fillColor: inputFill,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: selectedColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Screenshot section
            Text(
              'Screenshot (optional)',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: mutedColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            if (_screenshotFile == null)
              // Pick button
              GestureDetector(
                onTap: _pickScreenshot,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: mutedColor, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'Attach a screenshot',
                        style:
                            GoogleFonts.inter(fontSize: 13, color: mutedColor),
                      ),
                      Text(
                        'Helps us understand the issue faster',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: mutedColor.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Screenshot preview
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _screenshotFile!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeScreenshot,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  // Change button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _pickScreenshot,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Change',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (canSubmit && !_isSubmitting) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit
                      ? selectedColor
                      : (isDark ? Colors.white12 : Colors.black12),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit Report',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
