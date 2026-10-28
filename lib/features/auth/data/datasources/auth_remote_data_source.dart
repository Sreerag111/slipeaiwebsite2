import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:plagiarism_checker/features/auth/data/datasources/auth_local_data_source.dart';

import '../models/app_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel?> getSessionUser({
    required String? token,
    required AppUserModel? cachedUser,
  });

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });

  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUserModel> updateProfile({
    required AppUserModel user,
    required String? token,
  });

  Future<void> logout({required String? token});

  Future<AuthSessionModel> signInWithGoogle();
}

class BackendAuthRemoteDataSource implements AuthRemoteDataSource {
  BackendAuthRemoteDataSource({
    required String baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl.replaceAll(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Map<String, String> get _jsonHeaders => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> _authorizedHeaders(String token) => {
        ..._jsonHeaders,
        'Authorization': 'Bearer $token',
      };

  @override
  Future<AuthSessionModel?> getSessionUser({
    required String? token,
    required AppUserModel? cachedUser,
  }) async {
    if (token == null || token.isEmpty || cachedUser == null) {
      return null;
    }

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _authorizedHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthSessionModel(
          user: _parseUserPayload(data),
          token: token,
        );
      }

      if (response.statusCode == 401) {
        return null;
      }
    } catch (_) {
      return AuthSessionModel(user: cachedUser, token: token);
    }

    return AuthSessionModel(user: cachedUser, token: token);
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );
    final data = _decodeResponse(response);
    return AuthSessionModel(
      user: _parseUserPayload(data),
      token: _readToken(data),
    );
  }

  @override
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );
    final data = _decodeResponse(response);
    return AuthSessionModel(
      user: _parseUserPayload(data),
      token: _readToken(data),
    );
  }

  @override
  Future<AppUserModel> updateProfile({
    required AppUserModel user,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await _client.put(
      Uri.parse('$_baseUrl/auth/profile'),
      headers: _authorizedHeaders(token),
      body: jsonEncode(user.toJson()),
    );
    final data = _decodeResponse(response);
    return _parseUserPayload(data, fallback: user);
  }

  @override
  Future<void> logout({required String? token}) async {
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _client.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _authorizedHeaders(token),
      );
    } catch (_) {
      // Clear the local session even if the backend call fails.
    }
  }

  @override
  Future<AuthSessionModel> signInWithGoogle() async {
    throw UnsupportedError('Google sign-in is not supported with backend auth.');
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final hasBody = response.body.trim().isNotEmpty;
    final data = hasBody
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['message'] ??
        data['error'] ??
        data['detail'] ??
        'Request failed with status ${response.statusCode}.';
    throw Exception(message.toString());
  }

  String _readToken(Map<String, dynamic> data) {
    final token = data['token'] ?? data['access_token'];
    if (token is String && token.isNotEmpty) {
      return token;
    }
    throw Exception('Backend response is missing an auth token.');
  }

  AppUserModel _parseUserPayload(
    Map<String, dynamic> data, {
    AppUserModel? fallback,
  }) {
    final rawUser = data['user'];
    if (rawUser is Map<String, dynamic>) {
      return AppUserModel.fromJson(rawUser);
    }
    if (rawUser is Map) {
      return AppUserModel.fromJson(rawUser.cast<String, dynamic>());
    }
    if ((data['email'] ?? '').toString().isNotEmpty) {
      return AppUserModel.fromJson(data);
    }
    if (fallback != null) {
      return fallback;
    }
    throw Exception('Backend response is missing user data.');
  }
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  MockAuthRemoteDataSource(this._localDataSource);

  final AuthLocalDataSource _localDataSource;

  @override
  Future<AuthSessionModel?> getSessionUser({
    required String? token,
    required AppUserModel? cachedUser,
  }) async {
    return cachedUser == null
        ? null
        : AuthSessionModel(user: cachedUser, token: token);
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final users = _localDataSource.readMockUsers();
    final userJson = users[email.toLowerCase()];
    if (userJson == null) {
      throw Exception('No account found for this email.');
    }
    if ((userJson['password'] ?? '') != password) {
      throw Exception('Invalid password.');
    }
    return AuthSessionModel(
      user: AppUserModel.fromJson(userJson as Map<String, dynamic>),
      token: null,
    );
  }

  @override
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final users = _localDataSource.readMockUsers();
    final key = email.toLowerCase();
    if (users.containsKey(key)) {
      throw Exception('An account with this email already exists.');
    }
    users[key] = {
      'name': name.trim(),
      'email': key,
      'avatar_url': null,
      'password': password,
    };
    await _localDataSource.writeMockUsers(users);
    return AuthSessionModel(
      user: AppUserModel(name: name.trim(), email: key),
      token: null,
    );
  }

  @override
  Future<AppUserModel> updateProfile({
    required AppUserModel user,
    required String? token,
  }) async {
    final users = _localDataSource.readMockUsers();
    final key = user.email.toLowerCase();
    final existing = users[key];
    if (existing != null) {
      users[key] = {
        ...existing as Map<String, dynamic>,
        'name': user.name,
        'email': user.email,
        'avatar_url': user.avatarUrl,
      };
      await _localDataSource.writeMockUsers(users);
    }
    return user;
  }

  @override
  Future<void> logout({required String? token}) async {}

  @override
  Future<AuthSessionModel> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AuthSessionModel(
      user: AppUserModel(name: 'Google User', email: 'google.mock@paceai.com'),
      token: null,
    );
  }
}

