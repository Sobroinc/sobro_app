import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'operations_provider.dart';

/// Order detail screen.
class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
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
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    final status = data['status'] as String? ?? 'unknown';
    final type = data['type'] as String? ?? 'direct';
    final buyer = data['buyer'] as Map<String, dynamic>?;
    final seller = data['seller'] as Map<String, dynamic>?;
    final totals = data['totals'] as Map<String, dynamic>?;
    final items = data['items'] as List<dynamic>? ?? [];
    final shipment = data['shipment'] as Map<String, dynamic>?;
    final createdAt = data['created_at'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and type
          Row(
            children: [
              _buildStatusChip(context, status),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(type == 'auction' ? 'Auction' : 'Direct Sale'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Buyer
          if (buyer != null) ...[
            Text('Buyer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text(
                          buyer['name'] as String? ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (buyer['email'] != null) ...[
                      const SizedBox(height: 8),
                      Text(buyer['email'] as String),
                    ],
                    if (buyer['phone'] != null) ...[
                      const SizedBox(height: 4),
                      Text(buyer['phone'] as String),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Seller
          if (seller != null) ...[
            Text('Seller', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.store),
                    const SizedBox(width: 8),
                    Text(
                      seller['name'] as String? ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Items
          if (items.isNotEmpty) ...[
            Text(
              'Items (${items.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: items.map((item) {
                  final itemData = item as Map<String, dynamic>;
                  return ListTile(
                    title: Text(itemData['product_title'] as String? ?? 'Item'),
                    trailing: Text(
                      '\$${(itemData['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Totals
          if (totals != null) ...[
            Text('Totals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRow(
                      context,
                      'Subtotal',
                      '\$${(totals['subtotal'] as num?)?.toStringAsFixed(0) ?? '0'}',
                    ),
                    if ((totals['commission'] as num?) != null &&
                        (totals['commission'] as num) > 0)
                      _buildRow(
                        context,
                        'Commission',
                        '\$${(totals['commission'] as num).toStringAsFixed(0)}',
                      ),
                    if ((totals['shipping'] as num?) != null &&
                        (totals['shipping'] as num) > 0)
                      _buildRow(
                        context,
                        'Shipping',
                        '\$${(totals['shipping'] as num).toStringAsFixed(0)}',
                      ),
                    const Divider(),
                    _buildRow(
                      context,
                      'Grand Total',
                      '\$${(totals['grand_total'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Shipment
          if (shipment != null) ...[
            Text('Shipment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (shipment['carrier'] != null)
                      _buildRow(
                        context,
                        'Carrier',
                        shipment['carrier'] as String,
                      ),
                    if (shipment['tracking_number'] != null)
                      _buildRow(
                        context,
                        'Tracking #',
                        shipment['tracking_number'] as String,
                      ),
                    if (shipment['ship_to_address'] != null)
                      _buildRow(
                        context,
                        'Address',
                        shipment['ship_to_address'] as String,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Created date
          if (createdAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Created: ${dateFormat.format(DateTime.parse(createdAt))}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending_payment':
        color = Colors.orange;
        label = 'Pending Payment';
        break;
      case 'paid':
        color = Colors.blue;
        label = 'Paid';
        break;
      case 'shipped':
        color = Colors.purple;
        label = 'Shipped';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'Delivered';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
