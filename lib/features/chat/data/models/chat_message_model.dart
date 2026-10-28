import '../../domain/entities/app_mode.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_attachment_model.dart';
import 'chat_source_model.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.text,
    required super.isUser,
    super.isError,
    super.mode,
    super.attachments,
    super.animate,
    super.createdAt,
    super.generatedImageUrl,
    super.imagePrompt,
    super.generatedVideoUrl,
    super.videoPrompt,
    super.videoDuration,
    super.persistedImageUrls,
    super.sources,
  });

  factory ChatMessageModel.fromEntity(ChatMessage message) {
    return ChatMessageModel(
      text: message.text,
      isUser: message.isUser,
      isError: message.isError,
      mode: message.mode,
      attachments: message.attachments
          .map(ChatAttachmentModel.fromEntity)
          .toList(growable: false),
      animate: message.animate,
      createdAt: message.createdAt,
      generatedImageUrl: message.generatedImageUrl,
      imagePrompt: message.imagePrompt,
      generatedVideoUrl: message.generatedVideoUrl,
      videoPrompt: message.videoPrompt,
      videoDuration: message.videoDuration,
      persistedImageUrls: message.persistedImageUrls,
      sources: message.sources
          .map(ChatSourceModel.fromEntity)
          .toList(growable: false),
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      text: json['text'] ?? '',
      isUser: json['is_user'] ?? false,
      isError: json['is_error'] ?? false,
      mode: _modeFromStorage(json['mode'] as String?),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map(
            (item) => ChatAttachmentModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      animate: json['animate'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      generatedImageUrl: json['generated_image_url'] as String?,
      imagePrompt: json['image_prompt'] as String?,
      generatedVideoUrl: json['generated_video_url'] as String?,
      videoPrompt: json['video_prompt'] as String?,
      videoDuration: json['video_duration'] as int?,
      persistedImageUrls: (json['persisted_image_urls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      sources: (json['sources'] as List<dynamic>? ?? [])
          .map(
            (item) => ChatSourceModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    // Never store raw base64 image data in Firestore — it easily exceeds the
    // 1 MB document limit and causes [invalid-argument] errors.
    // Instead, persist only a flag + the prompt so the image can be
    // re-generated on demand if needed.
    final isBase64 = generatedImageUrl != null &&
        generatedImageUrl!.startsWith('data:image/');
    return {
      'text': text,
      'is_user': isUser,
      'is_error': isError,
      'mode': mode == null ? null : _modeToStorage(mode!),
      'attachments': attachments
          .map((item) => ChatAttachmentModel.fromEntity(item).toJson())
          .toList(),
      'animate': animate,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      // Store the URL only if it is a remote URL (not a base64 blob).
      'generated_image_url': isBase64 ? null : generatedImageUrl,
      'has_generated_image': generatedImageUrl != null,
      'image_prompt': imagePrompt,
      'generated_video_url': generatedVideoUrl,
      'has_generated_video': generatedVideoUrl != null,
      'video_prompt': videoPrompt,
      'video_duration': videoDuration,
      'persisted_image_urls': persistedImageUrls,
      'sources': sources
          .map((item) => ChatSourceModel.fromEntity(item).toJson())
          .toList(),
    };
  }

  static AppMode? _modeFromStorage(String? value) {
    switch (value) {
      case 'plagiarism':
        return AppMode.plagiarism;
      case 'grammar':
        return AppMode.grammar;
      case 'chat':
        return AppMode.chat;
      case 'home':
        return AppMode.home;
      default:
        return null;
    }
  }

  static String _modeToStorage(AppMode value) {
    switch (value) {
      case AppMode.home:
        return 'home';
      case AppMode.plagiarism:
        return 'plagiarism';
      case AppMode.grammar:
        return 'grammar';
      case AppMode.chat:
        return 'chat';
    }
  }
}
