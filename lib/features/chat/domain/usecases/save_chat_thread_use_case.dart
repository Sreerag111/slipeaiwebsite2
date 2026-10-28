import '../entities/chat_thread.dart';
import '../repositories/chat_repository.dart';

class SaveChatThreadUseCase {
  const SaveChatThreadUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(ChatThread thread) => _repository.saveChatThread(thread);
}

