import 'package:flutter/material.dart';

class RecorderDashboardScreen extends StatelessWidget {
  const RecorderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        title: const Text("Recorder"),
        actions: const [
          Icon(Icons.menu),
          SizedBox(width:10)
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Videos"),
                Text("Screenshot"),
              ],
            ),

            const SizedBox(height:20),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),

              child: Row(
                children: const [
                  Icon(Icons.video_file),
                  SizedBox(width:10),
                  Text("23423685 videos"),
                ],
              ),
            ),

            const SizedBox(height:30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Audio"),
                Text("External"),
              ],
            ),

            const SizedBox(height:10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Camera"),
                Text("Webcam"),
              ],
            ),

            const SizedBox(height:10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Screen"),
                Text("Entire Screen"),
              ],
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Icon(Icons.home,color: Colors.green),
                Icon(Icons.video_library),
                Icon(Icons.settings),
              ],
            ),

            const SizedBox(height:20),

            GestureDetector(
              onTap: (){
                Navigator.pushNamed(context, '/camera');
              },

              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green,width: 4),
                  shape: BoxShape.circle,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}