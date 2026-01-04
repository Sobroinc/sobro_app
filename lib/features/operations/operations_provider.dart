import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

/// Order model.
/// Per SobroBase app/api/endpoints/orders.py
class Order {
  final int id;
  final String type;
  final String status;
  final String? buyerName;
  final String? sellerName;
  final double grandTotal;
  final String currency;
  final int itemsCount;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.type,
    required this.status,
    this.buyerName,
    this.sellerName,
    required this.grandTotal,
    this.currency = 'USD',
    this.itemsCount = 1,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'direct',
      status: json['status'] as String,
      buyerName: json['buyer_name'] as String?,
      sellerName: json['seller_name'] as String?,
      grandTotal: (json['grand_total'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      itemsCount: json['items_count'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending_payment':
        return 'Pending Payment';
      case 'paid':
        return 'Paid';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isPendingPayment => status == 'pending_payment';
  bool get isPaid => status == 'paid';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
}

/// Operations state.
class OperationsState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;
  final String? statusFilter;

  OperationsState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.statusFilter,
  });

  OperationsState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    String? statusFilter,
  }) {
    return OperationsState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

/// Operations notifier.
/// Per Riverpod 3.x docs: https://riverpod.dev/docs/concepts/providers
class OperationsNotifier extends Notifier<OperationsState> {
  @override
  OperationsState build() {
    return OperationsState();
  }

  Future<void> loadOrders({String? status}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      orders: [],
      page: 1,
      statusFilter: status,
    );

    try {
      final dio = ref.read(dioProvider);
      final params = <String, dynamic>{'page': 1, 'per_page': 20};
      if (status != null) params['status'] = status;

      final response = await dio.get('/orders', queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final orders = (data['orders'] as List)
            .map((j) => Order.fromJson(j))
            .toList();
        final total = data['total'] as int? ?? orders.length;

        state = state.copyWith(
          orders: orders,
          isLoading: false,
          hasMore: orders.length < total,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final nextPage = state.page + 1;

    try {
      final dio = ref.read(dioProvider);
      final params = <String, dynamic>{'page': nextPage, 'per_page': 20};
      if (state.statusFilter != null) params['status'] = state.statusFilter;

      final response = await dio.get('/orders', queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newOrders = (data['orders'] as List)
            .map((j) => Order.fromJson(j))
            .toList();
        final total = data['total'] as int? ?? 0;

        state = state.copyWith(
          orders: [...state.orders, ...newOrders],
          page: nextPage,
          isLoading: false,
          hasMore: state.orders.length + newOrders.length < total,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    await loadOrders(status: state.statusFilter);
  }

  void setFilter(String? status) {
    loadOrders(status: status);
  }
}

/// Operations provider.
final operationsProvider =
    NotifierProvider<OperationsNotifier, OperationsState>(() {
      return OperationsNotifier();
    });

/// Order detail provider.
final orderDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  orderId,
) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/orders/$orderId');
  if (response.statusCode == 200) {
    return response.data as Map<String, dynamic>;
  }
  throw Exception('Failed to load order');
});
