import 'dart:async';
import 'package:flutter/material.dart';

import 'socket_service.dart';
import 'alert_sound_service.dart';

class AlertListenerService {
  static StreamSubscription? _sub;

  // 🧠 STORE LAST ALERT TIMES
  static final Map<String, DateTime> _lastAlertTimes = {};

  // ⏱ COOLDOWN DURATION
  static const Duration cooldown = Duration(seconds: 5);

  static void start(BuildContext context) {
    _sub?.cancel();

    _sub = SocketService.alertsStream.listen((alert) async {
      if (!context.mounted) return;

      final type = alert["event_type"] ?? "Unknown";
      final confidence = alert["confidence"] ?? "-";

      // 🧠 CHECK LAST ALERT TIME
      final now = DateTime.now();

      if (_lastAlertTimes.containsKey(type)) {
        final lastTime = _lastAlertTimes[type]!;

        final difference = now.difference(lastTime);

        // 🚫 IGNORE DUPLICATE ALERT
        if (difference < cooldown) {
          print("⏱ Ignored duplicate alert: $type");
          return;
        }
      }

      // ✅ SAVE ALERT TIME
      _lastAlertTimes[type] = now;

      // 🚨 SHOW ALERT
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🚨 $type detected ($confidence)",
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // 🔊 PLAY SOUND
      await AlertSoundService.playAlert();

      print("✅ Alert shown: $type");
    });
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
  }
}