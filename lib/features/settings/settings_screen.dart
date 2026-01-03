import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeTile(context, ref, themeMode),

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
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset App'),
            onTap: () {
              _showResetDialog(context, ref);
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

  Widget _buildThemeTile(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    return ListTile(
      leading: Icon(_getThemeIcon(currentMode)),
      title: const Text('Theme'),
      subtitle: Text(_getThemeName(currentMode)),
      onTap: () {
        _showThemeDialog(context, ref, currentMode);
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

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
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
                  _getThemeName(mode),
                  style: TextStyle(
                    fontWeight: mode == currentMode ? FontWeight.bold : null,
                    color: mode == currentMode
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                const Spacer(),
                if (mode == currentMode)
                  Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App'),
        content: const Text('This will clear all local data and log you out. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
