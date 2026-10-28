import 'dart:async';

import '../../../history/domain/repositories/history_repository.dart';
import '../entities/chat_completion_result.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  const SendMessageUseCase({
    required ChatRepository chatRepository,
    required HistoryRepository historyRepository,
  })  : _chatRepository = chatRepository,
        _historyRepository = historyRepository;

  final ChatRepository _chatRepository;
  final HistoryRepository _historyRepository;

  Future<ChatCompletionResult> call({
    required List<ChatMessage> messages,
    required String? conversationId,
  }) async {
    final result = await _chatRepository.sendMessage(messages: messages);
    await _historyRepository.saveChatHistory(
      prompt: result.prompt,
      response: result.response,
      type: 'chat',
      conversationId: conversationId,
    );
    return result;
  }

  Stream<String> callStreaming({
    required List<ChatMessage> messages,
  }) {
    return _chatRepository.sendMessageStreaming(messages: messages);
  }
}

