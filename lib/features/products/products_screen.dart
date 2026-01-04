import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import 'products_provider.dart';

/// Products tab for bottom navigation.
class ProductsTab extends ConsumerStatefulWidget {
  const ProductsTab({super.key});

  @override
  ConsumerState<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<ProductsTab> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadProducts();
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
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    ref.read(productsProvider.notifier).search(query);
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
    final state = ref.watch(productsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
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

        // Category filters
        if (state.categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.categories.length + 1, // +1 for "All"
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: state.categoryId == null,
                      onSelected: (_) {
                        ref
                            .read(productsProvider.notifier)
                            .filterByCategory(null);
                      },
                    ),
                  );
                }
                final category = state.categories[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text('${category.name} (${category.count})'),
                    selected: state.categoryId == category.id,
                    onSelected: (_) {
                      ref
                          .read(productsProvider.notifier)
                          .filterByCategory(category.id);
                    },
                  ),
                );
              },
            ),
          ),

        // Content
        Expanded(child: _buildContent(state)),
      ],
    );
  }

  Widget _buildContent(ProductsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(productsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
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
                  ? 'No products found for "${state.searchQuery}"'
                  : 'No products',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _ProductCard(product: state.products[index]);
        },
      ),
    );
  }
}

/// Product card widget.
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/product/${product.id}');
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(width: 100, height: 100, child: _buildImage()),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.categoryName != null)
                      Text(
                        product.categoryName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (product.price != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '\$${product.price!.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Status badge
            Padding(
              padding: const EdgeInsets.all(8),
              child: _buildStatusBadge(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String label;
    switch (product.status) {
      case 'in_stock':
        color = Colors.green;
        label = 'In Stock';
        break;
      case 'sold':
        color = Colors.red;
        label = 'Sold';
        break;
      case 'reserved':
        color = Colors.orange;
        label = 'Reserved';
        break;
      default:
        color = Colors.grey;
        label = product.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildImage() {
    if (product.imageUrl == null) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    // Build full URL
    final imageUrl = product.imageUrl!.startsWith('http')
        ? product.imageUrl!
        : '${AppConfig.baseUrl.replaceAll('/api', '')}${product.imageUrl}';

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
