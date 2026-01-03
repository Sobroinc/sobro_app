import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_client.dart';
import 'config.dart';

/// WebSocket event.
class WsEvent {
  final String type;
  final Map<String, dynamic> data;

  WsEvent({required this.type, required this.data});

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    return WsEvent(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// WebSocket connection state.
enum WsConnectionState { disconnected, connecting, connected }

/// WebSocket service.
/// Per web_socket_channel docs: https://pub.dev/packages/web_socket_channel
class WebSocketService {
  final Ref _ref;
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  final _eventController = StreamController<WsEvent>.broadcast();
  WsConnectionState _state = WsConnectionState.disconnected;

  WebSocketService(this._ref);

  /// Stream of WebSocket events.
  Stream<WsEvent> get events => _eventController.stream;

  /// Current connection state.
  WsConnectionState get state => _state;

  /// Connect to WebSocket server.
  Future<void> connect() async {
    if (_state == WsConnectionState.connecting ||
        _state == WsConnectionState.connected) {
      return;
    }

    _state = WsConnectionState.connecting;

    try {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.read(key: 'access_token');

      final uri = Uri.parse(
        token != null ? '${AppConfig.wsUrl}?token=$token' : AppConfig.wsUrl,
      );

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _state = WsConnectionState.connected;

      // Listen for messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Start ping timer (keepalive)
      _startPingTimer();
    } catch (e) {
      _state = WsConnectionState.disconnected;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final event = WsEvent.fromJson(json);

      // Ignore pong responses
      if (event.type != 'pong') {
        _eventController.add(event);
      }
    } catch (e) {
      // Invalid JSON, ignore
    }
  }

  void _onError(dynamic error) {
    _state = WsConnectionState.disconnected;
    _cleanup();
    _scheduleReconnect();
  }

  void _onDone() {
    _state = WsConnectionState.disconnected;
    _cleanup();
    _scheduleReconnect();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendPing();
    });
  }

  void _sendPing() {
    if (_channel != null && _state == WsConnectionState.connected) {
      try {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        // Connection lost
        _onDone();
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _channel = null;
  }

  /// Disconnect from WebSocket server.
  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _state = WsConnectionState.disconnected;
  }

  /// Dispose resources.
  void dispose() {
    disconnect();
    _eventController.close();
  }
}

/// WebSocket service provider.
final wsServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// WebSocket events stream provider.
final wsEventsProvider = StreamProvider<WsEvent>((ref) {
  final service = ref.watch(wsServiceProvider);
  return service.events;
});
