import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../../../chat/data/datasources/chat_storage_data_source.dart';
import '../../../chat/domain/entities/plagiarism_result.dart';
import 'history_item_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._storageDataSource);

  final ChatStorageDataSource _storageDataSource;

  @override
  Future<List<HistoryItem>> getHistory() => _storageDataSource.getHistory();

  @override
  Future<void> savePlagiarismHistory({
    required String text,
    required PlagiarismResult result,
  }) {
    final item = HistoryItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'plagiarism',
      textSnippet: _snippet(text),
      plagiarismScore: result.plagiarismScore,
      timestamp: result.timestamp,
      detectedLanguage: result.detectedLanguage,
      responseSnippet: _snippet(result.overallAssessment),
      fullText: text,
      fullResponse: result.overallAssessment,
    );
    return _storageDataSource.saveHistoryItem(item);
  }

  @override
  Future<void> saveChatHistory({
    required String prompt,
    required String response,
    required String type,
    String detectedLanguage = 'English',
    String? conversationId,
  }) {
    final item = HistoryItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      textSnippet: _snippet(prompt),
      plagiarismScore: null,
      timestamp: DateTime.now().toIso8601String(),
      detectedLanguage: detectedLanguage,
      responseSnippet: _snippet(response),
      fullText: prompt,
      fullResponse: response,
      conversationId: conversationId,
    );
    return _storageDataSource.saveHistoryItem(item);
  }

  @override
  Future<void> clearHistory() => _storageDataSource.clearHistory();

  @override
  Future<void> deleteHistoryItem(String historyId) {
    return _storageDataSource.deleteHistoryItem(historyId);
  }

  String _snippet(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 100) {
      return trimmed;
    }
    return '${trimmed.substring(0, 100)}...';
  }
}

