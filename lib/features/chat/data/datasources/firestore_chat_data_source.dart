import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../history/data/repositories/history_item_model.dart';
import '../models/chat_thread_model.dart';
import 'chat_storage_data_source.dart';

class FirestoreChatDataSource implements ChatStorageDataSource {
  FirestoreChatDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _userId => _auth.currentUser?.uid;
  bool get _isGuest => _userId == null;

  DocumentReference get _userDoc {
    final uid = _userId;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference get _historyCollection =>
      _userDoc.collection('history');

  CollectionReference get _threadsCollection =>
      _userDoc.collection('threads');

  @override
  Future<List<HistoryItemModel>> getHistory() async {
    if (_isGuest) return [];
    final snapshot = await _historyCollection
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return HistoryItemModel.fromJson(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<void> saveHistoryItem(HistoryItemModel item) async {
    if (_isGuest) return;
    await _historyCollection.doc(item.id).set(item.toJson());
  }

  @override
  Future<void> clearHistory() async {
    if (_isGuest) return;
    final batch = _firestore.batch();
    final snapshot = await _historyCollection.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> deleteHistoryItem(String historyId) async {
    if (_isGuest) return;
    await _historyCollection.doc(historyId).delete();
  }

  @override
  Future<List<ChatThreadModel>> getChatThreads() async {
    if (_isGuest) return [];
    final snapshot = await _threadsCollection
        .orderBy('updated_at', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return ChatThreadModel.fromJson(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<ChatThreadModel?> getChatThread(String conversationId) async {
    if (_isGuest) return null;
    final doc = await _threadsCollection.doc(conversationId).get();
    if (!doc.exists) return null;
    return ChatThreadModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> saveOrUpdateChatThread(ChatThreadModel thread) async {
    if (_isGuest) return;
    await _threadsCollection.doc(thread.conversationId).set(thread.toJson());
  }

  @override
  Future<void> deleteChatThread(String threadId) async {
    if (_isGuest) return;
    await _threadsCollection.doc(threadId).delete();
  }
}
