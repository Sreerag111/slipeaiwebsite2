import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/auth_scope.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/theme_controller.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/widgets/get_pro_badge.dart';
import '../../domain/entities/app_mode.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.mode,
    required this.activeThreadTitle,
    required this.onMenuOrBack,
    required this.onNewChat,
    this.isBackButton = false,
  });

  final AppMode mode;
  final String activeThreadTitle;
  final VoidCallback onMenuOrBack;
  final VoidCallback onNewChat;
  final bool isBackButton;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final isLoggedIn = auth.isLoggedIn;
    final premiumController = Get.find<PremiumController>();
    final labels = {
      AppMode.home: '',
      AppMode.plagiarism: 'Detect AI',
      AppMode.grammar: 'Grammar Check',
      AppMode.chat: activeThreadTitle
    };

    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final topBarBg = isDark ? Colors.black : const Color(0xFFF8FAFC);
      final iconColor = isDark ? Colors.white : Colors.black;
      final badgeBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
      final badgeTextColor = isDark ? Colors.white : Colors.black;
      final titleColor = isDark ? Colors.white : Colors.black;
      final showGetPro = premiumController.shouldShowUpgrade;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: topBarBg,
        ),
        child: mode == AppMode.home || mode == AppMode.chat
            ? SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildLeadingButton(
                        iconColor: iconColor,
                        backgroundColor: badgeBg,
                        isDark: isDark,
                      ),
                    ),
                    if (showGetPro) const GetProBadge(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: mode == AppMode.chat
                          ? _buildNewChatButton(
                              iconColor: iconColor,
                              backgroundColor: badgeBg,
                              isDark: isDark,
                            )
                          : !isLoggedIn
                              ? _buildLoginBadge(
                                  context: context,
                                  backgroundColor: badgeBg,
                                  isDark: isDark,
                                  foregroundColor: badgeTextColor,
                                )
                              : const SizedBox(width: 40),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  _buildLeadingButton(
                    iconColor: iconColor,
                    backgroundColor: badgeBg,
                    isDark: isDark,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        labels[mode]!,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),
                  if (showGetPro) ...[
                    const GetProBadge(),
                    const SizedBox(width: 2),
                  ],
                  _buildNewChatButton(
                    iconColor: iconColor,
                    backgroundColor: badgeBg,
                    isDark: isDark,
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildLoginBadge({
    required BuildContext context,
    required Color backgroundColor,
    required bool isDark,
    required Color foregroundColor,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              color: foregroundColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Login',
              style: AppTextStyles.labelMedium.copyWith(
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewChatButton({
    required Color iconColor,
    required Color backgroundColor,
    required bool isDark,
    String assetPath = 'assets/icons/new_chat.png',
  }) =>
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
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
            onTap: onNewChat,
            customBorder: const CircleBorder(),
            child: Center(
              child: Image.asset(
                assetPath,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                color: iconColor,
                colorBlendMode: BlendMode.srcIn,
                semanticLabel: 'New create image chat',
              ),
            ),
          ),
        ),
      );

  Widget _buildLeadingButton({
    required Color iconColor,
    required Color backgroundColor,
    required bool isDark,
  }) =>
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
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
            onTap: onMenuOrBack,
            customBorder: const CircleBorder(),
            child: Center(
              child: isBackButton
                  ? Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: iconColor,
                    )
                  : Image.asset(
                      'assets/icons/menu_staggered.png',
                      width: 22,
                      height: 22,
                      color: iconColor,
                    ),
            ),
          ),
        ),
      );
}
