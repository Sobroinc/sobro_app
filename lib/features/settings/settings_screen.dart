import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/locale_provider.dart';

/// Theme mode notifier.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// Theme mode provider.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

/// Settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // Language section
          _buildSectionHeader(context, l10n.language),
          _buildLanguageTile(context, ref, locale, l10n),

          const Divider(),

          // Appearance section
          _buildSectionHeader(context, l10n.theme),
          _buildThemeTile(context, ref, themeMode, l10n),

          const Divider(),

          // Server section
          _buildSectionHeader(context, 'Server'),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('API Server'),
            subtitle: Text(AppConfig.baseUrl),
          ),

          const Divider(),

          // About section
          _buildSectionHeader(context, l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            subtitle: const Text('2.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Build'),
            subtitle: const Text('sobro_app_v2'),
          ),

          const Divider(),

          // Debug section
          _buildSectionHeader(context, 'Debug'),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Clear Cache'),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset App'),
            onTap: () {
              _showResetDialog(context, ref, l10n);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
    AppLocalizations l10n,
  ) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: Text(_getLanguageName(currentLocale.languageCode)),
      trailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'ru', label: Text('RU')),
          ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {currentLocale.languageCode},
        onSelectionChanged: (selected) {
          ref.read(localeProvider.notifier).setLocale(Locale(selected.first));
        },
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  Widget _buildThemeTile(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
    AppLocalizations l10n,
  ) {
    return ListTile(
      leading: Icon(_getThemeIcon(currentMode)),
      title: Text(l10n.theme),
      subtitle: Text(_getThemeName(currentMode, l10n)),
      onTap: () {
        _showThemeDialog(context, ref, currentMode, l10n);
      },
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeName(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.lightMode;
      case ThemeMode.dark:
        return l10n.darkMode;
      case ThemeMode.system:
        return l10n.systemTheme;
    }
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.theme),
        children: ThemeMode.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Icon(
                  _getThemeIcon(mode),
                  color: mode == currentMode
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  _getThemeName(mode, l10n),
                  style: TextStyle(
                    fontWeight: mode == currentMode ? FontWeight.bold : null,
                    color: mode == currentMode
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                const Spacer(),
                if (mode == currentMode)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showResetDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App'),
        content: const Text(
          'This will clear all local data and log you out. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App reset (demo only)')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
