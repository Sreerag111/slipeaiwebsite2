import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/theme_controller.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../auth/presentation/pages/profile_screen.dart';
import '../../../legal/presentation/pages/privacy_policy_screen.dart';
import '../../../legal/presentation/pages/terms_conditions_screen.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/pages/premium_screen.dart';
import '../../../chat/presentation/widgets/report_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _confirmCancellation(
    PremiumController premiumController,
  ) async {
    final isDark = ThemeController.instance.isDarkMode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141418) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cancel subscription?'),
        content: const Text(
          'Future renewal will be stopped. You will keep Premium until '
          'the end of your current trial or billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KEEP SUBSCRIPTION'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CANCEL SUBSCRIPTION'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await premiumController.cancelSubscription();
    }
  }

  Future<void> _confirmLogout(AuthController auth) async {
    final isDark = ThemeController.instance.isDarkMode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141418) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of your PaceAI account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await auth.logout();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _confirmDeleteAccount(AuthController auth) async {
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
            const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 24),
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
          Navigator.of(context).pop(); // exit settings screen
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
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final textIconColor = isDark ? Colors.white : Colors.black;
      final mutedColor = isDark ? Colors.white54 : Colors.black;
      final bg = isDark ? Colors.black : const Color(0xFFF8FAFC);
      final dividerColor = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFE2E8F0);

      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: textIconColor,
              size: 18,
            ),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textIconColor,
              letterSpacing: 2,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                final premiumController = Get.find<PremiumController>();
                final showUpgrade = premiumController.shouldShowUpgrade;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!showUpgrade) ...[
                      _buildSectionHeader('SUBSCRIPTION', mutedColor),
                      const SizedBox(height: 10),
                      _buildSubscriptionCard(
                        premiumController: premiumController,
                        isDark: isDark,
                        textColor: textIconColor,
                        mutedColor: mutedColor,
                        borderColor: dividerColor,
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (showUpgrade) ...[
                      _buildSection(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Upgrade Slipe AI',
                            subtitle:
                                'Unlock unlimited image creation and enhancement',
                            color: AppTheme.accent,
                            textColor: textIconColor,
                            mutedColor: mutedColor,
                            onTap: () => PremiumScreen.open(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }).animate().fadeIn(delay: 120.ms),
              const SizedBox(height: 28),
              _buildSectionHeader('Account', mutedColor),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final auth = Get.find<AuthController>();
                return Obx(() {
                  final isLoggedIn = auth.isLoggedIn;
                  final user = auth.currentUser;
                  return _buildSection(
                    children: [
                      if (isLoggedIn) ...[
                        _buildSettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: (user?.name != null && user!.name.isNotEmpty)
                              ? user.name
                              : 'Account Profile',
                          subtitle: (user?.email != null && user!.email.isNotEmpty)
                              ? user.email
                              : 'Manage account details',
                          color: textIconColor,
                          textColor: textIconColor,
                          mutedColor: mutedColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                        ),
                        Divider(color: dividerColor, height: 1),
                        _buildSettingsTile(
                          icon: Icons.logout_rounded,
                          title: 'Log out',
                          subtitle: 'Sign out of your account on this device',
                          color: textIconColor,
                          textColor: textIconColor,
                          mutedColor: mutedColor,
                          onTap: () => _confirmLogout(auth),
                        ),
                        Divider(color: dividerColor, height: 1),
                        _buildSettingsTile(
                          icon: Icons.delete_forever_outlined,
                          title: 'Delete Account',
                          subtitle:
                              'Permanently remove your account and all personal data',
                          color: AppTheme.danger,
                          textColor: AppTheme.danger,
                          mutedColor: mutedColor,
                          onTap: () => _confirmDeleteAccount(auth),
                        ),
                      ] else ...[
                        _buildSettingsTile(
                          icon: Icons.login_rounded,
                          title: 'Log In or Sign Up',
                          subtitle:
                              'Sign in to sync your history and manage account',
                          color: AppTheme.accent,
                          textColor: textIconColor,
                          mutedColor: mutedColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                });
              }).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 28),
              _buildSectionHeader('About', mutedColor),
              const SizedBox(height: 8),
              _buildSection(
                children: [
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we collect and use your data',
                    color: textIconColor,
                    textColor: textIconColor,
                    mutedColor: mutedColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.gavel_rounded,
                    title: 'Terms & Conditions',
                    subtitle: 'Rules and responsibilities for app usage',
                    color: textIconColor,
                    textColor: textIconColor,
                    mutedColor: mutedColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen(),
                      ),
                    ),
                  ),
                  Divider(color: dividerColor, height: 1),
                  _buildSettingsTile(
                    assetIconPath: 'assets/icons/bug.png',
                    title: 'Report an Issue',
                    subtitle: 'Tell us what went wrong in the app',
                    color: textIconColor,
                    textColor: textIconColor,
                    mutedColor: mutedColor,
                    onTap: () => AppIssueReportSheet.show(context),
                  ),
                ],
              ).animate().fadeIn(delay: 240.ms),
              const SizedBox(height: 28),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: color,
      ),
    ).animate().fadeIn();
  }

  Widget _buildSubscriptionCard({
    required PremiumController premiumController,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    final planId = premiumController.subscriptionPlanId.value;
    final isOneTime = premiumController.purchaseType.value == 'one_time';
    final billingPeriod = premiumController.subscriptionBillingPeriod.value;
    final amountPaise = premiumController.subscriptionAmountPaise.value;
    final planName = switch (planId) {
      'lite_weekly' => 'Slipe AI Lite Weekly',
      'lite_monthly' => 'Slipe AI Lite Monthly',
      'lite_yearly' => 'Slipe AI Lite Yearly',
      'pro_monthly' => 'Slipe AI Pro Monthly',
      'pro_yearly' => 'Slipe AI Pro Yearly',
      'max' => 'Slipe AI Pro Yearly (existing plan)',
      _ => 'Slipe AI Pro Monthly (existing plan)',
    };
    final billingCycle = isOneTime
        ? '7 days (one-time)'
        : billingPeriod == 'yearly'
            ? 'Yearly'
            : 'Monthly';
    final price = amountPaise == null || billingPeriod.isEmpty
        ? 'Current subscription'
        : '₹${(amountPaise / 100).toStringAsFixed(amountPaise % 100 == 0 ? 0 : 2)}'
            '${isOneTime ? ' one-time' : ' / ${billingPeriod == 'yearly' ? 'year' : 'month'}'}';
    final status = premiumController.subscriptionStatus.value;
    final isCancelled = status == 'cancelled';
    final cancellationScheduled = !isOneTime &&
        (premiumController.cancelAtPeriodEnd.value || isCancelled);
    final isTrial = premiumController.isTrialActive.value;

    final statusLabel = cancellationScheduled
        ? isCancelled
            ? 'Cancelled'
            : 'Ends soon'
        : isTrial
            ? 'Free trial'
            : status == 'active' || status == 'prepaid_active'
                ? 'Active'
                : _readableStatus(status);
    final statusColor = cancellationScheduled
        ? AppTheme.danger
        : isTrial
            ? AppTheme.accent
            : AppTheme.success;

    final relevantDate = isOneTime
        ? premiumController.subscriptionAccessUntil.value
        : cancellationScheduled
            ? premiumController.subscriptionAccessUntil.value ??
                premiumController.subscriptionCurrentPeriodEnd.value
            : isTrial
                ? premiumController.subscriptionTrialEndsAt.value
                : premiumController.subscriptionCurrentPeriodEnd.value;
    final dateLabel = isOneTime
        ? 'Access until'
        : cancellationScheduled
            ? 'Access until'
            : isTrial
                ? 'Trial ends'
                : 'Next billing date';

    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cancellationScheduled && relevantDate != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Subscription cancelled. Premium stays active until '
                '${DateFormat('d MMM yyyy').format(relevantDate.toLocal())}. '
                'You will not be charged.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: borderColor),
          ),
          _buildSubscriptionDetail(
            label: 'Plan',
            value: planName,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          _buildSubscriptionDetail(
            label: 'Billing cycle',
            value: billingCycle,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          _buildSubscriptionDetail(
            label: 'Subscription status',
            value: statusLabel,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          if (relevantDate != null)
            _buildSubscriptionDetail(
              label: dateLabel,
              value: DateFormat('d MMM yyyy').format(relevantDate.toLocal()),
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          _buildSubscriptionDetail(
            label: 'Auto-renewal',
            value: isOneTime
                ? 'Not applicable'
                : cancellationScheduled
                    ? 'Turned off'
                    : 'Enabled',
            textColor: textColor,
            mutedColor: mutedColor,
            showBottomSpacing: false,
          ),
          if (!isOneTime && !cancellationScheduled) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: premiumController.isCancellingSubscription.value
                    ? null
                    : () => _confirmCancellation(premiumController),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: BorderSide(
                    color: AppTheme.danger.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: premiumController.isCancellingSubscription.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Cancel subscription',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ] else if (relevantDate != null) ...[
            const SizedBox(height: 14),
            Text(
              'Your premium features remain available until the date shown '
              'above. You will not be charged again.',
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.45,
                color: mutedColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetail({
    required String label,
    required String value,
    required Color textColor,
    required Color mutedColor,
    bool showBottomSpacing = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: showBottomSpacing ? 12 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _readableStatus(String status) {
    if (status.isEmpty || status == 'inactive') return 'Inactive';
    return status
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Widget _buildSection({
    required List<Widget> children,
  }) {
    return Column(children: children);
  }

  Widget _buildSettingsTile({
    IconData? icon,
    String? assetIconPath,
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    required Color mutedColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      minLeadingWidth: 28,
      splashColor: textColor.withValues(alpha: 0.04),
      leading: assetIconPath != null
          ? Image.asset(assetIconPath, width: 20, height: 20, color: color)
          : Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: mutedColor,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: mutedColor.withValues(alpha: 0.7),
      ),
    );
  }
}
