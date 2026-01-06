import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for paginated data.
class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final int perPage;
  final int total;
  final bool hasMore;
  final String? searchQuery;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.perPage = 20,
    this.total = 0,
    this.hasMore = true,
    this.searchQuery,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    int? perPage,
    int? total,
    bool? hasMore,
    String? searchQuery,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get isEmpty => items.isEmpty && !isLoading;
  int get totalPages => (total / perPage).ceil();
}

/// Response from paginated API call.
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final bool hasMore;

  const PaginatedResponse({
    required this.items,
    required this.total,
    this.hasMore = true,
  });
}

/// Abstract base class for paginated notifiers.
/// Eliminates duplication of pagination logic across providers.
abstract class PaginatedNotifier<T> extends Notifier<PaginatedState<T>> {
  Timer? _debounceTimer;

  @override
  PaginatedState<T> build() {
    return const PaginatedState();
  }

  /// Override this method to fetch data from API.
  /// Returns PaginatedResponse with items and total count.
  Future<PaginatedResponse<T>> fetchPage({
    required int page,
    required int perPage,
    String? searchQuery,
  });

  /// Load initial data or refresh.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await fetchPage(
        page: 1,
        perPage: state.perPage,
        searchQuery: state.searchQuery,
      );

      state = state.copyWith(
        items: response.items,
        total: response.total,
        page: 1,
        hasMore: response.hasMore && response.items.length >= state.perPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more items (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      final response = await fetchPage(
        page: nextPage,
        perPage: state.perPage,
        searchQuery: state.searchQuery,
      );

      state = state.copyWith(
        items: [...state.items, ...response.items],
        total: response.total,
        page: nextPage,
        hasMore: response.hasMore && response.items.length >= state.perPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Refresh data (pull to refresh).
  Future<void> refresh() async {
    await load();
  }

  /// Search with debounce.
  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query.isEmpty ? null : query);
      load();
    });
  }

  /// Clear search.
  void clearSearch() {
    state = state.copyWith(searchQuery: null);
    load();
  }

  /// Set items per page.
  void setPerPage(int perPage) {
    state = state.copyWith(perPage: perPage);
    load();
  }
}
