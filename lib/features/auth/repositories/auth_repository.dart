import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../models/auth_models.dart';
import '../models/user.dart';

abstract class AuthRepository {
  Future<User?> restoreSession();
  Future<User> login(AuthRequest request, {required bool remember});
  Future<void> logout();
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _sessionKey = 'auth_user';

  @override
  Future<User?> restoreSession() async {
    final encoded = _prefs.getString(_sessionKey);
    if (encoded == null) return null;
    return User.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  }

  @override
  Future<User> login(AuthRequest request, {required bool remember}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (request.username.trim().isEmpty || request.password.length < 4) {
      throw const ApiException(
        'Enter a username and at least 4 password characters.',
      );
    }
    if (request.password.toLowerCase() == 'wrong') {
      throw const ApiException('Invalid username or password.');
    }
    final user = User(
      id: 'u-1',
      name: 'Ahmad Zahir',
      username: request.username,
      role: 'Waiter',
      token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
    );
    if (remember) {
      await _prefs.setString(_sessionKey, jsonEncode(user.toJson()));
    }
    return user;
  }

  @override
  Future<void> logout() async {
    await _prefs.remove(_sessionKey);
  }
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;
  static const _sessionKey = 'auth_user';

  @override
  Future<User?> restoreSession() async {
    final encoded = _prefs.getString(_sessionKey);
    if (encoded == null) return null;
    return User.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  }

  @override
  Future<User> login(AuthRequest request, {required bool remember}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson(),
    );
    final auth = AuthResponse.fromJson(response.data ?? {});
    if (auth.token.isEmpty)
      throw const ApiException('Login succeeded without a token.');
    if (remember) {
      await _prefs.setString(_sessionKey, jsonEncode(auth.user.toJson()));
    }
    return auth.user;
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.get<Map<String, dynamic>>('/logout');
    } on DioException {
      // Local session cleanup should still happen if the token is already invalid.
    }
    await _prefs.remove(_sessionKey);
  }
}
