import 'package:flutter/material.dart';
import 'package:plagiarism_checker/theme/app_theme.dart';

class SuspiciousSection {
  const SuspiciousSection({
    required this.text,
    required this.reason,
    required this.confidenceLevel,
    required this.suggestion,
  });

  factory SuspiciousSection.fromJson(Map<String, dynamic> json) {
    return SuspiciousSection(
      text: json['text'] ?? '',
      reason: json['reason'] ?? '',
      confidenceLevel: (json['confidence_level'] as num? ?? 0).toDouble(),
      suggestion: json['suggestion'] ?? '',
    );
  }

  final String text;
  final String reason;
  final double confidenceLevel;
  final String suggestion;

  Map<String, dynamic> toJson() => {
        'text': text,
        'reason': reason,
        'confidence_level': confidenceLevel,
        'suggestion': suggestion,
      };
}

class PlagiarismResult {
  const PlagiarismResult({
    required this.plagiarismScore,
    required this.originalityScore,
    required this.overallAssessment,
    required this.suspiciousSections,
    required this.keyFindings,
    required this.languageStyle,
    required this.detectedLanguage,
    required this.wordCount,
    required this.timestamp,
    required this.detailedAnalysis,
  });

  factory PlagiarismResult.fromJson(Map<String, dynamic> json) {
    return PlagiarismResult(
      plagiarismScore: (json['plagiarism_score'] as num).toDouble(),
      originalityScore: (json['originality_score'] as num).toDouble(),
      overallAssessment: json['overall_assessment'] ?? '',
      suspiciousSections: (json['suspicious_sections'] as List<dynamic>? ?? [])
          .map((item) => SuspiciousSection.fromJson(item))
          .toList(),
      keyFindings: List<String>.from(json['key_findings'] ?? const <String>[]),
      languageStyle: json['language_style'] ?? '',
      detectedLanguage: json['detected_language'] ?? 'English',
      wordCount: json['word_count'] ?? 0,
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      detailedAnalysis: Map<String, dynamic>.from(
        json['detailed_analysis'] ?? const <String, dynamic>{},
      ),
    );
  }

  final double plagiarismScore;
  final double originalityScore;
  final String overallAssessment;
  final List<SuspiciousSection> suspiciousSections;
  final List<String> keyFindings;
  final String languageStyle;
  final String detectedLanguage;
  final int wordCount;
  final String timestamp;
  final Map<String, dynamic> detailedAnalysis;

  Map<String, dynamic> toJson() => {
        'plagiarism_score': plagiarismScore,
        'originality_score': originalityScore,
        'overall_assessment': overallAssessment,
        'suspicious_sections':
            suspiciousSections.map((item) => item.toJson()).toList(),
        'key_findings': keyFindings,
        'language_style': languageStyle,
        'detected_language': detectedLanguage,
        'word_count': wordCount,
        'timestamp': timestamp,
        'detailed_analysis': detailedAnalysis,
      };

  String get riskLevel {
    if (plagiarismScore >= 70) {
      return 'HIGH RISK';
    }
    if (plagiarismScore >= 40) {
      return 'MEDIUM RISK';
    }
    if (plagiarismScore >= 20) {
      return 'LOW RISK';
    }
    return 'MINIMAL RISK';
  }

  Color get riskColor {
    if (plagiarismScore >= 70) {
      return const Color(0xFFEF4444);
    }
    if (plagiarismScore >= 40) {
      return const Color(0xFFF59E0B);
    }
    if (plagiarismScore >= 20) {
      return AppTheme.accent;
    }
    return const Color(0xFF10B981);
  }
}
