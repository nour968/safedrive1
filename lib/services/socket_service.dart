import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static late IO.Socket _socket;

  // ── existing alerts stream (new_alert) ──────────────────
  static final StreamController<Map<String, dynamic>> _alertsController =
  StreamController.broadcast();

  static Stream<Map<String, dynamic>> get alertsStream =>
      _alertsController.stream;

  // ── NEW: per-frame result stream (frame_result) ──────────
  static final StreamController<Map<String, dynamic>> _frameResultController =
  StreamController.broadcast();

  static Stream<Map<String, dynamic>> get frameResultStream =>
      _frameResultController.stream;

  static bool _connected = false;
  static bool get connected => _connected;

  static void connect() {
    _socket = IO.io(
      "http://192.168.1.4:8000",
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

    // Cooldown-gated alerts → snackbar / sound
    _socket.on("new_alert", (data) {
      final alert = Map<String, dynamic>.from(data ?? {});
      _alertsController.add(alert);
    });

    // Every-frame results → live log panel
    _socket.on("frame_result", (data) {
      final frame = Map<String, dynamic>.from(data ?? {});
      _frameResultController.add(frame);
    });
  }

  static void disconnect() {
    _socket.disconnect();
  }

  static void dispose() {
    _alertsController.close();
    _frameResultController.close();
  }
}