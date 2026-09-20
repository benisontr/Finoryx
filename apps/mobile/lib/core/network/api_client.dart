import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../security/secure_storage_service.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorageService _storageService;

  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  ApiClient({
    String? baseUrl,
    SecureStorageService? storageService,
  })  : _storageService = storageService ?? SecureStorageService(),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? defaultBaseUrl,
            connectTimeout: const Duration(seconds: 45),
            receiveTimeout: const Duration(seconds: 45),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Inject Bearer Token
          final token = await _storageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 2. Inject Idempotency Key for mutations
          if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method.toUpperCase())) {
            options.headers['X-Idempotency-Key'] = const Uuid().v4();
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Smart retry for transient Render cold-start 502/503/504 or connection timeouts
          final isRetryable = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              (error.response?.statusCode != null &&
                  [502, 503, 504].contains(error.response!.statusCode));

          final retryCount = (error.requestOptions.extra['retry_count'] as int?) ?? 0;

          if (isRetryable && retryCount < 2) {
            error.requestOptions.extra['retry_count'] = retryCount + 1;
            await Future.delayed(const Duration(milliseconds: 1500));
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              if (e is DioException) {
                return handler.next(e);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// Extracts the response payload `data` if present, otherwise returns response body.
  static dynamic extractData(Response response) {
    if (response.data is Map<String, dynamic> && response.data.containsKey('data')) {
      return response.data['data'];
    }
    return response.data;
  }

  /// Extracts a clean, human-readable error message from DioException.
  static Exception handleDioError(DioException error, [String defaultMessage = 'An unexpected error occurred']) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['error']?['message'] ?? responseData['message'];
      if (message != null && message.toString().isNotEmpty) {
        return Exception(message.toString());
      }
    }
    return Exception(error.message?.isNotEmpty == true ? error.message! : defaultMessage);
  }
}
