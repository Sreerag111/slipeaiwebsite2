import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import 'app_version_service.dart';

/// Shows the update dialog matching the exact style of [PremiumDialog].
Future<void> showAppUpdateDialog(
  BuildContext context, {
  bool isMandatory = false,
  AppVersionConfig? config,
}) =>
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      builder: (ctx) => PopScope(
        canPop: true,
        child: AppUpdateDialog(
          isMandatory: isMandatory,
          config: config,
        ),
      ),
    );

/// Modal dialog styled exactly like [PremiumDialog].
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    this.isMandatory = false,
    this.config,
  });

  final bool isMandatory;
  final AppVersionConfig? config;

  @override
  Widget build(BuildContext context) => Obx(() {
        final isDark = ThemeController.instance.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.black;
        final mutedColor = isDark ? Colors.white60 : Colors.black54;

        final activeConfig = config ?? AppVersionService.instance.currentConfig;
        final title = activeConfig?.title ?? 'Update Slipe AI';
        final message = activeConfig?.message ??
            'A new version of Slipe AI is available with improved AI photo and video generation, performance updates, and bug fixes.';

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: isDark ? const Color(0xFF171717) : Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Bar / Close Button (Only for optional soft updates)
                    Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          tooltip: 'Close',
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.06),
                            foregroundColor: textColor,
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    

                    // Logo Container matching PremiumDialog
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset('assets/logo/new_logo.png'),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleLargeBold
                          .copyWith(color: textColor),
                    ),

                    const SizedBox(height: 10),

                    // Message
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        height: 1.5,
                        color: mutedColor,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Primary Action: Update on Google Play
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            AppVersionService.instance.launchStoreUpdate(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.onAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 16),
                          shape: const StadiumBorder(),
                          side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Update on Google Play',
                              style: AppTextStyles.titleLargeBold.copyWith(
                                color: AppTheme.onAccent,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 22),
                          ],
                        ),
                      ),
                    ),

                    // Secondary Action: Later (Only for soft updates)
                    ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.black12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 15),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            'Maybe Later',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      });
}

/// Full-screen wrapper page used when Splash screen routes to a mandatory update.
/// Renders the identical [AppUpdateDialog] on top of a dark/light blurred background.
class AppUpdateScreen extends StatelessWidget {
  const AppUpdateScreen({
    super.key,
    this.config,
  });

  final AppVersionConfig? config;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        body: Center(
          child: AppUpdateDialog(
            isMandatory: true,
            config: config,
          ),
        ),
      ),
    );
  }
}
