/// App configuration with environment variable support.
///
/// Build with custom URLs for production:
/// ```bash
/// flutter build apk \
///   --dart-define=API_BASE_URL=https://api.sobrobase.com/api \
///   --dart-define=WS_URL=wss://api.sobrobase.com/api/ws
/// ```
class AppConfig {
  /// Base URL for API
  /// Production: https://api.yourserver.com/api
  /// Development: http://10.0.2.2:8000/api (Android emulator)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8081/api',
  );

  /// WebSocket URL
  /// Production: wss://api.yourserver.com/api/ws
  /// Development: ws://10.0.2.2:8081/api/ws (Android emulator)
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://10.0.2.2:8081/api/ws',
  );

  /// Connection timeout in milliseconds
  static const int connectTimeout = 30000;

  /// Receive timeout in milliseconds
  static const int receiveTimeout = 30000;

  /// Check if running with production URLs (HTTPS/WSS)
  static bool get isProduction =>
      baseUrl.startsWith('https://') || wsUrl.startsWith('wss://');

  /// Maximum number of photos per item
  static const int maxPhotoCount = 10;

  /// Image quality for compression (0-100)
  static const int imageQuality = 85;

  /// Max image dimension (width or height)
  static const int maxImageDimension = 1920;
}
