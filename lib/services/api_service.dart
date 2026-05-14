import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  // 🔥 BACKEND SERVER IP
  static const String baseUrl =
      "http://192.168.1.23:8000";

  // =========================================
  // SEND EVENT TO FLASK
  // =========================================

  static Future<void> sendEvent({
    required int driverId,
    required String eventType,
    required double confidence,
  }) async {

    try {

      final response = await http.post(
        Uri.parse("$baseUrl/event"),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "driver_id": driverId,
          "event_type": eventType,
          "confidence": confidence,
          "timestamp": DateTime.now().toString(),
        }),
      );

      print("✅ SERVER RESPONSE:");
      print(response.body);

    } catch (e) {

      print("❌ API ERROR:");
      print(e);

    }
  }
}