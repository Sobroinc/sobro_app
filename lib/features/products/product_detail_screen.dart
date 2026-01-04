import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import 'products_provider.dart';

/// Product detail screen with image gallery.
/// Per Flutter docs: https://api.flutter.dev/flutter/widgets/PageView-class.html
class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      body: _buildBody(state),
      floatingActionButton: state.hasValue
          ? FloatingActionButton(
              onPressed: () {
                context.push('/product/${widget.productId}/edit');
              },
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  Widget _buildBody(AsyncValue<Product> state) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error.toString()),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(productDetailProvider(widget.productId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (product) => _buildContent(product),
    );
  }

  Widget _buildContent(Product product) {
    return CustomScrollView(
      slivers: [
        // Image gallery with app bar
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(product),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Category
                if (product.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      product.categoryName!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Prices
                _buildPricesSection(product),
                const SizedBox(height: 24),

                // Specifications
                if (product.params != null && product.params!.hasAnyData) ...[
                  Text(
                    'Specifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSpecifications(product.params!),
                  const SizedBox(height: 24),
                ],

                // Description
                if (product.content != null && product.content!.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.content!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                ],

                // Status
                _buildStatusChip(product.status),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(Product product) {
    final images = product.images;

    if (images.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        // PageView for images
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openFullScreenGallery(context, product, index),
              child: _buildImage(images[index].path),
            );
          },
        ),

        // Page indicator (limit to max 7 visible dots to prevent overflow)
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: _buildPageIndicators(context, images.length),
            ),
          ),

        // Image counter
        if (images.length > 1)
          Positioned(
            top: 80,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentPage + 1}/${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildPageIndicators(BuildContext context, int totalImages) {
    const maxDots = 7;

    // If few images, show all dots
    if (totalImages <= maxDots) {
      return List.generate(
        totalImages,
        (index) => _buildDot(context, index, _currentPage == index),
      );
    }

    // For many images, show sliding window of dots
    final indicators = <Widget>[];
    final halfWindow = maxDots ~/ 2;

    int start = (_currentPage - halfWindow).clamp(0, totalImages - maxDots);
    int end = start + maxDots;

    if (start > 0) {
      indicators.add(_buildDot(context, 0, _currentPage == 0, isSmall: true));
    }

    for (int i = start; i < end; i++) {
      indicators.add(_buildDot(context, i, _currentPage == i));
    }

    if (end < totalImages) {
      indicators.add(
        _buildDot(
          context,
          totalImages - 1,
          _currentPage == totalImages - 1,
          isSmall: true,
        ),
      );
    }

    return indicators;
  }

  Widget _buildDot(
    BuildContext context,
    int index,
    bool isActive, {
    bool isSmall = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 20 : (isSmall ? 4 : 6),
      height: isSmall ? 4 : 6,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(3),
      ),
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

  Widget _buildPricesSection(Product product) {
    final prices = <Widget>[];

    if (product.price != null) {
      prices.add(_buildPriceRow('Price', product.price!, 'USD'));
    }
    if (product.directSalePrice != null) {
      prices.add(
        _buildPriceRow(
          'Direct Sale',
          product.directSalePrice!,
          product.directCurrency,
        ),
      );
    }
    if (product.auctionPrice != null) {
      prices.add(
        _buildPriceRow(
          'Auction Start',
          product.auctionPrice!,
          product.auctionCurrency,
        ),
      );
    }

    if (prices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: prices,
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double price, String currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecifications(ProductParams params) {
    final specs = <MapEntry<String, String>>[];

    if (params.manufacturer != null)
      specs.add(MapEntry('Manufacturer', params.manufacturer!));
    if (params.model != null) specs.add(MapEntry('Model', params.model!));
    if (params.machineType != null)
      specs.add(MapEntry('Type', params.machineType!));
    if (params.yearOfProduction != null)
      specs.add(MapEntry('Year', params.yearOfProduction!));
    if (params.serialNumber != null)
      specs.add(MapEntry('Serial #', params.serialNumber!));
    if (params.weight != null) specs.add(MapEntry('Weight', params.weight!));
    if (params.location != null)
      specs.add(MapEntry('Location', params.location!));
    if (params.itemStatus != null)
      specs.add(MapEntry('Condition', params.itemStatus!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: specs
              .map((spec) => _buildSpecRow(spec.key, spec.value))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
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
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _openFullScreenGallery(
    BuildContext context,
    Product product,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          images: product.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Full screen image gallery.
class _FullScreenGallery extends StatefulWidget {
  final List<ProductFile> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final path = widget.images[index].path;
          final imageUrl = path.startsWith('http')
              ? path
              : '${AppConfig.baseUrl.replaceAll('/api', '')}$path';

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
