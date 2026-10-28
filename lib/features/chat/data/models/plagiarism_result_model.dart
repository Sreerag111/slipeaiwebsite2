import '../../domain/entities/plagiarism_result.dart';

class SuspiciousSectionModel extends SuspiciousSection {
  const SuspiciousSectionModel({
    required super.text,
    required super.reason,
    required super.confidenceLevel,
    required super.suggestion,
  });

  factory SuspiciousSectionModel.fromJson(Map<String, dynamic> json) {
    return SuspiciousSectionModel(
      text: json['text'] ?? '',
      reason: json['reason'] ?? '',
      confidenceLevel: (json['confidence_level'] as num? ?? 0).toDouble(),
      suggestion: json['suggestion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'reason': reason,
        'confidence_level': confidenceLevel,
        'suggestion': suggestion,
      };
}

class PlagiarismResultModel extends PlagiarismResult {
  const PlagiarismResultModel({
    required super.plagiarismScore,
    required super.originalityScore,
    required super.overallAssessment,
    required super.suspiciousSections,
    required super.keyFindings,
    required super.languageStyle,
    required super.detectedLanguage,
    required super.wordCount,
    required super.timestamp,
    required super.detailedAnalysis,
  });

  factory PlagiarismResultModel.fromJson(Map<String, dynamic> json) {
    return PlagiarismResultModel(
      plagiarismScore: (json['plagiarism_score'] as num).toDouble(),
      originalityScore: (json['originality_score'] as num).toDouble(),
      overallAssessment: json['overall_assessment'] ?? '',
      suspiciousSections: (json['suspicious_sections'] as List<dynamic>? ?? [])
          .map((item) => SuspiciousSectionModel.fromJson(item))
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
}

