import 'package:flutter/material.dart';
import 'camera_permission_screen.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CameraPermissionScreen(),
              ),
            );
          },
          child: const Text("Open Camera"),
        ),
      ),
    );
  }
}