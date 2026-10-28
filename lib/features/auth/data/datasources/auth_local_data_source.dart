import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user_model.dart';

class AuthLocalDataSource {
  const AuthLocalDataSource(this._preferences);

  static const sessionUserKey = 'auth_session_user';
  static const sessionTokenKey = 'auth_session_token';
  static const mockUsersKey = 'auth_mock_users';

  final SharedPreferences _preferences;

  AppUserModel? getCachedUser() {
    final raw = _preferences.getString(sessionUserKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return AppUserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  String? getSessionToken() => _preferences.getString(sessionTokenKey);

  Future<void> saveSession({
    required AppUserModel user,
    String? token,
  }) async {
    await _preferences.setString(sessionUserKey, jsonEncode(user.toJson()));
    if (token == null || token.isEmpty) {
      await _preferences.remove(sessionTokenKey);
      return;
    }
    await _preferences.setString(sessionTokenKey, token);
  }

  Future<void> clearSession() async {
    await _preferences.remove(sessionUserKey);
    await _preferences.remove(sessionTokenKey);
  }

  Map<String, dynamic> readMockUsers() {
    final raw = _preferences.getString(mockUsersKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeMockUsers(Map<String, dynamic> users) async {
    await _preferences.setString(mockUsersKey, jsonEncode(users));
  }
}

