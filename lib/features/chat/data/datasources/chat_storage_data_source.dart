import '../../../history/data/repositories/history_item_model.dart';
import '../models/chat_thread_model.dart';

abstract class ChatStorageDataSource {
  Future<List<HistoryItemModel>> getHistory();

  Future<void> saveHistoryItem(HistoryItemModel item);

  Future<void> clearHistory();

  Future<void> deleteHistoryItem(String historyId);

  Future<List<ChatThreadModel>> getChatThreads();

  Future<ChatThreadModel?> getChatThread(String conversationId);

  Future<void> saveOrUpdateChatThread(ChatThreadModel thread);

  Future<void> deleteChatThread(String threadId);
}
