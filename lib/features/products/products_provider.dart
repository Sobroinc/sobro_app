import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/websocket_service.dart';

/// Product params model.
/// Per SobroBase app/models/products.py ProductParams class.
class ProductParams {
  final String? machineType;
  final String? manufacturer;
  final String? model;
  final String? yearOfProduction;
  final String? serialNumber;
  final String? weight;
  final String? location;
  final String? itemStatus;

  ProductParams({
    this.machineType,
    this.manufacturer,
    this.model,
    this.yearOfProduction,
    this.serialNumber,
    this.weight,
    this.location,
    this.itemStatus,
  });

  factory ProductParams.fromJson(Map<String, dynamic> json) {
    return ProductParams(
      machineType:
          json['machine_type'] as String? ?? json['Machine type'] as String?,
      manufacturer:
          json['manufacturer'] as String? ?? json['Manufacturer'] as String?,
      model: json['model'] as String? ?? json['Model'] as String?,
      yearOfProduction:
          json['year_of_production'] as String? ??
          json['Year of production'] as String?,
      serialNumber:
          json['serial_number'] as String? ?? json['Serial number'] as String?,
      weight: json['weight'] as String? ?? json['Weight'] as String?,
      location: json['location'] as String? ?? json['Location'] as String?,
      itemStatus:
          json['item_status'] as String? ?? json['Item status'] as String?,
    );
  }

  bool get hasAnyData =>
      machineType != null ||
      manufacturer != null ||
      model != null ||
      yearOfProduction != null ||
      serialNumber != null ||
      weight != null ||
      location != null ||
      itemStatus != null;
}

/// Product model.
/// Per SobroBase app/models/products.py Product class.
class Product {
  final int id;
  final String title;
  final String? content;
  final double? price;
  final double? purchasePrice;
  final String purchaseCurrency;
  final double? auctionPrice;
  final String auctionCurrency;
  final double? directSalePrice;
  final String directCurrency;
  final String? categoryName;
  final int? categoryId;
  final List<ProductFile> files;
  final ProductParams? params;
  final String status;

  Product({
    required this.id,
    required this.title,
    this.content,
    this.price,
    this.purchasePrice,
    this.purchaseCurrency = 'USD',
    this.auctionPrice,
    this.auctionCurrency = 'USD',
    this.directSalePrice,
    this.directCurrency = 'USD',
    this.categoryName,
    this.categoryId,
    this.files = const [],
    this.params,
    this.status = 'in_stock',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      purchaseCurrency: json['purchase_currency'] as String? ?? 'USD',
      auctionPrice: (json['auction_price'] as num?)?.toDouble(),
      auctionCurrency: json['auction_currency'] as String? ?? 'USD',
      directSalePrice: (json['direct_sale_price'] as num?)?.toDouble(),
      directCurrency: json['direct_currency'] as String? ?? 'USD',
      categoryName: json['category_name'] as String?,
      categoryId: json['category_id'] as int?,
      files:
          (json['files'] as List<dynamic>?)
              ?.map((f) => ProductFile.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      params: json['params'] != null
          ? ProductParams.fromJson(json['params'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'in_stock',
    );
  }

  /// First image URL for display.
  String? get imageUrl {
    final image = files.where((f) => f.type == 'image').firstOrNull;
    return image?.path;
  }

  /// All image files.
  List<ProductFile> get images =>
      files.where((f) => f.type == 'image').toList();
}

/// Product file (image/document).
class ProductFile {
  final int id;
  final String name;
  final String path;
  final String type;

  ProductFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
  });

  factory ProductFile.fromJson(Map<String, dynamic> json) {
    return ProductFile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      type: json['type'] as String? ?? 'image',
    );
  }
}

/// Product category model.
class ProductCategory {
  final int id;
  final String name;
  final int count;

  ProductCategory({required this.id, required this.name, this.count = 0});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      count: json['count'] as int? ?? 0,
    );
  }
}

/// Products state.
class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final int page;
  final int total;
  final bool hasMore;
  final String? searchQuery;
  final int? categoryId;
  final List<ProductCategory> categories;

  ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.total = 0,
    this.hasMore = true,
    this.searchQuery,
    this.categoryId,
    this.categories = const [],
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    int? page,
    int? total,
    bool? hasMore,
    String? searchQuery,
    int? categoryId,
    List<ProductCategory>? categories,
    bool clearCategory = false,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categories: categories ?? this.categories,
    );
  }
}

/// Products notifier.
/// Per Riverpod 3.x docs: https://riverpod.dev/docs/concepts/providers
class ProductsNotifier extends Notifier<ProductsState> {
  @override
  ProductsState build() {
    _listenToWebSocket();
    _loadCategories();
    return ProductsState();
  }

  Future<void> _loadCategories() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/products/categories');
      if (response.statusCode == 200) {
        final categories = (response.data as List)
            .map((c) => ProductCategory.fromJson(c as Map<String, dynamic>))
            .toList();
        state = state.copyWith(categories: categories);
      }
    } catch (e) {
      // Ignore category load errors
    }
  }

  void _listenToWebSocket() {
    ref.listen(wsEventsProvider, (_, next) {
      next.whenData((event) {
        switch (event.type) {
          case 'product.created':
            _handleProductCreated(event.data);
            break;
          case 'product.updated':
            _handleProductUpdated(event.data);
            break;
          case 'product.deleted':
            _handleProductDeleted(event.data);
            break;
        }
      });
    });
  }

  void _handleProductCreated(Map<String, dynamic> data) {
    final product = Product.fromJson(data);
    state = state.copyWith(
      products: [product, ...state.products],
      total: state.total + 1,
    );
  }

  void _handleProductUpdated(Map<String, dynamic> data) {
    final updated = Product.fromJson(data);
    final products = state.products.map((p) {
      return p.id == updated.id ? updated : p;
    }).toList();
    state = state.copyWith(products: products);
  }

  void _handleProductDeleted(Map<String, dynamic> data) {
    final id = data['id'] as int?;
    if (id != null) {
      final products = state.products.where((p) => p.id != id).toList();
      state = state.copyWith(products: products, total: state.total - 1);
    }
  }

  /// Load products from API.
  Future<void> loadProducts({
    bool refresh = false,
    String? search,
    int? categoryId,
  }) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.page;

    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: search ?? state.searchQuery,
      categoryId: categoryId,
      clearCategory: categoryId == null && refresh,
    );

    try {
      final dio = ref.read(dioProvider);
      final params = <String, dynamic>{'page': page, 'per_page': 20};
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        params['search'] = state.searchQuery;
      }
      if (state.categoryId != null) {
        params['category_id'] = state.categoryId;
      }

      final response = await dio.get('/products', queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data;
        final products = (data['products'] as List)
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();
        final total = data['total'] as int? ?? 0;

        state = state.copyWith(
          products: refresh ? products : [...state.products, ...products],
          isLoading: false,
          page: page + 1,
          total: total,
          hasMore: products.length >= 20,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Search products.
  void search(String query) {
    loadProducts(refresh: true, search: query);
  }

  /// Filter by category.
  void filterByCategory(int? categoryId) {
    loadProducts(refresh: true, categoryId: categoryId);
  }

  /// Refresh products.
  Future<void> refresh() => loadProducts(refresh: true);

  /// Load next page.
  Future<void> loadMore() {
    if (!state.hasMore || state.isLoading) return Future.value();
    return loadProducts();
  }
}

/// Products provider.
final productsProvider = NotifierProvider<ProductsNotifier, ProductsState>(() {
  return ProductsNotifier();
});

/// Product detail provider using FutureProvider.
/// Per Riverpod 3.x docs: https://riverpod.dev/docs/concepts/providers
final productDetailProvider = FutureProvider.family<Product, int>((
  ref,
  productId,
) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/products/$productId');

  if (response.statusCode == 200) {
    return Product.fromJson(response.data as Map<String, dynamic>);
  }
  throw Exception('Failed to load product');
});
