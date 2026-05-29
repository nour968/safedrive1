import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {

  // CHANGE TO YOUR PC IP
  static const String baseUrl =
      "http://192.168.1.64:8000";

  // =====================================================
  // SEND FRAME TO AI
  // =====================================================

  static Future<void> sendFrame({

    required int driverId,
    required String imageBase64,

  }) async {

    try {

      final response = await http.post(

        Uri.parse("$baseUrl/frame"),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({

          "driver_id": driverId,
          "image": imageBase64,

        }),
      );

      print("FRAME STATUS: ${response.statusCode}");

    } catch (e) {

      print("SEND FRAME ERROR: $e");
    }
  }

  // =====================================================
  // TEST EVENT
  // =====================================================

  static Future<void> sendEvent({

    required int driverId,
    required String eventType,
    required double confidence,

  }) async {

    try {

      await http.post(

        Uri.parse("$baseUrl/event"),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({

          "driver_id": driverId,
          "event_type": eventType,
          "confidence": confidence,

        }),
      );

    } catch (e) {

      print("SEND EVENT ERROR: $e");
    }
  }
}
