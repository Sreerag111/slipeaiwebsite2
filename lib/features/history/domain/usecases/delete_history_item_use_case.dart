import '../repositories/history_repository.dart';

class DeleteHistoryItemUseCase {
  const DeleteHistoryItemUseCase(this._repository);

  final HistoryRepository _repository;

  Future<void> call(String historyId) => _repository.deleteHistoryItem(historyId);
}

