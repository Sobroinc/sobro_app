import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'clients_provider.dart';

/// Clients tab for bottom navigation.
class ClientsTab extends ConsumerStatefulWidget {
  const ClientsTab({super.key});

  @override
  ConsumerState<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends ConsumerState<ClientsTab> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientsProvider.notifier).loadClients();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(clientsProvider.notifier).loadMore();
    }
  }

  void _onSearch() {
    ref.read(clientsProvider.notifier).setFilter(
      search: _searchController.text,
    );
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _onSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _debounceTimer?.cancel();
                        _onSearch();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _onSearch,
                  ),
                ],
              ),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: (_) => _onSearch(),
            textInputAction: TextInputAction.search,
          ),
        ),

        // Content
        Expanded(child: _buildContent(state)),
      ],
    );
  }

  Widget _buildContent(ClientsState state) {
    if (state.isLoading && state.clients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(clientsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.clients.isEmpty) {
      return const Center(child: Text('No clients'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(clientsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.clients.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.clients.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _ClientCard(client: state.clients[index]);
        },
      ),
    );
  }
}

/// Client card widget.
class _ClientCard extends StatelessWidget {
  final Client client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/client/${client.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: client.isCompany
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  client.isCompany ? Icons.business : Icons.person,
                  color: client.isCompany
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (client.isSeller)
                          _Badge(
                            label: 'Seller',
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        if (client.isBuyer) ...[
                          const SizedBox(width: 4),
                          _Badge(
                            label: 'Buyer',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (client.contactPerson != null)
                      Text(
                        client.contactPerson!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (client.phone != null || client.email != null)
                      Text(
                        [client.phone, client.email]
                            .where((s) => s != null)
                            .join(' | '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (client.city != null || client.country != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            [client.city, client.country]
                                .where((s) => s != null)
                                .join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge widget.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
