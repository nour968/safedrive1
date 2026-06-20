import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RideDetailScreen extends StatefulWidget {
  final String rideId;

  const RideDetailScreen({super.key, required this.rideId});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  // TODO: move to config before shipping
  final String baseUrl = "http://192.168.1.4:8000";

  Map<String, dynamic>? ride;
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    loadRideDetail();
  }

  Future<void> loadRideDetail() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/ride-detail/${widget.rideId}"),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data["status"] == "success") {
        setState(() {
          ride = data["ride"];
          loading = false;
        });
      } else {
        setState(() {
          error = true;
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  Widget buildRow(String label, String value, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: isArabic
            ? [
          Text(value),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]
            : [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            isArabic ? "تفاصيل الرحلة" : "Ride Details",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF8BC98B),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error || ride == null
            ? Center(
          child: Text(
            isArabic ? "تعذر تحميل تفاصيل الرحلة" : "Could not load ride details",
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF8BC98B),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isArabic
                        ? "رقم الرحلة: ${ride!["ride_id"]}"
                        : "Ride ID: ${ride!["ride_id"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      buildRow(isArabic ? "التاريخ" : "Date",
                          ride!["date"].toString(), isArabic),
                      buildRow(isArabic ? "الوقت" : "Time",
                          ride!["time"].toString(), isArabic),
                      buildRow(
                          isArabic ? "عدد التنبيهات" : "Number of Alerts",
                          ride!["total_alerts"].toString(),
                          isArabic),
                      buildRow(isArabic ? "المدة" : "Duration",
                          "${ride!["duration_minutes"]} ${isArabic ? "دقيقة" : "minutes"}",
                          isArabic),
                      buildRow(isArabic ? "تنبيهات الموبايل" : "Mobile Alerts",
                          ride!["mobile_alerts"].toString(), isArabic),
                      buildRow(
                          isArabic ? "تنبيهات حزام الأمان" : "Seatbelt Alerts",
                          ride!["seatbelt_alerts"].toString(),
                          isArabic),
                      buildRow(isArabic ? "تنبيهات النعاس" : "Drowsy Alerts",
                          ride!["drowsy_alerts"].toString(), isArabic),
                      buildRow(isArabic ? "تنبيهات التثاؤب" : "Yawning Alerts",
                          ride!["yawning_alerts"].toString(), isArabic),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}