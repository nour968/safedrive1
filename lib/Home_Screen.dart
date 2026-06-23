import 'package:flutter/material.dart';
import 'nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_recording_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String baseUrl = "http://192.168.1.4:8000";

  List<Map<String, dynamic>> rides = [];
  bool loading = true;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  String text(BuildContext context, String en, String ar) {
    String lang = Localizations.localeOf(context).languageCode;
    return lang == "ar" ? ar : en;
  }

  @override
  void initState() {
    super.initState();
    loadRides();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadRides() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt("user_id") ?? 0;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rides/$userId"),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        rides = (data["status"] == "success")
            ? List<Map<String, dynamic>>.from(data["rides"] ?? [])
            : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        rides = [];
        loading = false;
      });
    }
  }

  // ── filter rides by ride_id OR date, case-insensitive ──
  List<Map<String, dynamic>> get filteredRides {
    if (searchQuery.trim().isEmpty) return [];

    final q = searchQuery.trim().toLowerCase();

    return rides.where((ride) {
      final rideId = (ride["ride_id"] ?? "").toString().toLowerCase();
      final date = (ride["date"] ?? "").toString().toLowerCase();
      return rideId.contains(q) || date.contains(q);
    }).toList();
  }

  Widget sessionCard(
      BuildContext context, {
        required String rideId,
        required String date,
        required String time,
        required String alerts,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/ride-detail',
          arguments: {"rideId": rideId},
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
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
              decoration: BoxDecoration(
                color: const Color(0xFF8BC98B),
                borderRadius: BorderRadius.circular(10),
              ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;
    final isSearching = searchQuery.trim().isNotEmpty;

    return Directionality(
      textDirection: lang == "ar" ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: Drawer(
          child: Column(
            children: [
              Container(
                height: 120,
                color: Colors.black,
                alignment: Alignment.center,
                child: const Text(
                  "Alerto",
                  style: TextStyle(color: Colors.green, fontSize: 22),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.green),
                title: Text(text(context, "Profile", "الملف الشخصي")),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.green),
                title: Text(text(context, "History", "السجل")),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/history');
                },
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  text(context, "Logout", "تسجيل الخروج"),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
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
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: text(
                    context,
                    "Search by Ride ID or Date",
                    "ابحث برقم الرحلة أو التاريخ",
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: isSearching
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => searchQuery = "");
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── SEARCH MODE ──────────────────────────────
              if (isSearching) ...[
                Align(
                  alignment: lang == "ar"
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    text(context, "Search Results", "نتائج البحث"),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredRides.isEmpty
                    ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      text(context, "No matching rides",
                          "لا توجد رحلات مطابقة"),
                    ),
                  ),
                )
                    : Column(
                  children: filteredRides.map<Widget>((ride) {
                    return sessionCard(
                      context,
                      rideId: (ride["ride_id"] ?? "").toString(),
                      date: (ride["date"] ?? "").toString(),
                      time: (ride["time"] ?? "").toString(),
                      alerts: (ride["alerts"] ?? "").toString(),
                    );
                  }).toList(),
                ),
              ]

              // ── DEFAULT MODE (Recent Sessions) ───────────
              else ...[
                Align(
                  alignment: lang == "ar"
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    text(context, "Recent Sessions", "الجلسات الأخيرة"),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : rides.isEmpty
                    ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      text(context, "No recent rides",
                          "لا توجد رحلات حديثة"),
                    ),
                  ),
                )
                    : Column(
                  children: rides.take(3).map<Widget>((ride) {
                    return sessionCard(
                      context,
                      rideId: (ride["ride_id"] ?? "").toString(),
                      date: (ride["date"] ?? "").toString(),
                      time: (ride["time"] ?? "").toString(),
                      alerts: (ride["alerts"] ?? "").toString(),
                    );
                  }).toList(),
                ),
              ],

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
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    int driverId = prefs.getInt("user_id") ?? 0;

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraRecordingScreen(driverId: driverId),
                      ),
                    );
                  },
                  child: Text(
                    text(context, "Start Session", "ابدأ الجلسة"),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
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