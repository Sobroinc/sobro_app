import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import 'inventory_provider.dart';

/// Inventory tab for bottom navigation.
class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).loadItems();
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
      ref.read(inventoryProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    ref.read(inventoryProvider.notifier).search(query);
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _onSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search inventory...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _debounceTimer?.cancel();
                        _onSearch('');
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _onSearch(_searchController.text),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: _onSearch,
            textInputAction: TextInputAction.search,
          ),
        ),

        // Breadcrumb
        if (state.currentGroup != null)
          _Breadcrumb(
            group: state.currentGroup!,
            onBack: () => ref.read(inventoryProvider.notifier).goToRoot(),
          ),

        // Content
        Expanded(child: _buildContent(state)),
      ],
    );
  }

  Widget _buildContent(InventoryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(inventoryProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              state.searchQuery != null && state.searchQuery!.isNotEmpty
                  ? 'No items found for "${state.searchQuery}"'
                  : 'No inventory items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _InventoryCard(
            item: state.items[index],
            onTap: () {
              final item = state.items[index];
              if (item.isGroup) {
                ref.read(inventoryProvider.notifier).openGroup(item.id);
              } else {
                context.push('/inventory/${item.id}');
              }
            },
          );
        },
      ),
    );
  }
}

/// Breadcrumb navigation.
class _Breadcrumb extends StatelessWidget {
  final InventoryItem group;
  final VoidCallback onBack;

  const _Breadcrumb({required this.group, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            tooltip: 'Back to root',
          ),
          const SizedBox(width: 8),
          Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              group.title,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inventory item card.
class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const _InventoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or folder icon
            SizedBox(
              width: 100,
              height: 100,
              child: item.isGroup ? _buildFolderIcon(context) : _buildImage(),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.inCatalog)
                          Icon(
                            Icons.public,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (item.isGroup) ...[
                      Text(
                        '${item.childCount ?? 0} items',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      if (item.manufacturer != null || item.model != null)
                        Text(
                          [
                            item.manufacturer,
                            item.model,
                          ].where((s) => s != null).join(' - '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.quantity > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Qty: ${item.quantity}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          if (item.location != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.location!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (item.isGroup)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.chevron_right),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderIcon(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.folder,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildImage() {
    if (item.firstPhoto == null) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    final imageUrl = item.firstPhoto!.startsWith('http')
        ? item.firstPhoto!
        : '${AppConfig.baseUrl.replaceAll('/api', '')}${item.firstPhoto}';

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
