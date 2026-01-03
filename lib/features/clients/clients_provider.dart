import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

/// Client model.
/// Per SobroBase app/models/clients.py Client class.
class Client {
  final int id;
  final int? clientNumber;
  final String type;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? country;
  final String? city;
  final String? notes;
  final bool isSeller;
  final bool isBuyer;
  final double totalSales;
  final double totalPurchases;
  final int itemsOnConsignment;
  final int itemsPurchased;
  final DateTime createdAt;

  Client({
    required this.id,
    this.clientNumber,
    required this.type,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.country,
    this.city,
    this.notes,
    this.isSeller = false,
    this.isBuyer = false,
    this.totalSales = 0,
    this.totalPurchases = 0,
    this.itemsOnConsignment = 0,
    this.itemsPurchased = 0,
    required this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int,
      clientNumber: json['client_number'] as int?,
      type: json['type'] as String? ?? 'company',
      name: json['name'] as String,
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      notes: json['notes'] as String?,
      isSeller: json['is_seller'] as bool? ?? false,
      isBuyer: json['is_buyer'] as bool? ?? false,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0,
      totalPurchases: (json['total_purchases'] as num?)?.toDouble() ?? 0,
      itemsOnConsignment: json['items_on_consignment'] as int? ?? 0,
      itemsPurchased: json['items_purchased'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isCompany => type == 'company';
  String get displayName => clientNumber != null ? '#$clientNumber $name' : name;
}

/// Clients state.
class ClientsState {
  final List<Client> clients;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;
  final String? searchQuery;
  final String? typeFilter;

  ClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.searchQuery,
    this.typeFilter,
  });

  ClientsState copyWith({
    List<Client>? clients,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    String? searchQuery,
    String? typeFilter,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }
}

/// Clients notifier.
/// Per Riverpod 3.x docs: https://riverpod.dev/docs/concepts/providers
class ClientsNotifier extends Notifier<ClientsState> {
  @override
  ClientsState build() {
    return ClientsState();
  }

  Future<void> loadClients({String? search, String? type}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      clients: [],
      page: 1,
      searchQuery: search,
      typeFilter: type,
    );

    try {
      final dio = ref.read(dioProvider);
      final params = <String, dynamic>{
        'page': 1,
        'per_page': 20,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (type != null) params['type'] = type;

      final response = await dio.get('/clients', queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final clients = (data['clients'] as List)
            .map((j) => Client.fromJson(j))
            .toList();
        final total = data['total'] as int? ?? clients.length;

        state = state.copyWith(
          clients: clients,
          isLoading: false,
          hasMore: clients.length < total,
        );
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
      final params = <String, dynamic>{
        'page': nextPage,
        'per_page': 20,
      };
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        params['search'] = state.searchQuery;
      }
      if (state.typeFilter != null) params['type'] = state.typeFilter;

      final response = await dio.get('/clients', queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newClients = (data['clients'] as List)
            .map((j) => Client.fromJson(j))
            .toList();
        final total = data['total'] as int? ?? 0;

        state = state.copyWith(
          clients: [...state.clients, ...newClients],
          page: nextPage,
          isLoading: false,
          hasMore: state.clients.length + newClients.length < total,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    await loadClients(search: state.searchQuery, type: state.typeFilter);
  }

  void setFilter({String? search, String? type}) {
    loadClients(search: search, type: type);
  }
}

/// Clients provider.
final clientsProvider = NotifierProvider<ClientsNotifier, ClientsState>(() {
  return ClientsNotifier();
});

/// Client detail provider.
final clientDetailProvider = FutureProvider.family<Client, int>((ref, clientId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/clients/$clientId');
  if (response.statusCode == 200) {
    return Client.fromJson(response.data as Map<String, dynamic>);
  }
  throw Exception('Failed to load client');
});
