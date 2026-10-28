import '../../../history/domain/repositories/history_repository.dart';
import '../entities/chat_completion_result.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class CheckGrammarUseCase {
  const CheckGrammarUseCase({
    required ChatRepository chatRepository,
    required HistoryRepository historyRepository,
  })  : _chatRepository = chatRepository,
        _historyRepository = historyRepository;

  final ChatRepository _chatRepository;
  final HistoryRepository _historyRepository;

  Future<ChatCompletionResult> call({
    required ChatMessage message,
    required String? conversationId,
  }) async {
    final result = await _chatRepository.checkGrammar(message: message);
    await _historyRepository.saveChatHistory(
      prompt: result.prompt,
      response: result.response,
      type: 'grammar',
      conversationId: conversationId,
    );
    return result;
  }
}

