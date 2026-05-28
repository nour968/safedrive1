import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'Home_Screen.dart';
import 'camera_recording_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;

  bool isDisposed = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCamera();
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {});

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showPopup();
      });
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  void _showPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("Camera Recording"),
          content: const Text("Start recording session?"),
          actions: [

            TextButton(
              onPressed: () async {
                isDisposed = true;

                await controller?.dispose();
                controller = null;

                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
              child: const Text("Deny"),
            ),

            TextButton(
              onPressed: () async {
                isDisposed = true;

                await controller?.dispose();
                controller = null;

                if (!mounted) return;

                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraRecordingScreen(driverId: 1),
                  ),
                );
              },
              child: const Text("Allow"),
            ),

          ],
        );
      },
    );
  }

  @override
  void dispose() {
    isDisposed = true;
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null ||
        !controller!.value.isInitialized ||
        isDisposed) {
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
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                isDisposed = true;
                await controller?.dispose();
                if (mounted) Navigator.pop(context);
              },
            ),
          ),

        ],
      ),
    );
  }
}