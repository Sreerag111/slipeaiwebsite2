import 'package:flutter/material.dart';
import 'package:plagiarism_checker/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/theme_controller.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/widgets/premium_dialog.dart';
import '../../data/services/floating_bubble_service.dart';
import '../controllers/companion_controller.dart';

class FloatingBubbleScreen extends StatefulWidget {
  const FloatingBubbleScreen({super.key});

  @override
  State<FloatingBubbleScreen> createState() => _FloatingBubbleScreenState();
}

class _FloatingBubbleScreenState extends State<FloatingBubbleScreen> {
  late final CompanionController _companionController;

  @override
  void initState() {
    super.initState();
    _companionController = Get.find<CompanionController>();
  }

  Future<void> _toggle() async {
    final isTurningOn = !_companionController.isRunning.value;
    if (isTurningOn && !Get.find<PremiumController>().isPremium.value) {
      showPremiumDialog(context);
      return;
    }

    final message = await _companionController.toggle();
    if (message != null && mounted) {
      _showSnackBar(message);
    } else if (_companionController.isRunning.value && mounted) {
      Navigator.pop(context); // Pop the screen
      FloatingBubbleService.moveToBackground(); // Move app to background
    }
  }

  void _showSnackBar(String message) {
    final isDark = ThemeController.instance.isDarkMode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
        backgroundColor: isDark ? Colors.white : Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final textIconColor = isDark ? Colors.white : Colors.black;
      final mutedColor = isDark ? const Color(0xFFB6B6B6) : Colors.black;
      final bg = isDark ? Colors.black : const Color(0xFFF8FAFC);

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
            'Companion Mode',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textIconColor,
            ),
          ),
        ),
        body: _companionController.isLoading.value
            ? Center(
                child: CircularProgressIndicator(color: textIconColor),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildSectionHeader('ACCESS', isDark),
                    const SizedBox(height: 8),
                    _buildPermissionTile(textIconColor, mutedColor, isDark),
                    _buildToggleTile(textIconColor, mutedColor, isDark),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Text(
                        'Companion mode lets the AI understand whatever is on your screen in real time — no screenshots needed.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: mutedColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('About', isDark),
                    const SizedBox(height: 8),
                    _buildAboutSection(textIconColor, mutedColor),
                  ],
                ),
              ),
      );
    });
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white.withValues(alpha: 0.72) : Colors.black,
        letterSpacing: 1.1,
      ),
    ).animate().fadeIn();
  }

  Widget _buildPermissionTile(
      Color textIconColor, Color mutedColor, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      minLeadingWidth: 28,
      leading: Icon(
        _companionController.hasPermission.value
            ? Icons.check_circle_outline_rounded
            : Icons.shield_outlined,
        color: textIconColor,
        size: 20,
      ),
      title: Text(
        _companionController.hasPermission.value
            ? 'Overlay permission enabled'
            : 'Overlay permission needed',
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textIconColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          _companionController.hasPermission.value
              ? 'The companion bubble can appear above other apps.'
              : 'Allow display over other apps to use companion mode.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: mutedColor,
            height: 1.4,
          ),
        ),
      ),
      trailing: _companionController.hasPermission.value
          ? null
          : TextButton(
              onPressed: _companionController.requestPermission,
              child: Text(
                'Allow',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.accent : AppTheme.accent,
                ),
              ),
            ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 80));
  }

  Widget _buildToggleTile(Color textIconColor, Color mutedColor, bool isDark) {
    return ListTile(
      onTap: _toggle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      minLeadingWidth: 28,
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(context);
        },
        child: Image.asset(
          'assets/icons/companion_mode.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          color: textIconColor,
        ),
      ),
      title: Text(
        'Companion mode',
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textIconColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          _companionController.isToggling.value
              ? _companionController.isRunning.value
                  ? 'Stopping...'
                  : 'Starting...'
              : _companionController.isRunning.value
                  ? 'Active on screen'
                  : 'Turn on to use companion mode',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: mutedColor,
            height: 1.4,
          ),
        ),
      ),
      trailing: _companionController.isToggling.value
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: textIconColor.withValues(alpha: 0.7),
              ),
            )
          : Switch(
              value: _companionController.isRunning.value,
              onChanged: (_) => _toggle(),
              activeThumbColor: Colors.white,
              activeTrackColor: isDark ? const Color(0xFF5A5A5A) : Colors.black,
              inactiveThumbColor:
                  isDark ? const Color(0xFFE0E0E0) : Colors.black45,
              inactiveTrackColor:
                  isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE2E8F0),
            ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 140));
  }

  Widget _buildAboutSection(Color textIconColor, Color mutedColor) {
    final items = [
      (
        Icons.shield_outlined,
        'Allow overlay access',
        'Required to display the floating Companion Mode above other apps.',
      ),
      (
        Icons.chat_bubble_outline_rounded,
        'Chat anywhere',
        'Open the companion bubble on top of any app and chat without leaving your current screen.',
      ),
      (
        Icons.smart_toy_outlined,
        'AI assistance',
        'Ask questions, get guidance, brainstorm ideas, or receive instant support whenever needed.',
      ),
      (
        Icons.upload_file_rounded,
        'File upload support',
        'Upload documents, images, or other supported files directly in the conversation for AI analysis.',
      ),
      (
        Icons.history_rounded,
        'Conversation continuity',
        'Keep track of previous messages and continue discussions seamlessly from the floating companion.',
      ),
      (
        Icons.touch_app_rounded,
        'Quick access',
        'Minimize, move, or reopen the companion bubble anytime while using other applications.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                minLeadingWidth: 28,
                leading: Icon(item.$1, color: textIconColor, size: 20),
                title: Text(
                  item.$2,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textIconColor,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    item.$3,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: mutedColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 220 + (index * 60)),
              )
              .slideX(begin: 0.04, curve: Curves.easeOut);
        }),
      ],
    );
  }
}
