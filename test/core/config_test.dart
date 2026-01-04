import 'package:flutter_test/flutter_test.dart';
import 'package:sobro_app/core/config.dart';

void main() {
  group('AppConfig', () {
    test('baseUrl has default development value', () {
      // Default value is for Android emulator
      expect(AppConfig.baseUrl, contains('10.0.2.2'));
      expect(AppConfig.baseUrl, endsWith('/api'));
    });

    test('wsUrl has default development value', () {
      // Default value is for Android emulator
      expect(AppConfig.wsUrl, contains('10.0.2.2'));
      expect(AppConfig.wsUrl, endsWith('/ws'));
    });

    test('connectTimeout is 30 seconds', () {
      expect(AppConfig.connectTimeout, 30000);
    });

    test('receiveTimeout is 30 seconds', () {
      expect(AppConfig.receiveTimeout, 30000);
    });

    test('isProduction is false for default development URLs', () {
      // With default http:// URLs, should not be production
      expect(AppConfig.isProduction, false);
    });

    test('maxPhotoCount is 10', () {
      expect(AppConfig.maxPhotoCount, 10);
    });

    test('imageQuality is 85', () {
      expect(AppConfig.imageQuality, 85);
      expect(AppConfig.imageQuality, lessThanOrEqualTo(100));
      expect(AppConfig.imageQuality, greaterThan(0));
    });

    test('maxImageDimension is 1920', () {
      expect(AppConfig.maxImageDimension, 1920);
    });
  });
}
