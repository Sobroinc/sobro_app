import 'package:flutter_test/flutter_test.dart';
import 'package:sobro_app/features/operations/operations_provider.dart';

void main() {
  group('Order', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'type': 'auction',
        'status': 'paid',
        'buyer_name': 'John Doe',
        'seller_name': 'Jane Smith',
        'grand_total': 50000.50,
        'currency': 'EUR',
        'items_count': 3,
        'created_at': '2024-01-15T10:30:00Z',
      };

      final order = Order.fromJson(json);

      expect(order.id, 1);
      expect(order.type, 'auction');
      expect(order.status, 'paid');
      expect(order.buyerName, 'John Doe');
      expect(order.sellerName, 'Jane Smith');
      expect(order.grandTotal, 50000.50);
      expect(order.currency, 'EUR');
      expect(order.itemsCount, 3);
      expect(order.createdAt, DateTime.parse('2024-01-15T10:30:00Z'));
    });

    test('fromJson uses default values for optional fields', () {
      final json = {
        'id': 1,
        'status': 'pending_payment',
        'grand_total': 1000,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final order = Order.fromJson(json);

      expect(order.type, 'direct');
      expect(order.buyerName, isNull);
      expect(order.sellerName, isNull);
      expect(order.currency, 'USD');
      expect(order.itemsCount, 1);
    });

    test('fromJson handles integer grand_total', () {
      final json = {
        'id': 1,
        'status': 'paid',
        'grand_total': 5000,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final order = Order.fromJson(json);

      expect(order.grandTotal, 5000.0);
    });

    group('statusDisplay', () {
      test('returns "Pending Payment" for pending_payment', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'pending_payment',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.statusDisplay, 'Pending Payment');
      });

      test('returns "Paid" for paid', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'paid',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.statusDisplay, 'Paid');
      });

      test('returns "Shipped" for shipped', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'shipped',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.statusDisplay, 'Shipped');
      });

      test('returns "Delivered" for delivered', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'delivered',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.statusDisplay, 'Delivered');
      });

      test('returns "Cancelled" for cancelled', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'cancelled',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.statusDisplay, 'Cancelled');
      });

      test('returns raw status for unknown status', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'custom_status',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.statusDisplay, 'custom_status');
      });
    });

    group('status boolean getters', () {
      test('isPendingPayment returns true for pending_payment', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'pending_payment',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.isPendingPayment, true);
        expect(order.isPaid, false);
        expect(order.isShipped, false);
        expect(order.isDelivered, false);
        expect(order.isCancelled, false);
      });

      test('isPaid returns true for paid', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'paid',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.isPendingPayment, false);
        expect(order.isPaid, true);
        expect(order.isShipped, false);
        expect(order.isDelivered, false);
        expect(order.isCancelled, false);
      });

      test('isShipped returns true for shipped', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'shipped',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.isPendingPayment, false);
        expect(order.isPaid, false);
        expect(order.isShipped, true);
        expect(order.isDelivered, false);
        expect(order.isCancelled, false);
      });

      test('isDelivered returns true for delivered', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'delivered',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.isPendingPayment, false);
        expect(order.isPaid, false);
        expect(order.isShipped, false);
        expect(order.isDelivered, true);
        expect(order.isCancelled, false);
      });

      test('isCancelled returns true for cancelled', () {
        final order = Order(
          id: 1,
          type: 'direct',
          status: 'cancelled',
          grandTotal: 1000,
          createdAt: DateTime.now(),
        );

        expect(order.isPendingPayment, false);
        expect(order.isPaid, false);
        expect(order.isShipped, false);
        expect(order.isDelivered, false);
        expect(order.isCancelled, true);
      });
    });
  });

  group('OperationsState', () {
    test('initial state has correct defaults', () {
      final state = OperationsState();

      expect(state.orders, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.page, 1);
      expect(state.hasMore, true);
      expect(state.statusFilter, isNull);
    });

    test('copyWith updates specified fields', () {
      final state = OperationsState();
      final updated = state.copyWith(
        isLoading: true,
        page: 2,
        hasMore: false,
        statusFilter: 'paid',
      );

      expect(updated.isLoading, true);
      expect(updated.page, 2);
      expect(updated.hasMore, false);
      expect(updated.statusFilter, 'paid');
      expect(updated.orders, isEmpty); // unchanged
    });

    test('copyWith preserves unspecified fields', () {
      final order = Order(
        id: 1,
        type: 'direct',
        status: 'paid',
        grandTotal: 1000,
        createdAt: DateTime.now(),
      );
      final state = OperationsState(orders: [order], page: 2);
      final updated = state.copyWith(isLoading: true);

      expect(updated.orders.length, 1);
      expect(updated.page, 2);
      expect(updated.isLoading, true);
    });

    test('copyWith clears error when not specified', () {
      final state = OperationsState(error: 'Some error');
      final updated = state.copyWith(isLoading: true);

      expect(updated.error, isNull);
    });

    test('copyWith can set error', () {
      final state = OperationsState();
      final updated = state.copyWith(error: 'Network error');

      expect(updated.error, 'Network error');
    });

    test('copyWith preserves statusFilter', () {
      final state = OperationsState(statusFilter: 'pending_payment');
      final updated = state.copyWith(page: 3);

      expect(updated.statusFilter, 'pending_payment');
    });
  });
}
