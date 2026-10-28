/// Result returned by the AI classifier that determines whether a user
/// message requires text, an image, a meme, or a mixed response.
class ClassificationResult {
  const ClassificationResult({
    required this.type,
    this.text = '',
    this.imagePrompt = '',
    this.memePrompt = '',
  });

  /// One of: 'text', 'image', 'meme', 'mixed'.
  final String type;

  /// Pre-written text response (for 'text' and 'mixed' types).
  final String text;

  /// Detailed DALL-E prompt (for 'image' and 'mixed' types).
  final String imagePrompt;

  /// Detailed Meme prompt (for 'meme' type).
  final String memePrompt;

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isMeme => type == 'meme';
  bool get isMixed => type == 'mixed';
  bool get needsImage => isImage || isMixed;
  bool get needsMeme => isMeme;
  bool get hasText => text.trim().isNotEmpty;

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      type: (json['type'] as String? ?? 'text').toLowerCase(),
      text: json['text'] as String? ?? '',
      imagePrompt: json['image_prompt'] as String? ?? '',
      memePrompt: json['meme_prompt'] as String? ??
          (json['prompt'] as String? ?? json['text'] as String? ?? ''),
    );
  }

  /// Fallback: treat the whole message as a plain text conversation.
  factory ClassificationResult.fallbackText() {
    return const ClassificationResult(type: 'text');
  }
}
