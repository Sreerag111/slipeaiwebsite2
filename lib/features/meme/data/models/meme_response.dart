class MemeResponse {
  final bool success;
  final String url;
  final String imageUrl;
  final String videoUrl;
  final String caption;
  final String prompt;
  final String format;
  final bool isVideo;
  final bool isGif;
  final int duration;
  final int creditsUsed;

  const MemeResponse({
    required this.success,
    required this.url,
    required this.imageUrl,
    required this.videoUrl,
    required this.caption,
    required this.prompt,
    this.format = 'video',
    this.isVideo = true,
    this.isGif = false,
    this.duration = 8,
    required this.creditsUsed,
  });

  factory MemeResponse.fromMap(Map<String, dynamic> map) {
    final rawUrl = map['url'] as String? ??
        map['videoUrl'] as String? ??
        map['imageUrl'] as String? ??
        '';
    final fmt = (map['format'] as String?)?.toLowerCase() ??
        (rawUrl.endsWith('.gif') ? 'gif' : 'video');
    final isG = map['isGif'] as bool? ?? (fmt == 'gif');
    final isV = map['isVideo'] as bool? ?? (fmt == 'video');

    return MemeResponse(
      success: map['success'] as bool? ?? true,
      url: rawUrl,
      imageUrl: map['imageUrl'] as String? ?? (isG ? rawUrl : ''),
      videoUrl: map['videoUrl'] as String? ?? (isV ? rawUrl : ''),
      caption: map['caption'] as String? ?? '',
      prompt: map['prompt'] as String? ?? '',
      format: fmt,
      isVideo: isV,
      isGif: isG,
      duration: map['duration'] as int? ?? 8,
      creditsUsed: map['creditsUsed'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'url': url,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'caption': caption,
      'prompt': prompt,
      'format': format,
      'isVideo': isVideo,
      'isGif': isGif,
      'duration': duration,
      'creditsUsed': creditsUsed,
    };
  }
}
