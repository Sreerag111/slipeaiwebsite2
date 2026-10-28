import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plagiarism_checker/theme/app_text_styles.dart';

import '../../../../theme/app_theme.dart';
import '../../../../theme/theme_controller.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Get.find<AuthController>().currentUser;
    _nameController.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(AppUser user) async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Get.find<AuthController>();
    await auth.updateProfile(
      user.copyWith(name: _nameController.text.trim()),
    );
    if (!mounted) return;
    setState(() => _isEditing = false);
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AuthController auth,
  ) async {
    final isDark = ThemeController.instance.isDarkMode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141418) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.danger, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Delete Account?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            const Text(
              'The following data will be permanently deleted:\n'
              '• Profile information & login credentials\n'
              '• Chat & prompt history\n'
              '• Generated media, photos, & videos\n'
              '• Saved user preferences\n\n'
              'Note: Payment and invoice records are retained only as required by Indian financial & tax regulations.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'DELETE FOREVER',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await auth.deleteAccount();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
          Navigator.of(context).pop(); // exit profile screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your account and personal data have been permanently deleted.',
              ),
              backgroundColor: Colors.black87,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
          final errorMsg = e.toString().replaceFirst('Exception: ', '');
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF141418) : Colors.white,
              title: const Text('Account Deletion'),
              content: Text(errorMsg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final textIconColor = isDark ? Colors.white : Colors.black;
      final mutedColor = isDark ? Colors.white54 : Colors.black;
      final bg = isDark ? Colors.black : const Color(0xFFF8FAFC);
      final inputFill =
          isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white;
      final inputBorder = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFE2E8F0);

      final user = auth.currentUser;
      if (user == null) {
        return Scaffold(
          backgroundColor: bg,
          body: const SizedBox.shrink(),
        );
      }

      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textIconColor,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Profile',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textIconColor,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: GoogleFonts.montserrat(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: textIconColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Name',
                  style: AppTextStyles.labelSmallMuted
                      .copyWith(color: mutedColor),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  enabled: _isEditing,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: textIconColor,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF0F172A),
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Email',
                  style: AppTextStyles.labelSmallMuted
                      .copyWith(color: mutedColor),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: mutedColor,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? Colors.white : const Color(0xFF0F172A),
                        foregroundColor:
                            isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textIconColor,
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                auth.isLoading ? null : () => _save(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              foregroundColor:
                                  isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: auth.isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          isDark ? Colors.black : Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 36),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _confirmDeleteAccount(context, auth),
                    icon: const Icon(
                      Icons.delete_forever_outlined,
                      color: AppTheme.danger,
                      size: 20,
                    ),
                    label: Text(
                      'Delete Account',
                      style: GoogleFonts.montserrat(
                        color: AppTheme.danger,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
