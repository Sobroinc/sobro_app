import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_service.dart';
import '../../core/websocket_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../inventory/inventory_screen.dart';
import '../clients/clients_screen.dart';
import '../chat/chat_drawer.dart';

/// Current tab index notifier.
/// Per Riverpod 3.x docs: https://riverpod.dev/docs/concepts/providers
class CurrentTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

/// Current tab provider.
final currentTabProvider = NotifierProvider<CurrentTabNotifier, int>(() {
  return CurrentTabNotifier();
});

/// Home screen with bottom navigation.
/// Per Flutter docs: https://api.flutter.dev/flutter/material/BottomNavigationBar-class.html
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Connect WebSocket on home screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wsServiceProvider).connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      drawer: const ChatDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.smart_toy),
            tooltip: 'AI Чат',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_getTitle(currentTab, l10n)),
        actions: [
          if (user != null)
            InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        user.username.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.username,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentTab,
        children: const [InventoryTab(), ClientsTab()],
      ),
      floatingActionButton: _buildFab(currentTab),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).setTab(index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.warehouse_outlined),
            selectedIcon: const Icon(Icons.warehouse),
            label: l10n.warehouse,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outlined),
            selectedIcon: const Icon(Icons.people),
            label: l10n.clients,
          ),
        ],
      ),
    );
  }

  Widget? _buildFab(int currentTab) {
    // Show FAB for both tabs
    switch (currentTab) {
      case 0: // Inventory/Склад
        return FloatingActionButton(
          onPressed: () => context.push('/inventory/new'),
          child: const Icon(Icons.add),
        );
      case 1: // Clients
        return FloatingActionButton(
          onPressed: () => context.push('/client/new'),
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  String _getTitle(int index, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return l10n.warehouse;
      case 1:
        return l10n.clients;
      default:
        return 'Sobro';
    }
  }
}
