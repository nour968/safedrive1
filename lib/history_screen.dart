import 'package:flutter/material.dart';
import 'package:untitled1/ride_detail_screen.dart';
import 'nav_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Widget historyCard(BuildContext context,
      {required String rideId,
        required String date,
        required String time,
        required String alerts}) {

    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(
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
                date: date,
                time: time,
                alerts: alerts,
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

    return Directionality( // 🔥 important for RTL
      textDirection:
      isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        bottomNavigationBar: const CustomBottomNavBar(
          currentIndex: 1,
        ),
        appBar: AppBar(
          title: Text(isArabic ? "السجل" : "History"),
          backgroundColor: const Color(0xFF8BC98B),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              historyCard(context,
                  rideId: "AB899395",
                  date: "20-11-2021",
                  time: "12:10 pm",
                  alerts: "13"),
              historyCard(context,
                  rideId: "ADER1223",
                  date: "20-11-2021",
                  time: "2:30 pm",
                  alerts: "3"),
            ],
          ),
        ),
      ),
    );
  }
}