import '../../../history/domain/repositories/history_repository.dart';
import '../entities/chat_completion_result.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class AnalyzePlagiarismUseCase {
  const AnalyzePlagiarismUseCase({
    required ChatRepository chatRepository,
    required HistoryRepository historyRepository,
  })  : _chatRepository = chatRepository,
        _historyRepository = historyRepository;

  final ChatRepository _chatRepository;
  final HistoryRepository _historyRepository;

  Future<PlagiarismAnalysisResult> call({
    required ChatMessage message,
    required String sourceText,
  }) async {
    final result = await _chatRepository.analyzePlagiarism(
      message: message,
      sourceText: sourceText,
    );
    await _historyRepository.savePlagiarismHistory(
      text: result.analyzedText,
      result: result.result,
    );
    return result;
  }
}

