import '../../domain/entities/app_mode.dart';
import '../../domain/entities/chat_thread.dart';
import 'chat_message_model.dart';

class ChatThreadModel extends ChatThread {
  const ChatThreadModel({
    required super.conversationId,
    required super.title,
    required super.mode,
    required super.updatedAt,
    required super.messages,
  });

  factory ChatThreadModel.fromEntity(ChatThread thread) {
    return ChatThreadModel(
      conversationId: thread.conversationId,
      title: thread.title,
      mode: thread.mode,
      updatedAt: thread.updatedAt,
      messages: thread.messages
          .map(ChatMessageModel.fromEntity)
          .toList(growable: false),
    );
  }

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      conversationId: (json['conversation_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? 'New Chat',
      mode: _modeFromStorage(json['mode'] ?? 'chat'),
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'title': title,
        'mode': _modeToStorage(mode),
        'updated_at': updatedAt,
        'messages': messages
            .map((item) => ChatMessageModel.fromEntity(item).toJson())
            .toList(),
      };

  static AppMode _modeFromStorage(String value) {
    switch (value) {
      case 'grammar':
        return AppMode.grammar;
      case 'plagiarism':
        return AppMode.plagiarism;
      case 'home':
        return AppMode.home;
      default:
        return AppMode.chat;
    }
  }

  static String _modeToStorage(AppMode mode) {
    switch (mode) {
      case AppMode.home:
        return 'chat';
      case AppMode.plagiarism:
        return 'plagiarism';
      case AppMode.grammar:
        return 'grammar';
      case AppMode.chat:
        return 'chat';
    }
  }
}

