import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/user_entity.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  AuthRepository({
    ApiClient? apiClient,
    SecureStorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storageService = storageService ?? SecureStorageService();

  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/signin', data: {
        'email': email,
        'password': password,
      });

      final responseData = ApiClient.extractData(response) ?? {};
      final session = responseData['session'];
      if (session != null) {
        final accessToken = session['access_token'] ?? '';
        final refreshToken = session['refresh_token'] ?? '';
        await _storageService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      return UserEntity.fromJson(responseData['user'] ?? {});
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Sign in failed');
    }
  }

  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
    String baseCurrency = 'INR',
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'baseCurrency': baseCurrency,
      });

      final responseData = ApiClient.extractData(response) ?? {};
      final session = responseData['session'];
      if (session != null) {
        final accessToken = session['access_token'] ?? '';
        final refreshToken = session['refresh_token'] ?? '';
        await _storageService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      return UserEntity.fromJson(responseData['user'] ?? {});
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Sign up failed');
    }
  }

  Future<UserEntity?> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      final data = ApiClient.extractData(response);
      return UserEntity.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<UserEntity> updateProfile({
    String? fullName,
    String? baseCurrency,
    bool? biometricEnabled,
    int? monthStartDay,
  }) async {
    try {
      final response = await _apiClient.dio.patch('/users/me', data: {
        if (fullName != null) 'fullName': fullName,
        if (baseCurrency != null) 'baseCurrency': baseCurrency,
        if (biometricEnabled != null) 'biometricEnabled': biometricEnabled,
        if (monthStartDay != null) 'monthStartDay': monthStartDay,
      });
      final data = ApiClient.extractData(response);
      return UserEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to update profile');
    }
  }

  Future<void> signOut() async {
    try {
      await _apiClient.dio.post('/auth/signout');
    } catch (_) {}
    await _storageService.clearTokens();
  }
}
