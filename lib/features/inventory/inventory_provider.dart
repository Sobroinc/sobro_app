import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

/// Inventory item model.
/// Per SobroBase app/api/endpoints/inventory.py
class InventoryItem {
  final int id;
  final String title;
  final String? description;
  final List<String> photos;
  final String? manufacturer;
  final String? model;
  final int? year;
  final String? serialNumber;
  final String? condition;
  final double? purchasePrice;
  final double? salePrice;
  final int quantity;
  final String? location;
  final String? city;
  final bool isGroup;
  final int? childCount;
  final int? parentId;
  final bool inCatalog;

  InventoryItem({
    required this.id,
    required this.title,
    this.description,
    this.photos = const [],
    this.manufacturer,
    this.model,
    this.year,
    this.serialNumber,
    this.condition,
    this.purchasePrice,
    this.salePrice,
    this.quantity = 1,
    this.location,
    this.city,
    this.isGroup = false,
    this.childCount,
    this.parentId,
    this.inCatalog = false,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      serialNumber: json['serial_number'] as String?,
      condition: json['condition'] as String?,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      salePrice: (json['sale_price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      location: json['location'] as String?,
      city: json['city'] as String?,
      isGroup: json['is_group'] as bool? ?? false,
      childCount: json['child_count'] as int?,
      parentId: json['parent_id'] as int?,
      inCatalog: json['in_catalog'] as bool? ?? false,
    );
  }

  String? get firstPhoto => photos.isNotEmpty ? photos.first : null;
}

/// Inventory state.
class InventoryState {
  final List<InventoryItem> items;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;
  final int? currentGroupId;
  final InventoryItem? currentGroup;
  final String? searchQuery;

  InventoryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.currentGroupId,
    this.currentGroup,
    this.searchQuery,
  });

  InventoryState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    int? currentGroupId,
    InventoryItem? currentGroup,
    String? searchQuery,
    bool clearGroup = false,
    bool clearSearch = false,
  }) {
    return InventoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      currentGroupId: clearGroup ? null : (currentGroupId ?? this.currentGroupId),
      currentGroup: clearGroup ? null : (currentGroup ?? this.currentGroup),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

/// Inventory notifier.
/// Per Riverpod 3.x docs: https://riverpod.dev/docs/concepts/providers
class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() {
    return InventoryState();
  }

  Future<void> loadItems({int? groupId, String? search}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentGroupId: groupId,
      items: [],
      page: 1,
      clearGroup: groupId == null,
      searchQuery: search,
      clearSearch: search == null || search.isEmpty,
    );

    try {
      final dio = ref.read(dioProvider);

      if (groupId != null) {
        // Load group items
        final queryParams = <String, dynamic>{
          'page': 1,
          'per_page': 20,
        };
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }
        final response = await dio.get('/inventory/group/$groupId', queryParameters: queryParams);
        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final items = (data['items'] as List)
              .map((j) => InventoryItem.fromJson(j))
              .toList();
          final group = data['group'] != null
              ? InventoryItem.fromJson(data['group'])
              : null;
          final total = data['total'] as int? ?? items.length;

          state = state.copyWith(
            items: items,
            isLoading: false,
            hasMore: items.length < total,
            currentGroup: group,
          );
        }
      } else {
        // Load root items
        final queryParams = <String, dynamic>{
          'page': 1,
          'per_page': 20,
        };
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }
        final response = await dio.get('/inventory', queryParameters: queryParams);

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final items = (data['items'] as List)
              .map((j) => InventoryItem.fromJson(j))
              .toList();
          final total = data['total'] as int? ?? items.length;

          state = state.copyWith(
            items: items,
            isLoading: false,
            hasMore: items.length < total,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final nextPage = state.page + 1;

    try {
      final dio = ref.read(dioProvider);
      final path = state.currentGroupId != null
          ? '/inventory/group/${state.currentGroupId}'
          : '/inventory';

      final queryParams = <String, dynamic>{
        'page': nextPage,
        'per_page': 20,
      };
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        queryParams['search'] = state.searchQuery;
      }

      final response = await dio.get(path, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newItems = (data['items'] as List)
            .map((j) => InventoryItem.fromJson(j))
            .toList();
        final total = data['total'] as int? ?? 0;

        state = state.copyWith(
          items: [...state.items, ...newItems],
          page: nextPage,
          isLoading: false,
          hasMore: state.items.length + newItems.length < total,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    await loadItems(groupId: state.currentGroupId, search: state.searchQuery);
  }

  void goToRoot() {
    loadItems();
  }

  void openGroup(int groupId) {
    loadItems(groupId: groupId);
  }

  void search(String query) {
    loadItems(groupId: state.currentGroupId, search: query);
  }
}

/// Inventory provider.
final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(() {
  return InventoryNotifier();
});

/// Inventory item detail provider.
final inventoryDetailProvider = FutureProvider.family<InventoryItem, int>((ref, itemId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/inventory/$itemId');
  if (response.statusCode == 200) {
    return InventoryItem.fromJson(response.data as Map<String, dynamic>);
  }
  throw Exception('Failed to load item');
});
