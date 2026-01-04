import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auctions_provider.dart';

/// Auction detail screen.
class AuctionDetailScreen extends ConsumerWidget {
  final int productId;

  const AuctionDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auctionDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Auction')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(auctionDetailProvider(productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final title = data['product_title'] as String? ?? 'Auction';
    final currentPrice = (data['current_price'] as num?)?.toDouble() ?? 0;
    final startPrice = (data['start_price'] as num?)?.toDouble() ?? 0;
    final reservePrice = (data['reserve_price'] as num?)?.toDouble();
    final bidsCount = data['bids_count'] as int? ?? 0;
    final status = data['status'] as String? ?? 'unknown';
    final winnerName = data['current_winner_name'] as String?;
    final timeRemaining = data['time_remaining_seconds'] as int?;
    final endsAtLocal = data['ends_at_local'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStatusChip(context, status),
          const SizedBox(height: 24),

          // Current price
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Current Bid',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${currentPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$bidsCount bids',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time remaining
          if (timeRemaining != null && timeRemaining > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time Remaining'),
                          Text(
                            _formatTime(timeRemaining),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRow(
                    context,
                    'Start Price',
                    '\$${startPrice.toStringAsFixed(0)}',
                  ),
                  if (reservePrice != null)
                    _buildRow(
                      context,
                      'Reserve Price',
                      '\$${reservePrice.toStringAsFixed(0)}',
                    ),
                  if (winnerName != null)
                    _buildRow(context, 'Leading Bidder', winnerName),
                  if (endsAtLocal != null)
                    _buildRow(context, 'Ends At', endsAtLocal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'scheduled':
        color = Colors.blue;
        break;
      case 'ended':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return 'Ended';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 24) {
      return '${hours ~/ 24}d ${hours % 24}h';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
