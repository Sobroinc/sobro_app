import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_service.dart';
import '../../core/websocket_service.dart';
import '../products/products_screen.dart';
import '../inventory/inventory_screen.dart';
import '../clients/clients_screen.dart';
import '../auctions/auctions_screen.dart';
import '../operations/operations_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(currentTab)),
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
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
        children: const [
          ProductsTab(),
          InventoryTab(),
          ClientsTab(),
          AuctionsTab(),
          OperationsTab(),
        ],
      ),
      floatingActionButton: _buildFab(currentTab),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).setTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.warehouse_outlined),
            selectedIcon: Icon(Icons.warehouse),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'Auctions',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Operations',
          ),
        ],
      ),
    );
  }

  Widget? _buildFab(int currentTab) {
    // Show FAB only for tabs that support creating new items
    switch (currentTab) {
      case 0: // Products
        return FloatingActionButton(
          onPressed: () => context.push('/product/new'),
          child: const Icon(Icons.add),
        );
      case 1: // Inventory
        return FloatingActionButton(
          onPressed: () => context.push('/inventory/new'),
          child: const Icon(Icons.add),
        );
      case 2: // Clients
        return FloatingActionButton(
          onPressed: () => context.push('/client/new'),
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Products';
      case 1:
        return 'Inventory';
      case 2:
        return 'Clients';
      case 3:
        return 'Auctions';
      case 4:
        return 'Operations';
      default:
        return 'Sobro';
    }
  }
}
