import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Locale notifier for language switching.
/// Per Riverpod 3.x docs: https://riverpod.dev/docs/concepts/providers
class LocaleNotifier extends Notifier<Locale> {
  static const _storageKey = 'app_locale';
  final _storage = const FlutterSecureStorage();

  @override
  Locale build() {
    // Load saved locale async
    _loadSavedLocale();
    // Default to Russian
    return const Locale('ru');
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await _storage.read(key: _storageKey);
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.write(key: _storageKey, value: locale.languageCode);
  }

  void toggleLocale() {
    if (state.languageCode == 'ru') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('ru'));
    }
  }
}

/// Locale provider.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
