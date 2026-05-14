import 'package:flutter/material.dart';
import '../lib/camera_screen.dart';
import '../lib/history_screen.dart';
import '../lib/ride_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              "Ride ID: $rideId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text("Date: $date"),
          Text("Time: $time"),
          Text("Number of Alerts: $alerts"),
          const SizedBox(height: 10),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
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
            child: const Text("View Details"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("العربية"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("English"),
                ),
              ],
            ),

            const ListTile(
              leading: Icon(Icons.person, color: Colors.green),
              title: Text("Profile"),
            ),

            ListTile(
              leading: const Icon(Icons.history, color: Colors.green),
              title: const Text("History"),
              onTap: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        title: Row(
          children: [
            Image.asset("assets/logo.png", height: 30),
            const SizedBox(width: 10),
            const Text(
              "Alerto",
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ""),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Sessions",
                style: TextStyle(
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

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/camera');
                },
                child: const Text(
                  "Start Session",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}