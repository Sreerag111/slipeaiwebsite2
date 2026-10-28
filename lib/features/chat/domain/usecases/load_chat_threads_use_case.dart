import '../entities/chat_thread.dart';
import '../repositories/chat_repository.dart';

class LoadChatThreadsUseCase {
  const LoadChatThreadsUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<ChatThread>> call() => _repository.getChatThreads();
}

