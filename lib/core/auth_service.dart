import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// User model.
/// Per SobroBase app/models/auth.py User class.
class User {
  final int id;
  final String username;
  final String? email;
  final String? fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'user',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Authentication state.
sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

/// Auth state notifier.
/// Per Riverpod 3.x docs: https://riverpod.dev/docs/concepts/providers
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthInitial();
  }

  /// Check if user is already logged in.
  Future<void> checkAuth() async {
    state = AuthLoading();

    try {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        state = AuthUnauthenticated();
        return;
      }

      // Verify token by getting current user
      // Per SobroBase GET /auth/me endpoint
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/me');

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthUnauthenticated();
    }
  }

  /// Login with username and password.
  /// Per SobroBase POST /auth/login endpoint.
  Future<bool> login(String username, String password) async {
    state = AuthLoading();

    try {
      final dio = ref.read(dioProvider);

      // Per SobroBase LoginRequest model: {username, password}
      final response = await dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        // Per SobroBase TokenResponse model
        final data = response.data as Map<String, dynamic>;
        final storage = ref.read(secureStorageProvider);

        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;

        await storage.write(key: 'access_token', value: accessToken);
        await storage.write(key: 'refresh_token', value: refreshToken);

        // Get user info from /auth/me
        // Per SobroBase GET /auth/me returns User model
        final meResponse = await dio.get('/auth/me');
        if (meResponse.statusCode == 200) {
          final user = User.fromJson(meResponse.data);
          state = AuthAuthenticated(user);
          return true;
        }

        state = AuthError('Failed to get user info');
        return false;
      } else {
        state = AuthError('Login failed');
        return false;
      }
    } on DioException catch (e) {
      String message = 'Login failed';
      final detail = e.response?.data?['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List) {
        message = detail.map((d) => d['msg'] ?? d.toString()).join(', ');
      } else if (e.message != null) {
        message = e.message!;
      }
      state = AuthError(message);
      return false;
    } catch (e) {
      state = AuthError('Connection error');
      return false;
    }
  }

  /// Logout.
  /// Per SobroBase POST /auth/logout endpoint.
  Future<void> logout() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    }

    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');

    state = AuthUnauthenticated();
  }
}

/// Auth provider.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
