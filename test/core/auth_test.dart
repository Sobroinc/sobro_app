import 'package:flutter_test/flutter_test.dart';
import 'package:sobro_app/core/auth_service.dart';

void main() {
  group('User', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'username': 'john_doe',
        'email': 'john@example.com',
        'full_name': 'John Doe',
        'role': 'admin',
        'is_active': true,
        'created_at': '2024-01-15T10:30:00Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.username, 'john_doe');
      expect(user.email, 'john@example.com');
      expect(user.fullName, 'John Doe');
      expect(user.role, 'admin');
      expect(user.isActive, true);
      expect(user.createdAt, DateTime.parse('2024-01-15T10:30:00Z'));
    });

    test('fromJson uses default values for optional fields', () {
      final json = {
        'id': 1,
        'username': 'test_user',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.email, isNull);
      expect(user.fullName, isNull);
      expect(user.role, 'user');
      expect(user.isActive, true);
    });

    test('fromJson handles inactive user', () {
      final json = {
        'id': 1,
        'username': 'inactive_user',
        'is_active': false,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.isActive, false);
    });
  });

  group('AuthState', () {
    test('AuthInitial can be created', () {
      final state = AuthInitial();
      expect(state, isA<AuthState>());
      expect(state, isA<AuthInitial>());
    });

    test('AuthLoading can be created', () {
      final state = AuthLoading();
      expect(state, isA<AuthState>());
      expect(state, isA<AuthLoading>());
    });

    test('AuthAuthenticated holds user', () {
      final user = User(
        id: 1,
        username: 'test',
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );
      final state = AuthAuthenticated(user);

      expect(state, isA<AuthState>());
      expect(state, isA<AuthAuthenticated>());
      expect(state.user, user);
      expect(state.user.username, 'test');
    });

    test('AuthUnauthenticated can be created', () {
      final state = AuthUnauthenticated();
      expect(state, isA<AuthState>());
      expect(state, isA<AuthUnauthenticated>());
    });

    test('AuthError holds message', () {
      final state = AuthError('Invalid credentials');

      expect(state, isA<AuthState>());
      expect(state, isA<AuthError>());
      expect(state.message, 'Invalid credentials');
    });

    test('sealed class pattern matching works', () {
      final states = <AuthState>[
        AuthInitial(),
        AuthLoading(),
        AuthAuthenticated(User(
          id: 1,
          username: 'test',
          role: 'user',
          isActive: true,
          createdAt: DateTime.now(),
        )),
        AuthUnauthenticated(),
        AuthError('Error'),
      ];

      final results = states.map((state) {
        return switch (state) {
          AuthInitial() => 'initial',
          AuthLoading() => 'loading',
          AuthAuthenticated(:final user) => 'authenticated:${user.username}',
          AuthUnauthenticated() => 'unauthenticated',
          AuthError(:final message) => 'error:$message',
        };
      }).toList();

      expect(results, [
        'initial',
        'loading',
        'authenticated:test',
        'unauthenticated',
        'error:Error',
      ]);
    });
  });
}
