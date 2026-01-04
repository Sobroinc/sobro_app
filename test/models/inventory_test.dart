import 'package:flutter_test/flutter_test.dart';
import 'package:sobro_app/features/inventory/inventory_provider.dart';

void main() {
  group('InventoryItem', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'title': 'Excavator CAT 320',
        'description': 'Heavy duty excavator',
        'photos': ['/img1.jpg', '/img2.jpg'],
        'manufacturer': 'Caterpillar',
        'model': 'CAT 320',
        'year': 2020,
        'serial_number': 'SN123456',
        'condition': 'Good',
        'purchase_price': 45000.0,
        'sale_price': 55000.0,
        'quantity': 2,
        'location': 'Warehouse A',
        'city': 'Berlin',
        'is_group': true,
        'child_count': 5,
        'parent_id': 10,
        'in_catalog': true,
      };

      final item = InventoryItem.fromJson(json);

      expect(item.id, 1);
      expect(item.title, 'Excavator CAT 320');
      expect(item.description, 'Heavy duty excavator');
      expect(item.photos, ['/img1.jpg', '/img2.jpg']);
      expect(item.manufacturer, 'Caterpillar');
      expect(item.model, 'CAT 320');
      expect(item.year, 2020);
      expect(item.serialNumber, 'SN123456');
      expect(item.condition, 'Good');
      expect(item.purchasePrice, 45000.0);
      expect(item.salePrice, 55000.0);
      expect(item.quantity, 2);
      expect(item.location, 'Warehouse A');
      expect(item.city, 'Berlin');
      expect(item.isGroup, true);
      expect(item.childCount, 5);
      expect(item.parentId, 10);
      expect(item.inCatalog, true);
    });

    test('fromJson uses default values for missing fields', () {
      final json = {'id': 1, 'title': 'Test Item'};

      final item = InventoryItem.fromJson(json);

      expect(item.id, 1);
      expect(item.title, 'Test Item');
      expect(item.description, isNull);
      expect(item.photos, isEmpty);
      expect(item.manufacturer, isNull);
      expect(item.model, isNull);
      expect(item.year, isNull);
      expect(item.serialNumber, isNull);
      expect(item.condition, isNull);
      expect(item.purchasePrice, isNull);
      expect(item.salePrice, isNull);
      expect(item.quantity, 1);
      expect(item.location, isNull);
      expect(item.city, isNull);
      expect(item.isGroup, false);
      expect(item.childCount, isNull);
      expect(item.parentId, isNull);
      expect(item.inCatalog, false);
    });

    test('fromJson handles numeric prices as int', () {
      final json = {
        'id': 1,
        'title': 'Test',
        'purchase_price': 1000,
        'sale_price': 1500,
      };

      final item = InventoryItem.fromJson(json);

      expect(item.purchasePrice, 1000.0);
      expect(item.salePrice, 1500.0);
    });

    group('firstPhoto', () {
      test('returns first photo when photos exist', () {
        final item = InventoryItem(
          id: 1,
          title: 'Test',
          photos: ['/img1.jpg', '/img2.jpg', '/img3.jpg'],
        );

        expect(item.firstPhoto, '/img1.jpg');
      });

      test('returns null when photos is empty', () {
        final item = InventoryItem(id: 1, title: 'Test', photos: []);

        expect(item.firstPhoto, isNull);
      });

      test('returns null when photos is default empty list', () {
        final item = InventoryItem(id: 1, title: 'Test');

        expect(item.firstPhoto, isNull);
      });
    });
  });

  group('InventoryState', () {
    test('initial state has correct defaults', () {
      final state = InventoryState();

      expect(state.items, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.page, 1);
      expect(state.hasMore, true);
      expect(state.currentGroupId, isNull);
      expect(state.currentGroup, isNull);
      expect(state.searchQuery, isNull);
    });

    test('copyWith updates specified fields', () {
      final state = InventoryState();
      final updated = state.copyWith(
        isLoading: true,
        page: 3,
        hasMore: false,
        currentGroupId: 5,
        searchQuery: 'excavator',
      );

      expect(updated.isLoading, true);
      expect(updated.page, 3);
      expect(updated.hasMore, false);
      expect(updated.currentGroupId, 5);
      expect(updated.searchQuery, 'excavator');
      expect(updated.items, isEmpty); // unchanged
    });

    test('copyWith preserves unspecified fields', () {
      final item = InventoryItem(id: 1, title: 'Test');
      final state = InventoryState(items: [item], page: 2);
      final updated = state.copyWith(isLoading: true);

      expect(updated.items.length, 1);
      expect(updated.page, 2);
      expect(updated.isLoading, true);
    });

    test('copyWith with clearGroup clears group-related fields', () {
      final group = InventoryItem(id: 10, title: 'Group');
      final state = InventoryState(currentGroupId: 10, currentGroup: group);
      final updated = state.copyWith(clearGroup: true);

      expect(updated.currentGroupId, isNull);
      expect(updated.currentGroup, isNull);
    });

    test('copyWith without clearGroup keeps group-related fields', () {
      final group = InventoryItem(id: 10, title: 'Group');
      final state = InventoryState(currentGroupId: 10, currentGroup: group);
      final updated = state.copyWith(page: 2);

      expect(updated.currentGroupId, 10);
      expect(updated.currentGroup, group);
    });

    test('copyWith with clearSearch clears searchQuery', () {
      final state = InventoryState(searchQuery: 'test query');
      final updated = state.copyWith(clearSearch: true);

      expect(updated.searchQuery, isNull);
    });

    test('copyWith without clearSearch keeps searchQuery', () {
      final state = InventoryState(searchQuery: 'test query');
      final updated = state.copyWith(page: 2);

      expect(updated.searchQuery, 'test query');
    });

    test('copyWith clears error when not specified', () {
      final state = InventoryState(error: 'Some error');
      final updated = state.copyWith(isLoading: true);

      // error is not preserved in copyWith by design (uses error: error parameter)
      expect(updated.error, isNull);
    });
  });
}
