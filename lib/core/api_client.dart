import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

/// Dio HTTP client provider.
/// Per Dio official documentation: https://pub.dev/packages/dio
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add auth interceptor
  dio.interceptors.add(AuthInterceptor(ref));

  return dio;
});

/// Secure storage provider.
/// Per flutter_secure_storage docs: https://pub.dev/packages/flutter_secure_storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Auth interceptor to add JWT token to requests.
class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token');

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired - try refresh
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry original request
        final opts = err.requestOptions;
        final storage = _ref.read(secureStorageProvider);
        final newToken = await storage.read(key: 'access_token');
        opts.headers['Authorization'] = 'Bearer $newToken';

        try {
          final response = await _ref.read(dioProvider).fetch(opts);
          handler.resolve(response);
          return;
        } catch (e) {
          handler.next(err);
          return;
        }
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final refreshToken = await storage.read(key: 'refresh_token');

      if (refreshToken == null) return false;

      final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await storage.write(key: 'access_token', value: data['access_token']);
        if (data['refresh_token'] != null) {
          await storage.write(
            key: 'refresh_token',
            value: data['refresh_token'],
          );
        }
        return true;
      }
    } catch (e) {
      // Refresh failed
    }
    return false;
  }
}
