import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/theme_controller.dart';
import '../../domain/entities/plagiarism_result.dart';
import '../widgets/result_widgets.dart';

class ResultScreen extends StatefulWidget {
  final PlagiarismResult result;
  final String originalText;

  const ResultScreen({
    super.key,
    required this.result,
    required this.originalText,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black,
              size: 18,
            ),
          ),
          title: Text(
            'ANALYSIS REPORT',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _shareReport(result),
              icon: Icon(
                Icons.share_outlined,
                color: isDark ? const Color(0xFF8E8E93) : Colors.black,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Score summary header
            _buildScoreHeader(result, isDark),
            // Tab bar
            Container(
              color: isDark ? const Color(0xFF121214) : Colors.white,
              child: TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
                labelColor: AppTheme.accent,
                unselectedLabelColor:
                    isDark ? const Color(0xFF8E8E93) : Colors.black,
                indicatorColor: AppTheme.accent,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'FINDINGS'),
                  Tab(text: 'DETAILS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(result, isDark),
                  _buildFindingsTab(result, isDark),
                  _buildDetailsTab(result, isDark),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildScoreHeader(PlagiarismResult result, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121214) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ScoreGauge(
                score: result.plagiarismScore,
                label: 'PLAGIARISM',
                color: result.riskColor,
              ).animate().scale(
                  begin: const Offset(0, 0),
                  curve: Curves.elasticOut,
                  duration: 800.ms),
              Column(
                children: [
                  RiskBadge(
                    riskLevel: result.riskLevel,
                    color: result.riskColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.detectedLanguage,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.wordCount} words',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF636366) : Colors.black,
                    ),
                  ),
                ],
              ),
              ScoreGauge(
                score: result.originalityScore,
                label: 'ORIGINALITY',
                color: AppTheme.success,
              ).animate().scale(
                  begin: const Offset(0, 0),
                  curve: Curves.elasticOut,
                  duration: 800.ms,
                  delay: 200.ms),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(PlagiarismResult result, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assessment
          GlowingCard(
            glowColor: result.riskColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI ASSESSMENT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.overallAssessment,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.6,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),

          // Language style
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161618) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.style_outlined, color: AppTheme.accent, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WRITING STYLE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                      ),
                    ),
                    Text(
                      result.languageStyle.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'AI Generated',
                  '${(result.detailedAnalysis['ai_generated_probability'] as num?)?.toInt() ?? 0}%',
                  Icons.smart_toy_outlined,
                  AppTheme.accentSecondary,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Style Match',
                  '${(result.detailedAnalysis['style_consistency'] as num?)?.toInt() ?? 0}%',
                  Icons.compare_arrows,
                  AppTheme.warning,
                  isDark,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Vocab Diversity',
                  '${(result.detailedAnalysis['vocabulary_diversity'] as num?)?.toInt() ?? 0}%',
                  Icons.spellcheck,
                  AppTheme.success,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Citations Needed',
                  '${result.detailedAnalysis['citation_needed_count'] ?? 0}',
                  Icons.format_quote,
                  AppTheme.danger,
                  isDark,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? const Color(0xFF8E8E93) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingsTab(PlagiarismResult result, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.keyFindings.isNotEmpty) ...[
            Text(
              'KEY FINDINGS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark ? const Color(0xFF8E8E93) : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...result.keyFindings.asMap().entries.map(
                  (e) => FindingChip(text: e.value, index: e.key),
                ),
            const SizedBox(height: 24),
          ],
          if (result.suspiciousSections.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'SUSPICIOUS SECTIONS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${result.suspiciousSections.length}',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...result.suspiciousSections.asMap().entries.map(
                  (e) => SuspiciousSectionCard(section: e.value, index: e.key),
                ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.check_circle_outline,
                      color: AppTheme.success, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'No suspicious sections found',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The text appears to be original',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(PlagiarismResult result, bool isDark) {
    final analysis = result.detailedAnalysis;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETAILED METRICS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF8E8E93) : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          DetailStatTile(
            label: 'Sentence Complexity',
            value: (analysis['sentence_complexity'] ?? 'N/A')
                .toString()
                .toUpperCase(),
            icon: Icons.account_tree_outlined,
          ),
          const SizedBox(height: 8),
          DetailStatTile(
            label: 'Vocabulary Diversity',
            value:
                '${(analysis['vocabulary_diversity'] as num?)?.toInt() ?? 0}%',
            icon: Icons.spellcheck,
            valueColor: AppTheme.success,
          ),
          const SizedBox(height: 8),
          DetailStatTile(
            label: 'AI-Generated Probability',
            value:
                '${(analysis['ai_generated_probability'] as num?)?.toInt() ?? 0}%',
            icon: Icons.smart_toy_outlined,
            valueColor: (analysis['ai_generated_probability'] as num? ?? 0) > 50
                ? AppTheme.danger
                : AppTheme.success,
          ),
          const SizedBox(height: 8),
          DetailStatTile(
            label: 'Paraphrasing Detected',
            value: (analysis['paraphrasing_detected'] as bool? ?? false)
                ? 'YES'
                : 'NO',
            icon: Icons.swap_horiz,
            valueColor: (analysis['paraphrasing_detected'] as bool? ?? false)
                ? AppTheme.warning
                : AppTheme.success,
          ),
          const SizedBox(height: 8),
          DetailStatTile(
            label: 'Style Consistency',
            value: '${(analysis['style_consistency'] as num?)?.toInt() ?? 0}%',
            icon: Icons.auto_graph,
          ),
          const SizedBox(height: 8),
          DetailStatTile(
            label: 'Citations Needed',
            value: '${analysis['citation_needed_count'] ?? 0}',
            icon: Icons.format_quote,
            valueColor: (analysis['citation_needed_count'] as num? ?? 0) > 0
                ? AppTheme.warning
                : AppTheme.success,
          ),
          const SizedBox(height: 24),

          // Copy report button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyReport(result, isDark),
              icon: const Icon(Icons.copy, size: 16),
              label: Text(
                'COPY FULL REPORT',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ]
            .map((w) => w is SizedBox
                ? w
                : w.animate().fadeIn(delay: 100.ms).slideX(begin: -0.05))
            .toList(),
      ),
    );
  }

  void _copyReport(PlagiarismResult result, bool isDark) {
    final report = '''PLAGIARISM ANALYSIS REPORT
Generated: ${result.timestamp}

SCORES:
• Plagiarism Score: ${result.plagiarismScore.toInt()}%
• Originality Score: ${result.originalityScore.toInt()}%
• Risk Level: ${result.riskLevel}

OVERVIEW:
${result.overallAssessment}

DETECTED LANGUAGE: ${result.detectedLanguage}
WRITING STYLE: ${result.languageStyle}
WORD COUNT: ${result.wordCount}

KEY FINDINGS:
${result.keyFindings.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

SUSPICIOUS SECTIONS: ${result.suspiciousSections.length}

DETAILED METRICS:
• Sentence Complexity: ${result.detailedAnalysis['sentence_complexity']}
• Vocabulary Diversity: ${result.detailedAnalysis['vocabulary_diversity']}%
• AI-Generated Probability: ${result.detailedAnalysis['ai_generated_probability']}%
• Paraphrasing Detected: ${result.detailedAnalysis['paraphrasing_detected']}
• Style Consistency: ${result.detailedAnalysis['style_consistency']}%
''';

    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Report copied to clipboard',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.success.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _shareReport(PlagiarismResult result) {
    final isDark = ThemeController.instance.isDarkMode;
    _copyReport(result, isDark);
  }
}
