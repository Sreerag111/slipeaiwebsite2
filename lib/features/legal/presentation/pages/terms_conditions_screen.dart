import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/theme_controller.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
            'TERMS & CONDITIONS',
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
                      child: Icon(Icons.description_outlined,
                          color: textIconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Conditions',
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
                    'Welcome to Slipe AI.\n\n'
                    'These Terms and Conditions (“Terms”) govern your access to and use of Slipe AI, an AI-powered application operated by Pace AI Technologies (OPC) Private Limited (“Company,” “we,” “our,” or “us”).\n\n'
                    'Slipe AI provides AI image generation, photo enhancement, video enhancement, and related features.\n\n'
                    'By accessing or using Slipe AI, you agree to these Terms. If you do not agree, please discontinue using the service.',
              ),

              // Section 2
              _sectionCard(
                number: '2',
                title: 'Eligibility',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'You must meet the minimum age requirements applicable in your country to use Slipe AI.\n\n'
                    'If you are under the age of majority, you may use the service only with any parental or guardian consent required by applicable law.\n\n'
                    'By using Slipe AI, you confirm that you are legally permitted to accept these Terms.',
              ),

              // Section 3
              _sectionCard(
                number: '3',
                title: 'Our Services',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'Slipe AI may offer the following features, depending on the version of the application:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                        'AI image generation.', textIconColor, bodyTextColor),
                    _bulletPoint('Photo enhancement and upscaling.',
                        textIconColor, bodyTextColor),
                    _bulletPoint('Black-and-white photo colourisation.',
                        textIconColor, bodyTextColor),
                    _bulletPoint(
                        'Photo restoration, including dust and scratch correction.',
                        textIconColor,
                        bodyTextColor),
                    _bulletPoint(
                        'Image sharpening, lighting correction, and colour balancing.',
                        textIconColor,
                        bodyTextColor),
                    _bulletPoint('Background removal and photo cleanup.',
                        textIconColor, bodyTextColor),
                    _bulletPoint(
                        'AI video enhancement, including denoising, colourisation, upscaling, and slow motion.',
                        textIconColor,
                        bodyTextColor),
                    _bulletPoint(
                        'Additional AI-powered features introduced in future updates.',
                        textIconColor,
                        bodyTextColor),
                    const SizedBox(height: 10),
                    _bodyText(
                      'Features, supported formats, processing limits, and availability may change over time.\n\n'
                      'We may update, improve, suspend, or discontinue particular features where reasonably necessary for operational, technical, security, commercial, or legal reasons.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 4
              _sectionCard(
                number: '4',
                title: 'AI-Generated and Enhanced Content',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'Slipe AI uses artificial intelligence and automated processing to generate or modify digital content.\n\n'
                      'You acknowledge that:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                      'AI-generated results may vary depending on the input, model, and processing settings.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Enhancements may introduce inaccuracies, visual artefacts, or unintended changes.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'We cannot guarantee that every result will be realistic, accurate, or suitable for a particular purpose.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Enhanced images and videos may differ from their original versions.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Processing quality may depend on the source file’s resolution, condition, lighting, and other factors.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bodyText(
                      'Although we aim to produce natural-looking results and preserve important details, we cannot guarantee perfect restoration or exact preservation of every facial feature, object, or original detail.\n\n'
                      'You are responsible for reviewing generated or enhanced content before using or sharing it.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 5
              _sectionCard(
                number: '5',
                title: 'User Content and Ownership',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'You retain any ownership rights you have in the photos, videos, images, and other materials you upload to Slipe AI.\n\n'
                    'Subject to applicable law and any third-party rights, you may use the generated or enhanced results for lawful personal or commercial purposes.\n\n'
                    'You are responsible for ensuring that your use of uploaded and generated content complies with applicable laws, intellectual property rights, privacy rights, publicity rights, and third-party terms.\n\n'
                    'By uploading content, you grant us and the service providers involved in fulfilling your request a limited, non-exclusive right to process, transmit, and temporarily store that content as reasonably necessary to provide, secure, and maintain the requested service.\n\n'
                    'We do not acquire ownership of your original content merely because you upload it.\n\n'
                    'Any rights in generated outputs remain subject to applicable law, the capabilities of the AI service, and third-party model or provider terms.',
              ),

              // Section 6
              _sectionCard(
                number: '6',
                title: 'Acceptable Use',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'You agree not to use Slipe AI to:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                      'Violate applicable laws or regulations.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Infringe another person’s copyright, trademark, privacy, or other legal rights.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Create or distribute deceptive, fraudulent, defamatory, or unlawfully impersonating content.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Create or distribute non-consensual intimate imagery or exploitative content.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Generate sexual content involving minors or other unlawful exploitative material.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Create content intended to facilitate fraud, harassment, threats, or malicious activities.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Upload malware or attempt to compromise our systems.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Reverse engineer, disrupt, abuse, or circumvent the security or technical limitations of the service, except where applicable law permits.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Bypass payment requirements, manipulate rewards, or exploit service vulnerabilities.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Use automated methods to access or overload our services without our authorisation.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bodyText(
                      'We may restrict access, suspend accounts, or take other appropriate action when we reasonably believe these Terms have been violated or action is required by law.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 7
              _sectionCard(
                number: '7',
                title: 'Payments, Pricing, and Paid Features',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'Certain features of Slipe AI may require payment.\n\n'
                      'Prices, payment terms, processing limits, and any applicable subscription details will be presented in the relevant purchase interface.\n\n'
                      'Depending on the feature and offer, payment may be charged per enhancement, through a subscription, or using another disclosed pricing model.',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 14),
                    _subheading('A. Payment Processing', textIconColor),
                    const SizedBox(height: 6),
                    _bodyText(
                      'Payments may be handled by third-party payment providers, such as Razorpay, or through an applicable app store billing system.\n\n'
                      'You agree to provide accurate information required to complete your purchase. Payment providers and app stores may apply their own terms and conditions.',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 14),
                    _subheading('B. Paid Processing', textIconColor),
                    const SizedBox(height: 6),
                    _bodyText(
                      'Where a feature requires payment, the applicable price and processing conditions will be disclosed before purchase.\n\n'
                      'A payment may authorise a specified enhancement, processing request, subscription period, or other clearly described entitlement. Payment for one request does not automatically provide unlimited access unless the purchase description explicitly states otherwise.',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 14),
                    _subheading('C. Subscriptions and Renewals', textIconColor),
                    const SizedBox(height: 6),
                    _bodyText(
                      'If Slipe AI offers subscriptions, the purchase screen will specify the price, duration, renewal terms, and cancellation process where applicable.\n\n'
                      'Subscriptions may renew automatically when the relevant billing system supports recurring billing and automatic renewal has been disclosed and authorised.\n\n'
                      'You are responsible for cancelling a subscription through the relevant billing provider before the renewal date if you do not wish to continue.',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 14),
                    _subheading('D. Refunds', textIconColor),
                    const SizedBox(height: 6),
                    _bodyText(
                      'Refund requests will be handled in accordance with applicable consumer protection laws and the refund policies of the payment provider or app store through which the purchase was made.\n\n'
                      'Where processing fails, a charge is duplicated, or a paid service is not delivered as promised, you may contact us to request a review and appropriate resolution.\n\n'
                      'Nothing in these Terms excludes any refund or other remedy that you are legally entitled to receive.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 8
              _sectionCard(
                number: '8',
                title: 'Free Features, Promotions, and Rewards',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'We may offer free processing, trial features, promotional offers, or rewarded advertisements.\n\n'
                    'These offers may have usage limits, eligibility conditions, expiry dates, or other restrictions disclosed when offered.\n\n'
                    'We may change or discontinue promotional offers prospectively, subject to applicable law and any commitments already made to users.\n\n'
                    'A promotional entitlement does not guarantee continued free access to a feature.',
              ),

              // Section 9
              _sectionCard(
                number: '9',
                title: 'Processing Times and Availability',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'AI processing may be affected by file size, queue length, network conditions, third-party provider availability, and technical limitations.\n\n'
                    'We do not guarantee uninterrupted service, specific processing times, or the availability of every feature at all times.\n\n'
                    'If processing fails, the available remedy may depend on the purchase terms, the cause of the failure, and applicable law.',
              ),

              // Section 10
              _sectionCard(
                number: '10',
                title: 'Third-Party Services',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'Slipe AI may rely on third-party AI models, cloud infrastructure, authentication services, payment processors, advertising networks, and other external services.\n\n'
                    'Your use of those services may be subject to separate terms and privacy policies.\n\n'
                    'We are not responsible for independent third-party services beyond the responsibilities imposed on us by applicable law. We will take reasonable steps to address issues relating to services that we control.',
              ),

              // Section 11
              _sectionCard(
                number: '11',
                title: 'Intellectual Property',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'Slipe AI, including its software, branding, interface, logos, website, and original materials, is owned by or licensed to the Company and protected by applicable intellectual property laws.\n\n'
                    'Except as expressly permitted by law or authorised by us, you may not copy, distribute, modify, sell, sublicense, or commercially exploit our software or proprietary materials.\n\n'
                    'These Terms do not transfer ownership of the Company’s intellectual property to you.',
              ),

              // Section 12
              _sectionCard(
                number: '12',
                title: 'Privacy and Data Protection',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'Your use of Slipe AI is also governed by our Privacy Policy, available at:\n'
                    'https://paceai.in/privacy-policy\n\n'
                    'The Privacy Policy explains how we collect, use, process, store, and share information.\n\n'
                    'By using the service, you acknowledge that you have had the opportunity to review the Privacy Policy. Where legally required, we will obtain consent separately.',
              ),

              // Section 13
              _sectionCard(
                number: '13',
                title: 'Suspension and Termination',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'You may stop using Slipe AI at any time.\n\n'
                    'We may suspend or restrict access if reasonably necessary to address violations of these Terms, fraud, security risks, non-payment, misuse, or legal obligations.\n\n'
                    'Where appropriate and legally required, we will provide notice and an opportunity to resolve the issue.\n\n'
                    'Termination does not remove rights or obligations that accrued before termination, including applicable payment obligations, refund rights, and legally required record-retention obligations.',
              ),

              // Section 14
              _sectionCard(
                number: '14',
                title: 'Disclaimers',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'To the extent permitted by applicable law, Slipe AI is provided on an “as available” basis.\n\n'
                      'We do not guarantee that:',
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bulletPoint(
                      'Every AI output will be accurate, realistic, or error-free.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Every uploaded photo or video can be fully restored.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'The service will always be uninterrupted or compatible with every device.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    _bulletPoint(
                      'Generated content will meet every user’s expectations or professional requirements.',
                      textIconColor,
                      bodyTextColor,
                    ),
                    const SizedBox(height: 10),
                    _bodyText(
                      'You should independently verify important content before relying on it for legal, financial, medical, professional, or other consequential decisions.\n\n'
                      'Nothing in these Terms excludes warranties or protections that cannot legally be excluded.',
                      bodyTextColor,
                    ),
                  ],
                ),
              ),

              // Section 15
              _sectionCard(
                number: '15',
                title: 'Limitation of Liability',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'To the extent permitted by applicable law, the Company will not be liable for indirect, incidental, special, or consequential losses arising from your use of Slipe AI, including loss of anticipated profits, business opportunities, or data, where such exclusions are legally permitted.\n\n'
                    'Our liability for direct loss will be determined in accordance with applicable law and the circumstances of the claim.\n\n'
                    'Nothing in these Terms limits liability where such limitation is prohibited by law, including applicable rights relating to consumer protection, fraud, or wilful misconduct.',
              ),

              // Section 16
              _sectionCard(
                number: '16',
                title: 'Indemnity',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'To the extent permitted by applicable law, you are responsible for losses, claims, and reasonable expenses arising from your unlawful use of Slipe AI, your infringement of third-party rights, or your material violation of these Terms.\n\n'
                    'This provision does not apply to the extent a claim results from our own unlawful conduct or where applicable law prohibits such an allocation of responsibility.',
              ),

              // Section 17
              _sectionCard(
                number: '17',
                title: 'Changes to These Terms',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'We may update these Terms to reflect changes in our services, pricing, technology, business operations, or legal obligations.\n\n'
                    'Updated Terms will be published on our website with a revised “Last Updated” date.\n\n'
                    'Where required by law, we will provide notice of material changes or obtain consent. Continued use of the service after changes take effect will constitute acceptance only to the extent permitted by applicable law.',
              ),

              // Section 18
              _sectionCard(
                number: '18',
                title: 'Governing Law and Disputes',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                content:
                    'These Terms are governed by the laws of India, subject to any mandatory consumer protection or other legal rights applicable to you.\n\n'
                    'Disputes will be addressed through the dispute resolution mechanisms available under applicable Indian law. Nothing in these Terms prevents a consumer from approaching a competent court, consumer commission, or other authority where legally entitled to do so.',
              ),

              // Section 19 - Contact Information
              _sectionCard(
                number: '19',
                title: 'Contact Information',
                cardColor: cardColor,
                isDark: isDark,
                textIconColor: textIconColor,
                bodyTextColor: bodyTextColor,
                isLast: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bodyText(
                      'For questions, complaints, payment concerns, or requests relating to these Terms, contact us:',
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
                      'We will review enquiries and respond in accordance with applicable law.\n\n'
                      'By using Slipe AI, you agree to comply with these Terms and Conditions, subject to your rights under applicable law.',
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
