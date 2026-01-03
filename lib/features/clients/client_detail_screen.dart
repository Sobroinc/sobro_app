import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'clients_provider.dart';

/// Client detail screen.
class ClientDetailScreen extends ConsumerWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientDetailProvider(clientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Client')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(clientDetailProvider(clientId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (client) => _buildContent(context, client),
      ),
      floatingActionButton: state.hasValue
          ? FloatingActionButton(
              onPressed: () {
                context.push('/client/$clientId/edit');
              },
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, Client client) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: client.isCompany
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  client.isCompany ? Icons.business : Icons.person,
                  size: 40,
                  color: client.isCompany
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (client.isSeller) _buildBadge(context, 'Seller', Colors.orange),
                        if (client.isBuyer) ...[
                          const SizedBox(width: 8),
                          _buildBadge(context, 'Buyer', Colors.blue),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact info
          _buildSection(context, 'Contact Information', [
            if (client.contactPerson != null)
              _buildRow(context, Icons.person_outline, 'Contact', client.contactPerson!),
            if (client.phone != null)
              _buildRow(context, Icons.phone_outlined, 'Phone', client.phone!),
            if (client.email != null)
              _buildRow(context, Icons.email_outlined, 'Email', client.email!),
          ]),

          // Address
          if (client.address != null || client.city != null || client.country != null)
            _buildSection(context, 'Address', [
              if (client.address != null)
                _buildRow(context, Icons.location_on_outlined, 'Address', client.address!),
              if (client.city != null)
                _buildRow(context, Icons.location_city, 'City', client.city!),
              if (client.country != null)
                _buildRow(context, Icons.flag_outlined, 'Country', client.country!),
            ]),

          // Statistics
          _buildSection(context, 'Statistics', [
            _buildRow(context, Icons.sell_outlined, 'Items on Consignment',
                client.itemsOnConsignment.toString()),
            _buildRow(context, Icons.shopping_cart_outlined, 'Items Purchased',
                client.itemsPurchased.toString()),
            _buildRow(context, Icons.attach_money, 'Total Sales',
                '\$${client.totalSales.toStringAsFixed(0)}'),
            _buildRow(context, Icons.payments_outlined, 'Total Purchases',
                '\$${client.totalPurchases.toStringAsFixed(0)}'),
          ]),

          // Notes
          if (client.notes != null && client.notes!.isNotEmpty)
            _buildSection(context, 'Notes', [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(client.notes!),
              ),
            ]),

          // Created date
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Client since ${dateFormat.format(client.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
