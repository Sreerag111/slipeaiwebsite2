class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.type,
    required this.textSnippet,
    this.plagiarismScore,
    required this.timestamp,
    required this.detectedLanguage,
    this.responseSnippet,
    this.fullText,
    this.fullResponse,
    this.conversationId,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
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

  final String id;
  final String type;
  final String textSnippet;
  final double? plagiarismScore;
  final String timestamp;
  final String detectedLanguage;
  final String? responseSnippet;
  final String? fullText;
  final String? fullResponse;
  final String? conversationId;

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
