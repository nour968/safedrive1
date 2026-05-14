import 'package:flutter/material.dart';

class RideDetailScreen extends StatelessWidget {
  final String rideId;
  final String date;
  final String time;
  final String alerts;

  const RideDetailScreen({
    super.key,
    required this.rideId,
    required this.date,
    required this.time,
    required this.alerts,
  });

  Widget buildRow(String label, String value, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: isArabic
            ? [
          Text(value),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]
            : [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection:
      isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? "تفاصيل الرحلة" : "Ride Details",style: const TextStyle(fontWeight: FontWeight.bold )),
          backgroundColor: const Color(0xFF8BC98B),

        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Column(
              children: [
                // 🔹 Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:  BorderRadius.circular(12),
                      color: Color(0xFF8BC98B),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isArabic
                        ? "رقم الرحلة: $rideId"
                        : "Ride ID: $rideId",
                    style: const TextStyle(fontWeight: FontWeight.bold ,fontSize: 20),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      buildRow(
                          isArabic ? "التاريخ" : "Date", date, isArabic),
                      buildRow(
                          isArabic ? "الوقت" : "Time", time, isArabic),
                      buildRow(isArabic ? "عدد التنبيهات" : "Number of Alerts",
                          alerts, isArabic),
                      buildRow(isArabic ? "المدة" : "Duration",
                          "30 minutes", isArabic),
                      buildRow(isArabic ? "تنبيهات الموبايل" : "Mobile Alerts",
                          "6", isArabic),
                      buildRow(isArabic ? "تنبيهات حزام الأمان" : "Seatbelt Alerts",
                          "2", isArabic),
                      buildRow(isArabic ? "تنبيهات النعاس" : "Drowsy Alerts",
                          "5", isArabic),

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