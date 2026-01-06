import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/auth_service.dart';
import 'core/router.dart';
import 'core/locale_provider.dart';
import 'core/l10n/app_localizations.dart';
import 'features/settings/settings_screen.dart';

/// Sentry DSN for error tracking.
/// In production, consider using --dart-define=SENTRY_DSN=xxx
const String _sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: 'https://874f01a04c2939ea3953774ed260f7b9@o4510664959721472.ingest.us.sentry.io/4510665042493440',
);

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;

      // Environment detection
      options.environment = kReleaseMode ? 'production' : 'development';

      // App version from pubspec.yaml
      options.release = 'sobro_app@3.1.4+106';

      // Performance monitoring (10% of transactions)
      options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;

      // Enable native crash reporting
      options.attachStacktrace = true;
      options.attachScreenshot = true;
      options.attachViewHierarchy = true;

      // Breadcrumbs for debugging
      options.maxBreadcrumbs = 100;

      // Don't send PII
      options.sendDefaultPii = false;

      // Debug mode logging (only in debug builds)
      options.debug = kDebugMode;

      // Auto session tracking
      options.enableAutoSessionTracking = true;
      options.autoSessionTrackingInterval = const Duration(seconds: 30);

      // Navigation observer for automatic screen tracking
      options.enableAutoPerformanceTracing = true;

      // Filter sensitive data from breadcrumbs
      options.beforeBreadcrumb = (breadcrumb, hint) {
        // Filter out sensitive navigation data
        if (breadcrumb?.category == 'navigation') {
          final data = breadcrumb?.data;
          if (data != null && data.containsKey('url')) {
            final url = data['url'] as String?;
            if (url != null && (url.contains('token') || url.contains('password'))) {
              return null; // Drop this breadcrumb
            }
          }
        }
        return breadcrumb;
      };
    },
    appRunner: () => runApp(
      // Wrap with Sentry for automatic error capture
      SentryWidget(
        child: const ProviderScope(child: SobroApp()),
      ),
    ),
  );
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
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Sobro',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      // Add Sentry navigation observer for automatic screen tracking
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
