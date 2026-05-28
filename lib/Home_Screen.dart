import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'camera_recording_screen.dart';
import 'nav_bar.dart';

import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'services/alert_listener_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOpeningCamera = false;

  @override
  void initState() {
    super.initState();

    // 🔥 CONNECT SOCKET ONCE
    SocketService.connect();

    // 🌍 GLOBAL ALERT SYSTEM (works everywhere)
    AlertListenerService.start(context);
  }


  String text(BuildContext context, String en, String ar) {
    String lang = Localizations.localeOf(context).languageCode;
    return lang == "ar" ? ar : en;
  }

  Widget sessionCard(
      BuildContext context, {
        required String rideId,
        required String date,
        required String time,
        required String alerts,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            color: Colors.green.shade100,
            child: Text(
              "${text(context, "Ride ID", "رقم الرحلة")}: $rideId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text("${text(context, "Date", "التاريخ")}: $date"),
          Text("${text(context, "Time", "الوقت")}: $time"),
          Text("${text(context, "Alerts", "التنبيهات")}: $alerts"),
        ],
      ),
    );
  }

  Future<void> openCamera() async {
    if (isOpeningCamera) return;
    isOpeningCamera = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int driverId = prefs.getInt("user_id") ?? 1;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CameraRecordingScreen(driverId: driverId),
        ),
      );
    } catch (e) {
      debugPrint("Open camera error: $e");
    } finally {
      isOpeningCamera = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection: lang == "ar" ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [

              TextField(
                decoration: InputDecoration(
                  hintText: text(context, "Search", "بحث"),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                text(context, "Recent Sessions", "الجلسات الأخيرة"),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              sessionCard(
                context,
                rideId: "AB899395",
                date: "20-11-2021",
                time: "12:10 pm",
                alerts: "13",
              ),

              sessionCard(
                context,
                rideId: "ADER1223",
                date: "20-11-2021",
                time: "2:30 pm",
                alerts: "3",
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();

                  int driverId = prefs.getInt("user_id") ?? 1;

                  ApiService.sendEvent(
                    driverId: driverId,
                    eventType: "TestEvent",
                    confidence: 0.95,
                  );
                },
                child: const Text("Send Test Event"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: openCamera,
                child: const Text("Start Session"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}