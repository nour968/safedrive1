import 'package:flutter/material.dart';
import 'nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_recording_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 🔥 Get language directly from app locale
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
          )
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
          Text("${text(context, "Number of Alerts", "عدد التنبيهات")}: $alerts"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection:
      lang == "ar" ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        drawer: Drawer(
          child: Column(
            children: [

              Container(
                height: 120,
                color: Colors.black,
                alignment: Alignment.center,
                child: const Text(
                  "Alerto",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 22,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// PROFILE
              ListTile(
                leading: const Icon(
                  Icons.person,
                  color: Colors.green,
                ),

                title: Text(
                  text(context, "Profile", "الملف الشخصي"),
                ),

                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/profile',
                  );
                },
              ),

              /// HISTORY
              ListTile(
                leading: const Icon(
                  Icons.history,
                  color: Colors.green,
                ),

                title: Text(
                  text(context, "History", "السجل"),
                ),

                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/history',
                  );
                },
              ),

              const Spacer(),

              /// LOGOUT
              const Divider(),

              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),

                title: Text(
                  text(context, "Logout", "تسجيل الخروج"),
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),

                onTap: () {

                  /// REMOVE ALL SCREENS
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (route) => false,
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF8BC98B)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("  "),
              Image.asset(
                "assets/Logo_alerto-removebg-preview.png",
                height: 100,
              ),
            ],
          ),
        ),

        bottomNavigationBar: const CustomBottomNavBar(
          currentIndex: 0,
        ),

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

              Align(
                alignment: lang == "ar"
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  text(context, "Recent Sessions", "الجلسات الأخيرة"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC98B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    SharedPreferences prefs =
                    await SharedPreferences.getInstance();

                    int driverId =
                        prefs.getInt("user_id") ?? 0;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraRecordingScreen(
                          driverId: driverId,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    text(context, "Start Session", "ابدأ الجلسة"),
                    style: const TextStyle(fontSize: 18,color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}