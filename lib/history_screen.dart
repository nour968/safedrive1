import 'package:flutter/material.dart';
import 'package:untitled1/ride_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'nav_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // TODO: move to config/env file before shipping.
  final String baseUrl = "http://192.168.1.4:8000";

  List<Map<String, dynamic>> rides = [];
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    loadRides();
  }

  Future<void> loadRides() async {
    setState(() {
      loading = true;
      error = false;
    });

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
        error = true;
      });
    }
  }

  Widget historyCard(
      BuildContext context, {
        required String rideId,
        required String date,
        required String time,
        required String alerts,
      }) {
    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title:
        Text(
          isArabic ? "رقم الرحلة: $rideId" : "Ride ID: $rideId",
        ),
        subtitle: Text(
          isArabic
              ? "التاريخ: $date\nالوقت: $time\nالتنبيهات: $alerts"
              : "Date: $date\nTime: $time\nAlerts: $alerts",
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailScreen(
                rideId: rideId,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: const CustomBottomNavBar(
          currentIndex: 1,
        ),
        appBar: AppBar(
          centerTitle: true,
          title: Text(isArabic ? "السجل" : "History"),
          backgroundColor: const  Color(0xFF8BC98B),
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        body: RefreshIndicator(
          onRefresh: loadRides,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error
              ? Center(
            child: Text(
              isArabic
                  ? "تعذر تحميل السجل"
                  : "Could not load history",
            ),
          )
              : rides.isEmpty
              ? Center(
            child: Text(
              isArabic ? "لا توجد رحلات سابقة" : "No past rides",
            ),
          )
              : ListView(
            padding: const EdgeInsets.all(16),
            children: rides.map((ride) {
              return historyCard(
                context,
                rideId: (ride["ride_id"] ?? "").toString(),
                date: (ride["date"] ?? "").toString(),
                time: (ride["time"] ?? "").toString(),
                alerts: (ride["alerts"] ?? "").toString(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}