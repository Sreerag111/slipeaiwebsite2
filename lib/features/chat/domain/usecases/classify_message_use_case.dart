import '../entities/chat_message.dart';
import '../entities/classification_result.dart';
import '../repositories/chat_repository.dart';

class ClassifyMessageUseCase {
  const ClassifyMessageUseCase({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  final ChatRepository _chatRepository;

  Future<ClassificationResult> call({
    required String message,
    required List<ChatMessage> history,
  }) =>
      _chatRepository.classifyMessage(message: message, history: history);
}
