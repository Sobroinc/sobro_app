import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_service.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/products/product_form_screen.dart';
import '../features/inventory/inventory_detail_screen.dart';
import '../features/inventory/inventory_form_screen.dart';
import '../features/clients/client_detail_screen.dart';
import '../features/clients/client_form_screen.dart';
import '../features/auctions/auction_detail_screen.dart';
import '../features/operations/order_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';

/// Router provider.
/// Per go_router docs: https://pub.dev/packages/go_router
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    restorationScopeId:
        null, // Disable state restoration - fixes navigation bug
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // If not authenticated and not on login, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // If authenticated and on login, redirect to home
      if (isAuthenticated && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/product/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/product/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductFormScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/inventory/new',
        builder: (context, state) => const InventoryFormScreen(),
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return InventoryDetailScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/inventory/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return InventoryFormScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/client/new',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/client/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ClientDetailScreen(clientId: id);
        },
      ),
      GoRoute(
        path: '/client/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ClientFormScreen(clientId: id);
        },
      ),
      GoRoute(
        path: '/auction/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AuctionDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
