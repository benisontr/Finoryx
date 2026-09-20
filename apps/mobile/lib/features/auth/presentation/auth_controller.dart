import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/security/biometric_service.dart';
import '../data/auth_repository.dart';
import '../domain/user_entity.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

enum AuthStatus { initial, authenticated, unauthenticated, biometricRequired, loading }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _storage;
  final BiometricService _biometrics;

  AuthNotifier({
    required AuthRepository repository,
    required SecureStorageService storage,
    required BiometricService biometrics,
  })  : _repository = repository,
        _storage = storage,
        _biometrics = biometrics,
        super(const AuthState(status: AuthStatus.initial)) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final biometricEnabled = await _storage.isBiometricEnabled();
    if (biometricEnabled) {
      final available = await _biometrics.isBiometricsAvailable();
      if (available) {
        state = state.copyWith(status: AuthStatus.biometricRequired);
        final authenticated = await _biometrics.authenticate();
        if (authenticated) {
          await _loadUserProfile();
        }
        return;
      }
    }

    await _loadUserProfile();
  }

  Future<void> unlockWithBiometrics() async {
    final authenticated = await _biometrics.authenticate();
    if (authenticated) {
      await _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.getProfile();
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String fullName, {String baseCurrency = 'INR'}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        baseCurrency: baseCurrency,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.setBiometricEnabled(enabled);
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(biometricEnabled: enabled);
      state = state.copyWith(user: updatedUser);
      try {
        await _repository.updateProfile(biometricEnabled: enabled);
      } catch (_) {}
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    storage: ref.watch(secureStorageProvider),
    biometrics: ref.watch(biometricServiceProvider),
  );
});
