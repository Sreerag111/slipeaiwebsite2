import '../entities/history_item.dart';
import '../repositories/history_repository.dart';

class LoadHistoryUseCase {
  const LoadHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<List<HistoryItem>> call() => _repository.getHistory();
}

