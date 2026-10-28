import '../repositories/chat_repository.dart';

class CancelActiveRequestUseCase {
  const CancelActiveRequestUseCase(this._repository);

  final ChatRepository _repository;

  void call() => _repository.cancelActiveRequest();
}

