import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:untitled1/Home_Screen.dart';
import 'camera_recording_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;

  bool isControllerDisposed = false;

  @override
  void initState() {
    super.initState();

    /// ✅ SAFE INIT
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
        if (mounted) _showPermissionPopup();
      });

    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  void _showPermissionPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Camera Recording"),
          content: const Text("Start recording session?"),
          actions: [

            /// ❌ DENY
            TextButton(
              onPressed: () async {

                isControllerDisposed = true;

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

            /// ✅ ALLOW
            TextButton(
              onPressed: () async {

                isControllerDisposed = true;

                await controller?.dispose();
                controller = null;

                if (!mounted) return;

                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraRecordingScreen(),
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
    isControllerDisposed = true;
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    /// ✅ SAFE CHECK (IMPORTANT FIX)
    if (controller == null ||
        !controller!.value.isInitialized ||
        isControllerDisposed) {

      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// 📷 CAMERA PREVIEW
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.previewSize!.height,
                height: controller!.value.previewSize!.width,
                child: CameraPreview(controller!),
              ),
            ),
          ),

          /// 🔙 BACK BUTTON
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {

                isControllerDisposed = true;

                await controller?.dispose();
                controller = null;

                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ),

        ],
      ),
    );
  }
}