import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/widgets/auth_scope.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/theme_controller.dart';
import 'animated_slipe_wordmark.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer(
      {super.key,
      required this.onOpenProfile,
      required this.onOpenCreatedImages,
      required this.onOpenSettings});

  final VoidCallback onOpenProfile;
  final VoidCallback onOpenCreatedImages;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return Obx(() {
      final isLoggedIn = auth.isLoggedIn;
      final isDark = ThemeController.instance.isDarkMode;
      final textIconColor = isDark ? Colors.white : Colors.black;
      final mutedColor = isDark ? Colors.white54 : Colors.black;
      final name = auth.currentUser?.name.trim() ?? '';
      final initial = name.isEmpty ? 'G' : name[0].toUpperCase();
      return Drawer(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
        width: MediaQuery.of(context).size.width,
        child: SafeArea(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: isDark ? 0.12 : 0.12),
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
                  child: IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: textIconColor, size: 20),
                    onPressed: () {
                      AppHaptics.tap();
                      Navigator.pop(context);
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                const AnimatedSlipeWordmark(fontSize: 22),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: isDark ? 0.12 : 0.12),
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
                      customBorder: const CircleBorder(),
                      onTap: () {
                        AppHaptics.tap();
                        onOpenProfile();
                      },
                      child: Center(
                        child: Text(
                          initial,
                          style: AppTextStyles.titleMediumLg
                              .copyWith(color: textIconColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            Divider(
              height: 1,
              thickness: 0.7,
              indent: 16,
              endIndent: 16,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 12),
            _drawerItem(
              icon: Icons.photo_library_outlined,
              label: 'Created images',
              color: textIconColor,
              isDark: isDark,
              onTap: onOpenCreatedImages,
            ),
            _drawerItem(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              label: 'Theme',
              trailing: Text(isDark ? 'Dark' : 'Light',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: mutedColor,
                    height: 1.4,
                  )),
              color: textIconColor,
              isDark: isDark,
              onTap: ThemeController.instance.toggleTheme,
            ),
            _drawerItem(
              assetIcon: 'assets/icons/settings.png',
              label: 'Settings',
              color: textIconColor,
              isDark: isDark,
              onTap: onOpenSettings,
            ),
            if (isLoggedIn)
              _drawerItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: textIconColor,
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(context);
                  await auth.logout();
                },
              ),
          ]),
        ),
      );
    });
  }

  Widget _drawerItem({
    IconData? icon,
    String? assetIcon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final iconBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.09 : 0.08),
                    blurRadius: 5,
                    offset: const Offset(0, 1.5),
                  ),
                  BoxShadow(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.04 : 0.03),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: assetIcon != null
                    ? Image.asset(
                        assetIcon,
                        color: color,
                        width: 18,
                        height: 18,
                      )
                    : Icon(icon, color: color, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                    height: 1.4,
                  )),
            ),
            trailing ?? const SizedBox.shrink(),
          ]),
        ),
      ),
    );
  }
}
