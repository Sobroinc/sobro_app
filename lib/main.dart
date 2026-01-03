import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth_service.dart';
import 'core/router.dart';
import 'features/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SobroApp()));
}

/// Main app widget.
/// Per Riverpod docs: https://riverpod.dev/docs/concepts/providers
class SobroApp extends ConsumerStatefulWidget {
  const SobroApp({super.key});

  @override
  ConsumerState<SobroApp> createState() => _SobroAppState();
}

class _SobroAppState extends ConsumerState<SobroApp> {
  @override
  void initState() {
    super.initState();
    // Check auth on startup
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Sobro',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      routerConfig: router,
    );
  }
}
