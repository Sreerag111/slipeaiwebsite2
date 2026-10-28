import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../history/data/repositories/history_item_model.dart';
import '../models/chat_thread_model.dart';
import 'chat_storage_data_source.dart';

class ChatLocalDataSource implements ChatStorageDataSource {
  const ChatLocalDataSource(this._preferences);

  static const historyKey = 'analysis_history';
  static const chatThreadsKey = 'chat_threads_v1';
  static const _isolateDecodeThreshold = 12;

  final SharedPreferences _preferences;

  Future<List<HistoryItemModel>> getHistory() async {
    final historyJson = _preferences.getStringList(historyKey) ?? <String>[];
    if (historyJson.length >= _isolateDecodeThreshold) {
      return compute(_decodeHistoryItems, historyJson);
    }
    return _decodeHistoryItems(historyJson);
  }

  Future<void> saveHistoryItem(HistoryItemModel item) async {
    final history = _preferences.getStringList(historyKey) ?? <String>[];
    history.add(jsonEncode(item.toJson()));
    if (history.length > 50) {
      history.removeAt(0);
    }
    await _preferences.setStringList(historyKey, history);
  }

  Future<void> clearHistory() async {
    await _preferences.remove(historyKey);
    await _preferences.remove(chatThreadsKey);
  }

  Future<void> deleteHistoryItem(String historyId) async {
    final history = _preferences.getStringList(historyKey) ?? <String>[];
    final updated = history.where((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return decoded['id'] != historyId;
    }).toList();
    await _preferences.setStringList(historyKey, updated);
  }

  Future<List<ChatThreadModel>> getChatThreads() async {
    final raw = _preferences.getStringList(chatThreadsKey) ?? <String>[];
    if (raw.length >= _isolateDecodeThreshold) {
      return compute(_decodeChatThreads, raw);
    }
    return _decodeChatThreads(raw);
  }

  Future<ChatThreadModel?> getChatThread(String conversationId) async {
    final raw = _preferences.getStringList(chatThreadsKey) ?? <String>[];
    for (final item in raw) {
      try {
        final thread = ChatThreadModel.fromJson(
          jsonDecode(item) as Map<String, dynamic>,
        );
        if (thread.conversationId == conversationId) {
          return thread;
        }
      } catch (_) {
        // Ignore malformed entries.
      }
    }
    return null;
  }

  Future<void> saveOrUpdateChatThread(ChatThreadModel thread) async {
    final raw = _preferences.getStringList(chatThreadsKey) ?? <String>[];
    final threads = raw
        .map(
          (item) => ChatThreadModel.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();

    final index = threads.indexWhere(
      (existing) => existing.conversationId == thread.conversationId,
    );
    if (index >= 0) {
      threads[index] = thread;
    } else {
      threads.add(thread);
    }

    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (threads.length > 40) {
      threads.removeRange(40, threads.length);
    }

    await _preferences.setStringList(
      chatThreadsKey,
      threads.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> deleteChatThread(String threadId) async {
    final raw = _preferences.getStringList(chatThreadsKey) ?? <String>[];
    final threads = raw
        .map(
          (item) => ChatThreadModel.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .where((thread) => thread.conversationId != threadId)
        .toList();
    await _preferences.setStringList(
      chatThreadsKey,
      threads.map((thread) => jsonEncode(thread.toJson())).toList(),
    );
  }
}

List<HistoryItemModel> _decodeHistoryItems(List<String> historyJson) {
  final items = <HistoryItemModel>[];
  for (final raw in historyJson) {
    try {
      items.add(
        HistoryItemModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (_) {
      // Ignore malformed legacy entries instead of blocking the history screen.
    }
  }
  return items.reversed.toList(growable: false);
}

List<ChatThreadModel> _decodeChatThreads(List<String> rawThreads) {
  final threads = <ChatThreadModel>[];
  for (final raw in rawThreads) {
    try {
      threads.add(
        ChatThreadModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (_) {
      // Ignore malformed legacy entries instead of blocking app startup.
    }
  }
  threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return threads;
}
