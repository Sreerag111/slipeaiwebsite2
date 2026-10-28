import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/premium_repository.dart';

class PremiumRepositoryImpl implements PremiumRepository {
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PremiumRepositoryImpl(this._prefs);

  static const String _keyIsPremium = 'pace_is_premium';
  static const String _keyChatCount = 'pace_chat_count';
  static const String _keyImageCount = 'pace_image_count';
  static const String _keyMemeCount = 'pace_meme_count';
  static const String _keyIsTrialActive = 'pace_is_trial_active';
  static const String _keyIsAutoPayEnabled = 'pace_is_autopay_enabled';

  String _keyForCurrentUser(String key) {
    final uid = _auth.currentUser?.uid;
    return uid == null ? '${key}_signed_out' : '${key}_$uid';
  }

  @override
  bool getIsPremium() {
    return _prefs.getBool(_keyForCurrentUser(_keyIsPremium)) ?? false;
  }

  @override
  Future<void> setIsPremium(bool value) async {
    await _prefs.setBool(_keyForCurrentUser(_keyIsPremium), value);
  }

  @override
  int getChatCount() {
    return _prefs.getInt(_keyForCurrentUser(_keyChatCount)) ?? 0;
  }

  @override
  Future<void> incrementChatCount() async {
    final current = getChatCount();
    await _prefs.setInt(_keyForCurrentUser(_keyChatCount), current + 1);
    await _syncUsageToFirestore();
  }

  @override
  int getImageCount() {
    return _prefs.getInt(_keyForCurrentUser(_keyImageCount)) ?? 0;
  }

  @override
  Future<void> incrementImageCount() async {
    final current = getImageCount();
    await _prefs.setInt(_keyForCurrentUser(_keyImageCount), current + 1);
    await _syncUsageToFirestore();
  }

  @override
  int getMemeCount() {
    return _prefs.getInt(_keyForCurrentUser(_keyMemeCount)) ?? 0;
  }

  @override
  Future<void> incrementMemeCount() async {
    final current = getMemeCount();
    await _prefs.setInt(_keyForCurrentUser(_keyMemeCount), current + 1);
    await _syncUsageToFirestore();
  }

  Future<void> _syncUsageToFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'usage': {
            'chatCount': getChatCount(),
            'imageCount': getImageCount(),
            'memeCount': getMemeCount(),
          }
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> resetCounts() async {
    await _prefs.setInt(_keyForCurrentUser(_keyChatCount), 0);
    await _prefs.setInt(_keyForCurrentUser(_keyImageCount), 0);
    await _prefs.setInt(_keyForCurrentUser(_keyMemeCount), 0);
    await _syncUsageToFirestore();
  }

  @override
  bool getIsTrialActive() {
    return _prefs.getBool(_keyForCurrentUser(_keyIsTrialActive)) ?? false;
  }

  @override
  Future<void> setIsTrialActive(bool value) async {
    await _prefs.setBool(_keyForCurrentUser(_keyIsTrialActive), value);
  }

  @override
  bool getIsAutoPayEnabled() {
    return _prefs.getBool(_keyForCurrentUser(_keyIsAutoPayEnabled)) ?? false;
  }

  @override
  Future<void> setIsAutoPayEnabled(bool value) async {
    await _prefs.setBool(_keyForCurrentUser(_keyIsAutoPayEnabled), value);
  }
}
