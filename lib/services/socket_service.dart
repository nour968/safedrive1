import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static late IO.Socket _socket;

  static final StreamController<Map<String, dynamic>> _alertsController =
  StreamController.broadcast();

  static Stream<Map<String, dynamic>> get alertsStream =>
      _alertsController.stream;

  static bool _connected = false;

  static void connect() {
    _socket = IO.io(
      "http://192.168.1.64:8000",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket.onConnect((_) {
      _connected = true;
      print("✅ Socket connected");
    });

    _socket.onDisconnect((_) {
      _connected = false;
      print("⚠️ Socket disconnected");
    });

    _socket.onError((error) {
      print("❌ Socket error: $error");
    });

    // 🚨 ONLY SEND DATA
    _socket.on("new_alert", (data) {
      final alert = Map<String, dynamic>.from(data ?? {});
      _alertsController.add(alert);
    });
  }

  static void disconnect() {
    _socket.disconnect();
  }

  static void dispose() {
    _alertsController.close();
  }
}