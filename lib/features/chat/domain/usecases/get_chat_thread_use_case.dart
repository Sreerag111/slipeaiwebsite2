import '../entities/chat_thread.dart';
import '../repositories/chat_repository.dart';

class GetChatThreadUseCase {
  const GetChatThreadUseCase(this._repository);

  final ChatRepository _repository;

  Future<ChatThread?> call(String conversationId) =>
      _repository.getChatThread(conversationId);
}
