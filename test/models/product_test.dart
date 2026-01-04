import 'package:flutter_test/flutter_test.dart';
import 'package:sobro_app/features/products/products_provider.dart';

void main() {
  group('ProductParams', () {
    test('fromJson parses snake_case fields', () {
      final json = {
        'machine_type': 'Excavator',
        'manufacturer': 'Caterpillar',
        'model': 'CAT 320',
        'year_of_production': '2020',
        'serial_number': 'SN123456',
        'weight': '20000 kg',
        'location': 'Warehouse A',
        'item_status': 'Available',
      };

      final params = ProductParams.fromJson(json);

      expect(params.machineType, 'Excavator');
      expect(params.manufacturer, 'Caterpillar');
      expect(params.model, 'CAT 320');
      expect(params.yearOfProduction, '2020');
      expect(params.serialNumber, 'SN123456');
      expect(params.weight, '20000 kg');
      expect(params.location, 'Warehouse A');
      expect(params.itemStatus, 'Available');
    });

    test('fromJson parses Title Case fields (legacy format)', () {
      final json = {
        'Machine type': 'Loader',
        'Manufacturer': 'Komatsu',
        'Model': 'WA470',
        'Year of production': '2019',
        'Serial number': 'KM789',
        'Weight': '15000 kg',
        'Location': 'Yard B',
        'Item status': 'Sold',
      };

      final params = ProductParams.fromJson(json);

      expect(params.machineType, 'Loader');
      expect(params.manufacturer, 'Komatsu');
      expect(params.model, 'WA470');
      expect(params.yearOfProduction, '2019');
    });

    test('hasAnyData returns true when at least one field is set', () {
      final params = ProductParams(manufacturer: 'Test');
      expect(params.hasAnyData, true);
    });

    test('hasAnyData returns false when all fields are null', () {
      final params = ProductParams();
      expect(params.hasAnyData, false);
    });

    test('fromJson handles empty json', () {
      final params = ProductParams.fromJson({});
      expect(params.hasAnyData, false);
    });
  });

  group('ProductFile', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'photo.jpg',
        'path': '/uploads/photo.jpg',
        'type': 'image',
      };

      final file = ProductFile.fromJson(json);

      expect(file.id, 1);
      expect(file.name, 'photo.jpg');
      expect(file.path, '/uploads/photo.jpg');
      expect(file.type, 'image');
    });

    test('fromJson uses defaults for missing values', () {
      final file = ProductFile.fromJson({});

      expect(file.id, 0);
      expect(file.name, '');
      expect(file.path, '');
      expect(file.type, 'image');
    });
  });

  group('ProductCategory', () {
    test('fromJson parses correctly', () {
      final json = {'id': 5, 'name': 'Heavy Equipment', 'count': 42};

      final category = ProductCategory.fromJson(json);

      expect(category.id, 5);
      expect(category.name, 'Heavy Equipment');
      expect(category.count, 42);
    });

    test('fromJson uses default count of 0', () {
      final json = {'id': 1, 'name': 'Test'};
      final category = ProductCategory.fromJson(json);
      expect(category.count, 0);
    });
  });

  group('Product', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'title': 'Excavator CAT 320',
        'content': 'Description here',
        'price': 50000.0,
        'purchase_price': 45000.0,
        'purchase_currency': 'EUR',
        'auction_price': 48000.0,
        'auction_currency': 'USD',
        'direct_sale_price': 52000.0,
        'direct_currency': 'GBP',
        'category_name': 'Heavy Equipment',
        'category_id': 3,
        'status': 'in_stock',
        'files': [
          {'id': 1, 'name': 'img1.jpg', 'path': '/img1.jpg', 'type': 'image'},
          {'id': 2, 'name': 'doc.pdf', 'path': '/doc.pdf', 'type': 'document'},
        ],
        'params': {'manufacturer': 'Caterpillar', 'model': 'CAT 320'},
      };

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.title, 'Excavator CAT 320');
      expect(product.content, 'Description here');
      expect(product.price, 50000.0);
      expect(product.purchasePrice, 45000.0);
      expect(product.purchaseCurrency, 'EUR');
      expect(product.auctionPrice, 48000.0);
      expect(product.auctionCurrency, 'USD');
      expect(product.directSalePrice, 52000.0);
      expect(product.directCurrency, 'GBP');
      expect(product.categoryName, 'Heavy Equipment');
      expect(product.categoryId, 3);
      expect(product.status, 'in_stock');
      expect(product.files.length, 2);
      expect(product.params?.manufacturer, 'Caterpillar');
    });

    test('fromJson uses default values', () {
      final json = {'id': 1, 'title': 'Test Product'};

      final product = Product.fromJson(json);

      expect(product.purchaseCurrency, 'USD');
      expect(product.auctionCurrency, 'USD');
      expect(product.directCurrency, 'USD');
      expect(product.status, 'in_stock');
      expect(product.files, isEmpty);
      expect(product.params, isNull);
    });

    test('imageUrl returns first image path', () {
      final product = Product(
        id: 1,
        title: 'Test',
        files: [
          ProductFile(
            id: 1,
            name: 'doc.pdf',
            path: '/doc.pdf',
            type: 'document',
          ),
          ProductFile(id: 2, name: 'img.jpg', path: '/img.jpg', type: 'image'),
          ProductFile(
            id: 3,
            name: 'img2.jpg',
            path: '/img2.jpg',
            type: 'image',
          ),
        ],
      );

      expect(product.imageUrl, '/img.jpg');
    });

    test('imageUrl returns null when no images', () {
      final product = Product(
        id: 1,
        title: 'Test',
        files: [
          ProductFile(
            id: 1,
            name: 'doc.pdf',
            path: '/doc.pdf',
            type: 'document',
          ),
        ],
      );

      expect(product.imageUrl, isNull);
    });

    test('images returns only image type files', () {
      final product = Product(
        id: 1,
        title: 'Test',
        files: [
          ProductFile(
            id: 1,
            name: 'doc.pdf',
            path: '/doc.pdf',
            type: 'document',
          ),
          ProductFile(id: 2, name: 'img.jpg', path: '/img.jpg', type: 'image'),
          ProductFile(
            id: 3,
            name: 'img2.jpg',
            path: '/img2.jpg',
            type: 'image',
          ),
        ],
      );

      expect(product.images.length, 2);
      expect(product.images.every((f) => f.type == 'image'), true);
    });
  });

  group('ProductsState', () {
    test('initial state has correct defaults', () {
      final state = ProductsState();

      expect(state.products, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.page, 1);
      expect(state.total, 0);
      expect(state.hasMore, true);
      expect(state.searchQuery, isNull);
      expect(state.categoryId, isNull);
      expect(state.categories, isEmpty);
    });

    test('copyWith updates specified fields', () {
      final state = ProductsState();
      final updated = state.copyWith(
        isLoading: true,
        page: 2,
        searchQuery: 'test',
      );

      expect(updated.isLoading, true);
      expect(updated.page, 2);
      expect(updated.searchQuery, 'test');
      expect(updated.products, isEmpty); // unchanged
    });

    test('copyWith with clearCategory clears categoryId', () {
      final state = ProductsState(categoryId: 5);
      final updated = state.copyWith(clearCategory: true);

      expect(updated.categoryId, isNull);
    });

    test('copyWith without clearCategory keeps categoryId', () {
      final state = ProductsState(categoryId: 5);
      final updated = state.copyWith(page: 2);

      expect(updated.categoryId, 5);
    });
  });
}
