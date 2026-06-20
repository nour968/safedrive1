import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {

  // CHANGE TO YOUR PC IP
  static const String baseUrl =
      "http://192.168.1.4:8000";

  // =====================================================
  // START RIDE
  // =====================================================

  static Future<int?> startRide({

    required int driverId,

  }) async {

    try {

      final response = await http.post(

        Uri.parse("$baseUrl/start-ride"),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({

          "driver_id": driverId,

        }),
      );

      print("START RIDE STATUS: ${response.statusCode}");
      print("START RIDE BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        return data["ride_id"] as int;
      }

      return null;

    } catch (e, stack) {
      print("START RIDE ERROR: $e");
      print(stack);
      return null;
    }
  }

  // =====================================================
  // END RIDE
  // =====================================================

  static Future<void> endRide(int rideId) async {

    try {

      final response = await http.post(

        Uri.parse("$baseUrl/end-ride/$rideId"),

        headers: {
          "Content-Type": "application/json",
        },
      );

      print("END RIDE STATUS: ${response.statusCode}");
      print("END RIDE BODY: ${response.body}");

    } catch (e, stack) {
      print("END RIDE ERROR: $e");
      print(stack);
    }
  }

  // =====================================================
  // SEND FRAME TO AI
  // =====================================================

  static Future<void> sendFrame({

    required int driverId,
    int? rideId,
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
          "ride_id": rideId,
          "image": imageBase64,

        }),
      );

      print("FRAME STATUS: ${response.statusCode}");
      print("FRAME BODY: ${response.body}");
    } catch (e, stack) {
      print("SEND FRAME ERROR: $e");
      print(stack);
    }
  }

  // =====================================================
  // TEST EVENT
  // =====================================================

  static Future<void> sendEvent({

    required int driverId,
    int? rideId,
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
          "ride_id": rideId,
          "event_type": eventType,
          "confidence": confidence,

        }),
      );

    } catch (e) {

      print("SEND EVENT ERROR: $e");
    }
  }
}