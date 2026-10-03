import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/app_config.dart';
import '../models/auth_models.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden at startup.');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (AppConfig.useMockRepositories) return MockAuthRepository(prefs);
  return ApiAuthRepository(ref.watch(dioProvider), prefs);
});

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.errorLog,
  });

  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final String? errorLog;
  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    String? errorLog,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      errorLog: clearError ? null : errorLog ?? this.errorLog,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._ref) : super(const AuthState(isLoading: true)) {
    restoreSession();
  }

  final AuthRepository _repository;
  final Ref _ref;

  Future<void> restoreSession() async {
    try {
      final user = await _repository.restoreSession();
      _ref.read(apiTokenProvider.notifier).state = user?.token;
      state = AuthState(user: user);
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
    required bool remember,
  }) async {
    _ref.read(apiTokenProvider.notifier).state = null;
    state = state.copyWith(isLoading: true, clearUser: true, clearError: true);
    try {
      final user = await _repository.login(
        AuthRequest(username: username, password: password),
        remember: remember,
      );
      _ref.read(apiTokenProvider.notifier).state = user.token;
      state = AuthState(user: user);
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        errorMessage: readableApiError(error),
        errorLog: detailedApiError(error, stackTrace),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _ref.read(apiTokenProvider.notifier).state = null;
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});
