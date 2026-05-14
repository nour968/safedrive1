import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'Home_Screen.dart';

class CameraRecordingScreen extends StatefulWidget {
  const CameraRecordingScreen({super.key});

  @override
  State<CameraRecordingScreen> createState() =>
      _CameraRecordingScreenState();
}

class _CameraRecordingScreenState
    extends State<CameraRecordingScreen> {

  CameraController? controller;
  List<CameraDescription>? cameras;

  int currentCameraIndex = 0;

  bool isRecording = false;
  bool isPaused = false;
  bool cameraClosed = false;

  Timer? timer;
  int seconds = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// 🔥 INIT CAMERA
  Future<void> _initCamera() async {
    try {

      cameras = await availableCameras();

      controller = CameraController(
        cameras![currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {});

      await _startRecording();

    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  /// 🔁 FLIP CAMERA
  Future<void> _flipCamera() async {

    if (cameras == null || cameras!.length < 2) return;

    try {

      currentCameraIndex =
          (currentCameraIndex + 1) % cameras!.length;

      await controller?.dispose();

      controller = CameraController(
        cameras![currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {});

    } catch (e) {
      debugPrint("Flip error: $e");
    }
  }

  /// ⏱ TIMER
  String get formattedTime {
    int m = seconds ~/ 60;
    int s = seconds % 60;

    return "${m.toString().padLeft(2, '0')}:"
        "${s.toString().padLeft(2, '0')}";
  }

  void startTimer() {
    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted) return;

        setState(() {
          seconds++;
        });
      },
    );
  }

  /// ▶ START RECORDING
  Future<void> _startRecording() async {

    try {

      await Future.delayed(const Duration(milliseconds: 300));

      await controller!.startVideoRecording();

      startTimer();

      setState(() {
        isRecording = true;
      });

    } catch (e) {
      debugPrint("Start error: $e");
    }
  }

  /// ⏸ PAUSE / RESUME
  Future<void> _togglePause() async {

    if (!isRecording) return;

    try {

      if (isPaused) {
        await controller!.resumeVideoRecording();
        startTimer();
      } else {
        await controller!.pauseVideoRecording();
        timer?.cancel();
      }

      setState(() {
        isPaused = !isPaused;
      });

    } catch (e) {
      debugPrint("Pause error: $e");
    }
  }

  /// 📌 REAL SAVE TO GALLERY
  Future<bool> saveVideoToGallery(String filePath) async {

    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.isAuth) {
      debugPrint("Permission denied");
      return false;
    }

    final file = File(filePath);

    final entity = await PhotoManager.editor.saveVideo(
      file,
      title: "MyApp_${DateTime.now().millisecondsSinceEpoch}",
    );

    return entity != null;
  }

  /// ⏹ STOP RECORDING
  Future<void> _stopRecording() async {

    try {

      timer?.cancel();

      final file =
      await controller!.stopVideoRecording();

      debugPrint("Temp path: ${file.path}");

      /// ✅ SAVE TO GALLERY
      final saved = await saveVideoToGallery(file.path);

      debugPrint(saved
          ? "Saved to gallery"
          : "Save failed");

      await controller?.dispose();
      controller = null;

      setState(() {
        cameraClosed = true;
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Saved"),
          content: Text(
            saved
                ? "Video saved successfully!"
                : "Failed to save video",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );

    } catch (e) {
      debugPrint("Stop error: $e");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (cameraClosed ||
        controller == null ||
        !controller!.value.isInitialized) {

      return const Scaffold(
        backgroundColor: Colors.black,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [

          /// 🎥 CAMERA PREVIEW
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

          /// 🔴 TIMER
          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record,
                    color: Colors.red),
                const SizedBox(width: 10),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          /// ⏸ PAUSE
          Positioned(
            bottom: 40,
            left: MediaQuery.of(context).size.width / 2 - 120,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _togglePause,
              child: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: const Color(0xFF8BC98B),
              ),
            ),
          ),

          /// ⏹ STOP
          Positioned(
            bottom: 40,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: _stopRecording,
              child: const Icon(Icons.stop),
            ),
          ),

          /// 🔁 FLIP
          Positioned(
            bottom: 40,
            left: MediaQuery.of(context).size.width / 2 + 80,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _flipCamera,
              child: const Icon(Icons.cameraswitch),
            ),
          ),
        ],
      ),
    );
  }
}