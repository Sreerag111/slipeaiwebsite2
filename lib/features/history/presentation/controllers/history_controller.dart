import 'dart:async';

import 'package:get/get.dart';

import '../../../chat/domain/usecases/delete_chat_thread_use_case.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/usecases/clear_history_use_case.dart';
import '../../domain/usecases/delete_history_item_use_case.dart';
import '../../domain/usecases/load_history_use_case.dart';

class HistoryController extends GetxController {
  HistoryController({
    required LoadHistoryUseCase loadHistoryUseCase,
    required DeleteHistoryItemUseCase deleteHistoryItemUseCase,
    required ClearHistoryUseCase clearHistoryUseCase,
    required DeleteChatThreadUseCase deleteChatThreadUseCase,
  })  : _loadHistoryUseCase = loadHistoryUseCase,
        _deleteHistoryItemUseCase = deleteHistoryItemUseCase,
        _clearHistoryUseCase = clearHistoryUseCase,
        _deleteChatThreadUseCase = deleteChatThreadUseCase;

  final LoadHistoryUseCase _loadHistoryUseCase;
  final DeleteHistoryItemUseCase _deleteHistoryItemUseCase;
  final ClearHistoryUseCase _clearHistoryUseCase;
  final DeleteChatThreadUseCase _deleteChatThreadUseCase;

  final RxList<HistoryItem> history = <HistoryItem>[].obs;
  final RxList<HistoryItem> filteredHistory = <HistoryItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;

  static const Duration _searchDebounceDuration = Duration(milliseconds: 260);
  final Map<String, String> _searchIndex = <String, String>{};
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      final items = await _loadHistoryUseCase();
      history.assignAll(items);
      _rebuildSearchIndex(items);
      _applySearch(searchQuery.value);
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == searchQuery.value) {
      return;
    }
    searchQuery.value = normalized;
    _searchDebounce?.cancel();
    if (normalized.isEmpty) {
      filteredHistory.assignAll(history);
      return;
    }
    _searchDebounce = Timer(_searchDebounceDuration, () {
      _applySearch(normalized);
    });
  }

  void _applySearch(String query) {
    if (query.isEmpty) {
      filteredHistory.assignAll(history);
      return;
    }
    filteredHistory.assignAll(
      history.where((item) => (_searchIndex[item.id] ?? '').contains(query)),
    );
  }

  void _rebuildSearchIndex(List<HistoryItem> items) {
    _searchIndex
      ..clear()
      ..addEntries(
        items.map(
          (item) => MapEntry(
            item.id,
            [
              item.type,
              item.textSnippet,
              item.responseSnippet ?? '',
              item.fullText ?? '',
              item.fullResponse ?? '',
              item.detectedLanguage,
            ].join(' ').toLowerCase(),
          ),
        ),
      );
  }

  Future<void> deleteItem(HistoryItem item) async {
    await _deleteHistoryItemUseCase(item.id);
    if (item.conversationId != null) {
      await _deleteChatThreadUseCase(item.conversationId!);
    }
    history.removeWhere((entry) => entry.id == item.id);
    filteredHistory.removeWhere((entry) => entry.id == item.id);
    _searchIndex.remove(item.id);
  }

  Future<void> clearHistory() async {
    await _clearHistoryUseCase();
    history.clear();
    filteredHistory.clear();
    _searchIndex.clear();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
