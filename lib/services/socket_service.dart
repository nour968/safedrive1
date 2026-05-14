import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static late IO.Socket socket;

  static void connect() {
    socket = IO.io(
      "http://192.168.1.64:8000",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print("✅ Connected to server");
    });

    socket.on("new_alert", (data) {
      print("🚨 ALERT RECEIVED: $data");
    });

    socket.onDisconnect((_) {
      print("❌ Disconnected");
    });
  }
}