import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import 'inventory_provider.dart';

/// Inventory item detail screen.
class InventoryDetailScreen extends ConsumerStatefulWidget {
  final int itemId;

  const InventoryDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends ConsumerState<InventoryDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryDetailProvider(widget.itemId));

    return Scaffold(
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(inventoryDetailProvider(widget.itemId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (item) => _buildContent(item),
      ),
      floatingActionButton: state.hasValue
          ? FloatingActionButton(
              onPressed: () {
                context.push('/inventory/${widget.itemId}/edit');
              },
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  Widget _buildContent(InventoryItem item) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(item),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (item.manufacturer != null || item.model != null)
                  _buildInfoCard([
                    if (item.manufacturer != null) _buildRow('Manufacturer', item.manufacturer!),
                    if (item.model != null) _buildRow('Model', item.model!),
                    if (item.year != null) _buildRow('Year', item.year.toString()),
                    if (item.serialNumber != null) _buildRow('Serial #', item.serialNumber!),
                    if (item.condition != null) _buildRow('Condition', item.condition!),
                  ]),
                const SizedBox(height: 16),
                _buildInfoCard([
                  _buildRow('Quantity', item.quantity.toString()),
                  if (item.location != null) _buildRow('Location', item.location!),
                  if (item.city != null) _buildRow('City', item.city!),
                ]),
                if (item.salePrice != null || item.purchasePrice != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    if (item.purchasePrice != null)
                      _buildRow('Purchase Price', '\$${item.purchasePrice!.toStringAsFixed(0)}'),
                    if (item.salePrice != null)
                      _buildRow('Sale Price', '\$${item.salePrice!.toStringAsFixed(0)}'),
                  ]),
                ],
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Description', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(item.description!),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(InventoryItem item) {
    if (item.photos.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey)),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: item.photos.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) => _buildImage(item.photos[index]),
        ),
        if (item.photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                item.photos.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withAlpha(128),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage(String path) {
    final imageUrl = path.startsWith('http')
        ? path
        : '${AppConfig.baseUrl.replaceAll('/api', '')}$path';

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
