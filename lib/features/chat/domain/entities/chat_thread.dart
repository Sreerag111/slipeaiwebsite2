import 'app_mode.dart';
import 'chat_message.dart';

class ChatThread {
  const ChatThread({
    required this.conversationId,
    required this.title,
    required this.mode,
    required this.updatedAt,
    required this.messages,
  });

  final String conversationId;
  final String title;
  final AppMode mode;
  final String updatedAt;
  final List<ChatMessage> messages;

  String get id => conversationId;
}

