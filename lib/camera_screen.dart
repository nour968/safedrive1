import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'Home_Screen.dart';
import 'services/alert_listener_service.dart';

class CameraRecordingScreen extends StatefulWidget {
  final int driverId;

  const CameraRecordingScreen({
    super.key,
    required this.driverId,
  });

  @override
  State<CameraRecordingScreen> createState() =>
      _CameraRecordingScreenState();
}

class _CameraRecordingScreenState extends State<CameraRecordingScreen> {
  CameraController? controller;

  bool isDisposed = false;

  @override
  void initState() {
    super.initState();

    // ✅ START REAL-TIME ALERTS WHILE RECORDING
    AlertListenerService.start(context);

    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> stopSession() async {
    isDisposed = true;

    try {
      await controller?.stopImageStream();
      await controller?.dispose();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    AlertListenerService.stop();

    isDisposed = true;
    controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(controller!),
          ),

          Positioned(
            top: 50,
            left: 20,
            child: const Text(
              "Recording...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),

          Positioned(
            bottom: 40,
            right: 40,
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: stopSession,
              child: const Icon(Icons.stop),
            ),
          ),
        ],
      ),
    );
  }
}