import 'app_mode.dart';
import 'chat_attachment.dart';
import 'chat_source.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.mode,
    this.attachments = const <ChatAttachment>[],
    this.animate = false,
    this.createdAt,
    this.generatedImageUrl,
    this.imagePrompt,
    this.generatedVideoUrl,
    this.videoPrompt,
    this.videoDuration,
    this.persistedImageUrls = const <String>[],
    this.sources = const <ChatSource>[],
  });

  final String text;
  final bool isUser;
  final bool isError;
  final AppMode? mode;
  final List<ChatAttachment> attachments;
  final bool animate;
  final DateTime? createdAt;

  /// URL of a DALL-E generated image attached to this message bubble.
  final String? generatedImageUrl;

  /// The prompt that was used to generate [generatedImageUrl].
  final String? imagePrompt;

  /// URL of a Veo 3.1 generated video attached to this message bubble.
  final String? generatedVideoUrl;

  /// The prompt that was used to generate [generatedVideoUrl].
  final String? videoPrompt;

  /// Duration of the generated video in seconds.
  final int? videoDuration;

  /// Firebase Storage URLs for user-uploaded images (persisted after submit).
  /// When populated, the UI shows these instead of local [attachments] paths.
  final List<String> persistedImageUrls;

  /// Verified web sources / citations used to generate this response.
  final List<ChatSource> sources;

  bool get hasGeneratedImage =>
      generatedImageUrl != null && generatedImageUrl!.isNotEmpty;

  bool get hasGeneratedVideo =>
      generatedVideoUrl != null && generatedVideoUrl!.isNotEmpty;

  bool get hasSources => sources.isNotEmpty;

  List<ChatAttachment> get images =>
      attachments.where((item) => item.isImage).toList(growable: false);

  List<ChatAttachment> get files =>
      attachments.where((item) => item.isFile).toList(growable: false);

  /// Returns a copy of this message with [persistedImageUrls] replaced.
  ChatMessage copyWithPersistedUrls(List<String> urls) {
    return ChatMessage(
      text: text,
      isUser: isUser,
      isError: isError,
      mode: mode,
      attachments: attachments,
      animate: false,
      createdAt: createdAt,
      generatedImageUrl: generatedImageUrl,
      imagePrompt: imagePrompt,
      generatedVideoUrl: generatedVideoUrl,
      videoPrompt: videoPrompt,
      videoDuration: videoDuration,
      persistedImageUrls: urls,
      sources: sources,
    );
  }
}
