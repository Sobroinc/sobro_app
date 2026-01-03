import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'operations_provider.dart';

/// Operations (Orders) tab for bottom navigation.
class OperationsTab extends ConsumerStatefulWidget {
  const OperationsTab({super.key});

  @override
  ConsumerState<OperationsTab> createState() => _OperationsTabState();
}

class _OperationsTabState extends ConsumerState<OperationsTab> {
  final _scrollController = ScrollController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(operationsProvider.notifier).loadOrders();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(operationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(operationsProvider);

    return Column(
      children: [
        // Status filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _selectedStatus == null,
                onSelected: () {
                  setState(() => _selectedStatus = null);
                  ref.read(operationsProvider.notifier).setFilter(null);
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Pending',
                selected: _selectedStatus == 'pending_payment',
                onSelected: () {
                  setState(() => _selectedStatus = 'pending_payment');
                  ref.read(operationsProvider.notifier).setFilter('pending_payment');
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Paid',
                selected: _selectedStatus == 'paid',
                onSelected: () {
                  setState(() => _selectedStatus = 'paid');
                  ref.read(operationsProvider.notifier).setFilter('paid');
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Shipped',
                selected: _selectedStatus == 'shipped',
                onSelected: () {
                  setState(() => _selectedStatus = 'shipped');
                  ref.read(operationsProvider.notifier).setFilter('shipped');
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Delivered',
                selected: _selectedStatus == 'delivered',
                onSelected: () {
                  setState(() => _selectedStatus = 'delivered');
                  ref.read(operationsProvider.notifier).setFilter('delivered');
                },
              ),
            ],
          ),
        ),

        // Content
        Expanded(child: _buildContent(state)),
      ],
    );
  }

  Widget _buildContent(OperationsState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(operationsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(operationsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.orders.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.orders.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _OrderCard(order: state.orders[index]);
        },
      ),
    );
  }
}

/// Filter chip widget.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Order card widget.
class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/order/${order.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context).withAlpha(38),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.type == 'auction' ? 'Auction' : 'Direct',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${order.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Buyer/Seller
              if (order.buyerName != null)
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Buyer: ${order.buyerName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              if (order.sellerName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Seller: ${order.sellerName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Text(
                    dateFormat.format(order.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order.itemsCount} item${order.itemsCount > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${order.grandTotal.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (order.isPendingPayment) {
      return Colors.orange;
    }
    if (order.isPaid) {
      return Colors.blue;
    }
    if (order.isShipped) {
      return Colors.purple;
    }
    if (order.isDelivered) {
      return Colors.green;
    }
    if (order.isCancelled) {
      return Colors.red;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
