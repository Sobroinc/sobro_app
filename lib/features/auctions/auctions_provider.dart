import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

/// Auction model.
/// Per SobroBase app/api/endpoints/auctions.py
class Auction {
  final int productId;
  final String productTitle;
  final double currentPrice;
  final int bidsCount;
  final DateTime endsAt;
  final String timezone;
  final int? timeRemainingSeconds;
  final String? imageUrl;
  final String? winnerName;

  Auction({
    required this.productId,
    required this.productTitle,
    required this.currentPrice,
    required this.bidsCount,
    required this.endsAt,
    this.timezone = 'UTC',
    this.timeRemainingSeconds,
    this.imageUrl,
    this.winnerName,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      productId: json['product_id'] as int,
      productTitle: json['product_title'] as String,
      currentPrice: (json['current_price'] as num).toDouble(),
      bidsCount: json['bids_count'] as int? ?? 0,
      endsAt: DateTime.parse(json['ends_at'] as String),
      timezone: json['timezone'] as String? ?? 'UTC',
      timeRemainingSeconds: json['time_remaining_seconds'] as int?,
      imageUrl: json['image_url'] as String?,
      winnerName: json['winner_name'] as String?,
    );
  }

  bool get isEnding => (timeRemainingSeconds ?? 0) < 3600; // Less than 1 hour
  bool get isActive => (timeRemainingSeconds ?? 0) > 0;

  String get timeRemaining {
    if (timeRemainingSeconds == null || timeRemainingSeconds! <= 0) {
      return 'Ended';
    }
    final hours = timeRemainingSeconds! ~/ 3600;
    final minutes = (timeRemainingSeconds! % 3600) ~/ 60;
    if (hours > 24) {
      return '${hours ~/ 24}d ${hours % 24}h';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// Auctions state.
class AuctionsState {
  final List<Auction> auctions;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  AuctionsState({
    this.auctions = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  AuctionsState copyWith({
    List<Auction>? auctions,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return AuctionsState(
      auctions: auctions ?? this.auctions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Auctions notifier.
/// Per Riverpod 3.x docs: https://riverpod.dev/docs/concepts/providers
class AuctionsNotifier extends Notifier<AuctionsState> {
  @override
  AuctionsState build() {
    return AuctionsState();
  }

  Future<void> loadAuctions() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      auctions: [],
      page: 1,
    );

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auctions/live', queryParameters: {
        'page': 1,
        'per_page': 20,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final auctions = (data['auctions'] as List)
            .map((j) => Auction.fromJson(j))
            .toList();
        final total = data['total'] as int? ?? auctions.length;

        state = state.copyWith(
          auctions: auctions,
          isLoading: false,
          hasMore: auctions.length < total,
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
      final response = await dio.get('/auctions/live', queryParameters: {
        'page': nextPage,
        'per_page': 20,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAuctions = (data['auctions'] as List)
            .map((j) => Auction.fromJson(j))
            .toList();
        final total = data['total'] as int? ?? 0;

        state = state.copyWith(
          auctions: [...state.auctions, ...newAuctions],
          page: nextPage,
          isLoading: false,
          hasMore: state.auctions.length + newAuctions.length < total,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    await loadAuctions();
  }
}

/// Auctions provider.
final auctionsProvider = NotifierProvider<AuctionsNotifier, AuctionsState>(() {
  return AuctionsNotifier();
});

/// Auction detail provider.
final auctionDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, productId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/auctions/$productId');
  if (response.statusCode == 200) {
    return response.data as Map<String, dynamic>;
  }
  throw Exception('Failed to load auction');
});
