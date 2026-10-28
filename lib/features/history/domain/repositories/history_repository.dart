import '../entities/history_item.dart';
import '../../../chat/domain/entities/plagiarism_result.dart';

abstract class HistoryRepository {
  Future<List<HistoryItem>> getHistory();

  Future<void> savePlagiarismHistory({
    required String text,
    required PlagiarismResult result,
  });

  Future<void> saveChatHistory({
    required String prompt,
    required String response,
    required String type,
    String detectedLanguage = 'English',
    String? conversationId,
  });

  Future<void> clearHistory();

  Future<void> deleteHistoryItem(String historyId);
}

