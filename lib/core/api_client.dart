import 'dart:async';

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
/// Fixed: Properly handles async operations without async void.
/// Fixed: Uses lock to prevent race conditions during token refresh.
class AuthInterceptor extends Interceptor {
  final Ref _ref;

  /// Lock to prevent concurrent token refresh attempts
  Completer<bool>? _refreshCompleter;

  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Delegate async work to separate method
    _handleRequest(options, handler);
  }

  Future<void> _handleRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.read(key: 'access_token');

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (e) {
      handler.reject(DioException(requestOptions: options, error: e));
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Delegate async work to separate method
    _handleError(err, handler);
  }

  Future<void> _handleError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired - try refresh
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry original request with new token
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

  /// Refresh token with lock to prevent race conditions.
  /// If refresh is already in progress, wait for it instead of starting new one.
  Future<bool> _tryRefreshToken() async {
    // If refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    // Start new refresh
    _refreshCompleter = Completer<bool>();

    try {
      final storage = _ref.read(secureStorageProvider);
      final refreshToken = await storage.read(key: 'refresh_token');

      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        return false;
      }

      // Use separate Dio instance to avoid interceptor loop
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
        _refreshCompleter!.complete(true);
        _refreshCompleter = null;
        return true;
      }

      _refreshCompleter!.complete(false);
      _refreshCompleter = null;
      return false;
    } catch (e) {
      // Refresh failed
      _refreshCompleter?.complete(false);
      _refreshCompleter = null;
      return false;
    }
  }
}

/// API Client for business logic.
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  /// Create inventory item with media files and trigger AI analysis.
  Future<int> createInventoryWithMedia({
    required int clientId,
    required String title,
    required List<dynamic> files,
  }) async {
    List<String> photoUrls = [];
    List<String> videoUrls = [];

    // Step 1: Upload files
    if (files.isNotEmpty) {
      final formData = FormData();
      for (final file in files) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(file.path, filename: file.name),
          ),
        );
      }
      final resp = await _dio.post('/inventory/upload', data: formData);
      final urls = List<String>.from(resp.data['urls'] ?? []);
      for (final url in urls) {
        if (url.contains('.mp4') || url.contains('.mov')) {
          videoUrls.add(url);
        } else {
          photoUrls.add(url);
        }
      }
    }

    // Step 2: Create inventory item for this client
    final response = await _dio.post(
      '/inventory',
      data: {
        'client_id': clientId,
        'title': title,
        'photos': photoUrls,
        'videos': videoUrls,
      },
    );
    final itemId = response.data['id'] as int;

    // Step 3: Trigger AI analysis (background)
    try {
      await _dio.post('/inventory/$itemId/analyze');
    } catch (e) {
      // AI analysis is optional, don't fail if it errors
    }

    // Step 4: Also save to main warehouse (client_id=1)
    if (clientId != 1) {
      final mainResp = await _dio.post(
        '/inventory',
        data: {
          'client_id': 1,
          'title': '$title (клиент #$clientId)',
          'photos': photoUrls,
          'videos': videoUrls,
        },
      );
      // Trigger AI for main warehouse item too
      try {
        final mainId = mainResp.data['id'] as int;
        await _dio.post('/inventory/$mainId/analyze');
      } catch (e) {
        // Optional
      }
    }

    return itemId;
  }
}

/// API Client provider.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
