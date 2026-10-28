import '../../domain/entities/history_item.dart';

class HistoryItemModel extends HistoryItem {
  const HistoryItemModel({
    required super.id,
    required super.type,
    required super.textSnippet,
    super.plagiarismScore,
    required super.timestamp,
    required super.detectedLanguage,
    super.responseSnippet,
    super.fullText,
    super.fullResponse,
    super.conversationId,
  });

  factory HistoryItemModel.fromEntity(HistoryItem item) {
    return HistoryItemModel(
      id: item.id,
      type: item.type,
      textSnippet: item.textSnippet,
      plagiarismScore: item.plagiarismScore,
      timestamp: item.timestamp,
      detectedLanguage: item.detectedLanguage,
      responseSnippet: item.responseSnippet,
      fullText: item.fullText,
      fullResponse: item.fullResponse,
      conversationId: item.conversationId,
    );
  }

  factory HistoryItemModel.fromJson(Map<String, dynamic> json) {
    return HistoryItemModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'plagiarism',
      textSnippet: json['text_snippet'] ?? '',
      plagiarismScore: (json['plagiarism_score'] as num?)?.toDouble(),
      timestamp: json['timestamp'] ?? '',
      detectedLanguage: json['detected_language'] ?? 'English',
      responseSnippet: json['response_snippet'],
      fullText: json['full_text'],
      fullResponse: json['full_response'],
      conversationId: json['conversation_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'text_snippet': textSnippet,
        'plagiarism_score': plagiarismScore,
        'timestamp': timestamp,
        'detected_language': detectedLanguage,
        'response_snippet': responseSnippet,
        'full_text': fullText,
        'full_response': fullResponse,
        'conversation_id': conversationId,
      };
}

