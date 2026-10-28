import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/theme_controller.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final textIconColor = isDark ? Colors.white : Colors.black;
      final mutedColor = isDark ? Colors.white54 : Colors.black;
      final bodyTextColor = isDark ? Colors.white70 : Colors.black;
      final bg = isDark ? Colors.black : const Color(0xFFF8FAFC);
      final cardColor =
          isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white;
      final cardBorder =
          isDark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1);

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
            'PRIVACY POLICY',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textIconColor,
              letterSpacing: 1.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 0.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: cardBorder,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: isDark
                            ? null
                            : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(Icons.shield_outlined,
                          color: textIconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy Policy',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textIconColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pace AI Technologies (OPC) Private Limited',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Effective Date: October 27, 2026',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 1
              _sectionCard(
                number: '1',
                title: 'Introduction',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'Pace AI Technologies (OPC) Private Limited (“we,” “our,” or “us”) operates Slipe AI, an AI-powered application that provides AI image generation, photo enhancement, and video enhancement services.\n\n'
                    'This Privacy Policy explains how Slipe AI collects, uses, processes, stores, and shares information when you use our mobile application, website, and related services.\n\n'
                    'By using Slipe AI, you acknowledge this Privacy Policy. Where applicable law requires consent, we will obtain it separately.',
              ),

              // Section 2
              _sectionCard(
                number: '2',
                title: 'Information We May Collect',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'Depending on the features you use and the permissions you grant, we may collect the following information:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 12),
                    _subheading('A. Personal Information', textIconColor),
                    const SizedBox(height: 6),
                    _bulletPoint(
                      'Account information: Your name, email address, profile image, and authentication identifiers when you sign in using Google or another supported authentication provider.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Support communications: Information you provide when contacting our support team.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 12),
                    _subheading('B. Photos, Images, and Videos', textIconColor),
                    const SizedBox(height: 6),
                    _bodyText(
                      'When you use our AI features, you may select and upload photos, images, or videos for processing, including:\n'
                      '• AI image generation and generated images.\n'
                      '• Photo enhancement, upscaling, colourisation, sharpening, restoration, lighting correction, and background removal.\n'
                      '• Video enhancement, denoising, colourisation, upscaling, and slow-motion processing.\n\n'
                      'We process these files to provide the features you request. Depending on the service used, your files may be transmitted securely to our servers or third-party AI processing providers.\n\n'
                      'Please do not upload content you do not have the right to use or content containing sensitive information unless you understand and accept the associated risks.',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 12),
                    _subheading(
                        'C. Device and Usage Information', textIconColor),
                    const SizedBox(height: 6),
                    _bulletPoint(
                      'Device model, operating system, and app version.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'App activity, feature usage, and diagnostic information.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Crash reports, performance data, and error logs.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Advertising identifiers and advertising interaction data, where applicable.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 12),
                    _subheading('D. Payment Information', textIconColor),
                    const SizedBox(height: 6),
                    _bodyText(
                      'Some Slipe AI features may require payment. Payments may be processed by third-party payment providers, including Razorpay, where applicable.\n\n'
                      'Payment providers may process transaction identifiers, payment status, amounts, and other information needed to complete a transaction. We do not intentionally collect or store your complete card number, UPI PIN, or banking password.\n\n'
                      'Please review the relevant payment provider’s privacy policy for details of its data practices.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 3
              _sectionCard(
                number: '3',
                title: 'How We Use Your Information',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'We may use information collected through Slipe AI to:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                      'Provide AI image generation and photo and video enhancement services.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Process your uploaded files and deliver generated or enhanced results.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Authenticate users and maintain account security.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Maintain your generation history or saved results where supported.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Process payments and verify purchases.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Diagnose errors and improve app performance.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Prevent fraud, abuse, unauthorised access, and service misuse.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Respond to support requests and communicate important service updates.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Display and measure advertisements where advertising is enabled.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Meet applicable legal and regulatory obligations.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 8),
                    _bodyText(
                      'We use personal information only for purposes that are lawful and consistent with this Privacy Policy.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 4
              _sectionCard(
                number: '4',
                title: 'AI Processing and Third-Party Services',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'Slipe AI may rely on third-party providers for AI processing, cloud infrastructure, authentication, payments, analytics, and advertising.\n\n'
                      'Depending on the features enabled, these providers may include:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                      'AI processing providers: Services such as Topaz Labs or other AI model providers used to enhance images or videos.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Cloud and infrastructure providers: Services that host our application, process requests, or store data.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Authentication providers: Google sign-in or related authentication services.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Payment providers: Razorpay or other supported payment processors.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Advertising providers: Google AdMob or other advertising networks, if integrated.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Analytics and diagnostics providers: Services used to understand app performance and diagnose crashes, if integrated.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 8),
                    _bodyText(
                      'We share only the information reasonably necessary for the relevant service, subject to applicable law and the provider’s terms.\n\n'
                      'Third-party providers may process information under their own privacy policies and contractual arrangements. Their data handling practices may differ from ours.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 5
              _sectionCard(
                number: '5',
                title: 'Use of Uploaded Content',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'Your uploaded photos and videos are processed to fulfil the enhancement or generation request you initiate.\n\n'
                    'We do not claim ownership of your original photos, videos, or generated content merely because you use Slipe AI.\n\n'
                    'We do not intentionally use your private uploads to train our own AI models unless we disclose that practice and obtain any consent required by applicable law.\n\n'
                    'However, whether a third-party AI provider retains submitted content or uses it for model improvement depends on the provider, the applicable service configuration, and its contractual terms. Please consult the relevant provider’s policy for details.\n\n'
                    'Generated content may be stored temporarily or retained in your history where the feature requires it.',
              ),

              // Section 6
              _sectionCard(
                number: '6',
                title: 'Data Sharing',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'We do not sell your personal information to third parties for money.\n\n'
                      'We may disclose information to:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                      'Service providers that help operate, maintain, and deliver Slipe AI.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Payment processors to complete and verify transactions.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Advertising and analytics partners to display advertisements, measure performance, and diagnose issues, where enabled.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Legal authorities when disclosure is required by law or necessary to respond to valid legal requests.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Other parties where necessary to protect our rights, users, services, or security, in accordance with applicable law.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 8),
                    _bodyText(
                      'We do not authorise service providers to use information beyond the purposes permitted by applicable law and our relevant agreements.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 7
              _sectionCard(
                number: '7',
                title: 'Data Retention and Deletion',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'We retain information only for as long as reasonably necessary to provide our services, maintain security, comply with legal obligations, resolve disputes, and enforce our agreements.',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                      'Uploaded files: Retention depends on the processing service and whether temporary storage or history features are used.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Generated and enhanced results: These may remain in your history or storage until you delete them or the applicable retention period expires.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Account information: Retained while needed to operate your account and fulfil legal obligations.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Transaction records: May be retained for accounting, fraud prevention, tax, and legal compliance.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Technical logs: Retained for a limited period appropriate to their operational purpose.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bodyText(
                      'You may request deletion of your account and associated personal information by contacting us at the email address below. Where account deletion is supported in the app, you may also use that option.\n\n'
                      'We will process deletion requests in accordance with applicable law. Certain records may need to be retained for legitimate legal or regulatory reasons. Data held independently by third-party providers may also be subject to their own deletion procedures.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 8
              _sectionCard(
                number: '8',
                title: 'Data Security',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'We take reasonable technical and organisational measures to protect information against unauthorised access, disclosure, alteration, loss, and misuse.\n\n'
                    'Depending on the service, these measures may include access controls, secure transmission, restricted system access, and safeguards implemented by our infrastructure providers.\n\n'
                    'No method of electronic transmission or storage is completely secure. Therefore, we cannot guarantee absolute security.',
              ),

              // Section 9
              _sectionCard(
                number: '9',
                title: 'Permissions',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'Slipe AI may request access to certain device features when required for functionality, including:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                      'Photos and media: To let you select content for enhancement or save results.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Internet access: To communicate with AI processing services and deliver results.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Notifications: If enabled, to provide relevant processing updates or service notifications.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 8),
                    _bodyText(
                      'Permissions depend on your device and the app version. You can manage supported permissions through your device settings.\n\n'
                      'We aim to request only permissions necessary for the features you choose to use.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 10
              _sectionCard(
                number: '10',
                title: 'Advertising and Analytics',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'If advertising is enabled, Slipe AI may use third-party advertising services to display advertisements and measure their effectiveness. These services may collect device identifiers, ad interactions, and related technical information as permitted by their policies and applicable law.\n\n'
                    'If rewarded advertisements are offered, information about ad views or completion may be processed to provide the associated reward.\n\n'
                    'You may be able to manage advertising personalisation through your device settings or the relevant advertising provider.\n\n'
                    'If advertising is disabled or removed from a version of Slipe AI, this section applies only to advertising-related processing that continues through other enabled services.',
              ),

              // Section 11
              _sectionCard(
                number: '11',
                title: 'Children’s Privacy',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'Slipe AI is not intended for children who are below the minimum age permitted to use the service under applicable law.\n\n'
                    'We do not knowingly collect personal information from children in violation of applicable law. If you believe a child has provided personal information without the necessary authorisation, please contact us so that we can review the matter and take appropriate action.',
              ),

              // Section 12
              _sectionCard(
                number: '12',
                title: 'Your Privacy Rights',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'Depending on your location and applicable law, you may have the right to:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                      'Request access to personal information we hold about you.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Request correction of inaccurate information.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Request deletion of your personal information.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Withdraw consent where processing relies on consent.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Object to or restrict certain processing.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Request information about relevant data sharing.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Raise a complaint with the appropriate data protection authority.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 8),
                    _bodyText(
                      'To exercise these rights, contact us using the details below. We may need to verify your identity before fulfilling a request.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 13
              _sectionCard(
                number: '13',
                title: 'International Data Transfers',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'Our service providers may process information on servers located outside your country of residence.\n\n'
                    'Where information is transferred internationally, we will take steps required by applicable law to ensure that the transfer and subsequent processing are appropriately protected.',
              ),

              // Section 14
              _sectionCard(
                number: '14',
                title: 'Third-Party Websites and Services',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'Slipe AI may link to third-party websites or services, including payment gateways and AI processing providers. We do not control the privacy practices of independent third parties.\n\n'
                    'We encourage you to review their privacy policies before submitting information to them.',
              ),

              // Section 15
              _sectionCard(
                number: '15',
                title: 'Changes to This Privacy Policy',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'We may update this Privacy Policy when our features, service providers, legal obligations, or data practices change.\n\n'
                    'The updated policy will be published on our official website with a revised “Last Updated” date. Where required by law, we will provide additional notice or obtain consent before implementing material changes.',
              ),

              // Section 16 - Contact Us
              _sectionCard(
                number: '16',
                title: 'Contact Us',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                isLast: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'If you have questions about this Privacy Policy, your personal information, or a data deletion request, contact us:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 12),
                    _contactRow(
                      icon: Icons.business_outlined,
                      label: 'Company',
                      value: 'Pace AI Technologies (OPC) Private Limited',
                      textIconColor: textIconColor,
                      bodyTextColor: bodyTextColor,
                    ),
                    const SizedBox(height: 8),
                    _contactRow(
                      icon: Icons.apps_outlined,
                      label: 'Application',
                      value: 'Slipe AI',
                      textIconColor: textIconColor,
                      bodyTextColor: bodyTextColor,
                    ),
                    const SizedBox(height: 8),
                    _contactRow(
                      icon: Icons.language_outlined,
                      label: 'Website',
                      value: 'https://paceai.in',
                      textIconColor: textIconColor,
                      bodyTextColor: bodyTextColor,
                    ),
                    const SizedBox(height: 8),
                    _contactRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: 'paceai.support@gmail.com',
                      textIconColor: textIconColor,
                      bodyTextColor: bodyTextColor,
                    ),
                    const SizedBox(height: 14),
                    _bodyText(
                      'We will review privacy-related requests and respond in accordance with applicable law.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    });
  }

  Widget _subheading(String text, Color textIconColor) => Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textIconColor,
        ),
      );

  Widget _sectionCard({
    required String number,
    required String title,
    required Color cardColor,
    required bool isDark,
    required Color textIconColor,
    required Color bodyTextColor,
    String? content,
    Widget? child,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: isDark
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textIconColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textIconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (content != null) _bodyText(content, bodyTextColor),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  Widget _bodyText(String text, Color bodyTextColor) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: bodyTextColor,
          height: 1.6,
        ),
      );

  Widget _bulletPoint(String text, Color textIconColor, Color bodyTextColor) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: textIconColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: bodyTextColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textIconColor,
    required Color bodyTextColor,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textIconColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textIconColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: bodyTextColor,
              ),
            ),
          ),
        ],
      );
}
