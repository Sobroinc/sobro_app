import 'package:flutter_test/flutter_test.dart';
import 'package:sobro_app/features/clients/clients_provider.dart';

void main() {
  group('Client', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'client_number': 1001,
        'type': 'company',
        'name': 'Acme Corp',
        'contact_person': 'John Doe',
        'phone': '+1234567890',
        'email': 'john@acme.com',
        'address': '123 Main St',
        'country': 'USA',
        'city': 'New York',
        'notes': 'Important client',
        'is_seller': true,
        'is_buyer': false,
        'total_sales': 50000.50,
        'total_purchases': 25000.25,
        'items_on_consignment': 10,
        'items_purchased': 5,
        'created_at': '2024-01-15T10:30:00Z',
      };

      final client = Client.fromJson(json);

      expect(client.id, 1);
      expect(client.clientNumber, 1001);
      expect(client.type, 'company');
      expect(client.name, 'Acme Corp');
      expect(client.contactPerson, 'John Doe');
      expect(client.phone, '+1234567890');
      expect(client.email, 'john@acme.com');
      expect(client.address, '123 Main St');
      expect(client.country, 'USA');
      expect(client.city, 'New York');
      expect(client.notes, 'Important client');
      expect(client.isSeller, true);
      expect(client.isBuyer, false);
      expect(client.totalSales, 50000.50);
      expect(client.totalPurchases, 25000.25);
      expect(client.itemsOnConsignment, 10);
      expect(client.itemsPurchased, 5);
      expect(client.createdAt, DateTime.parse('2024-01-15T10:30:00Z'));
    });

    test('fromJson uses default values for missing optional fields', () {
      final json = {
        'id': 1,
        'name': 'Test Client',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final client = Client.fromJson(json);

      expect(client.type, 'company');
      expect(client.isSeller, false);
      expect(client.isBuyer, false);
      expect(client.totalSales, 0);
      expect(client.totalPurchases, 0);
      expect(client.itemsOnConsignment, 0);
      expect(client.itemsPurchased, 0);
    });

    test('isCompany returns true for company type', () {
      final client = Client(
        id: 1,
        type: 'company',
        name: 'Test',
        createdAt: DateTime.now(),
      );

      expect(client.isCompany, true);
    });

    test('isCompany returns false for individual type', () {
      final client = Client(
        id: 1,
        type: 'individual',
        name: 'Test',
        createdAt: DateTime.now(),
      );

      expect(client.isCompany, false);
    });

    test('displayName includes client number when available', () {
      final client = Client(
        id: 1,
        clientNumber: 1001,
        type: 'company',
        name: 'Acme Corp',
        createdAt: DateTime.now(),
      );

      expect(client.displayName, '#1001 Acme Corp');
    });

    test('displayName returns just name when no client number', () {
      final client = Client(
        id: 1,
        type: 'company',
        name: 'Acme Corp',
        createdAt: DateTime.now(),
      );

      expect(client.displayName, 'Acme Corp');
    });
  });

  group('ClientsState', () {
    test('initial state has correct defaults', () {
      final state = ClientsState();

      expect(state.clients, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.page, 1);
      expect(state.hasMore, true);
      expect(state.searchQuery, isNull);
      expect(state.typeFilter, isNull);
    });

    test('copyWith updates specified fields', () {
      final state = ClientsState();
      final updated = state.copyWith(
        isLoading: true,
        page: 3,
        searchQuery: 'acme',
        typeFilter: 'company',
      );

      expect(updated.isLoading, true);
      expect(updated.page, 3);
      expect(updated.searchQuery, 'acme');
      expect(updated.typeFilter, 'company');
      expect(updated.clients, isEmpty); // unchanged
    });

    test('copyWith preserves unspecified fields', () {
      final client = Client(
        id: 1,
        type: 'company',
        name: 'Test',
        createdAt: DateTime.now(),
      );
      final state = ClientsState(clients: [client], page: 2);
      final updated = state.copyWith(isLoading: true);

      expect(updated.clients.length, 1);
      expect(updated.page, 2);
      expect(updated.isLoading, true);
    });
  });
}
