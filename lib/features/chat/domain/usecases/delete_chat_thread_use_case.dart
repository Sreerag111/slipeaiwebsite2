import '../repositories/chat_repository.dart';

class DeleteChatThreadUseCase {
  const DeleteChatThreadUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String threadId) => _repository.deleteChatThread(threadId);
}

