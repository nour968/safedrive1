import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'Home_Screen.dart';
import 'services/api_service.dart';
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

class _CameraRecordingScreenState
    extends State<CameraRecordingScreen> {

  CameraController? controller;

  bool isStreaming = false;

  bool isPaused = false;

  bool processingFrame = false;

  bool isDisposed = false;

  Timer? timer;

  int seconds = 0;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    // 🚨 START LIVE ALERT LISTENER
    AlertListenerService.start(context);

    initializeCamera();
  }

  // =====================================================
  // INITIALIZE CAMERA
  // =====================================================

  Future<void> initializeCamera() async {

    try {

      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
            (camera) =>
        camera.lensDirection ==
            CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {});

      await startStreaming();

    } catch (e) {

      debugPrint("CAMERA INIT ERROR: $e");
    }
  }

  // =====================================================
  // TIMER
  // =====================================================

  void startTimer() {

    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {

        if (!mounted) return;

        if (isPaused) return;

        setState(() {
          seconds++;
        });
      },
    );
  }

  String get formattedTime {

    int minutes = seconds ~/ 60;

    int remainingSeconds = seconds % 60;

    return
      "${minutes.toString().padLeft(2, '0')}:"
          "${remainingSeconds.toString().padLeft(2, '0')}";
  }

  // =====================================================
  // YUV420 -> RGB
  // =====================================================

  img.Image convertYUV420ToImage(CameraImage image) {

    final int width = image.width;
    final int height = image.height;

    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final img.Image rgbImage = img.Image(
      width: width,
      height: height,
    );

    for (int y = 0; y < height; y++) {

      final int uvRow = uvRowStride * (y >> 1);

      for (int x = 0; x < width; x++) {

        final int uvIndex =
            uvRow + (x >> 1) * uvPixelStride;

        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];

        final up = image.planes[1].bytes[uvIndex];

        final vp = image.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round();

        int g = (
            yp -
                up * 46549 / 131072 +
                44 -
                vp * 93604 / 131072 +
                91
        ).round();

        int b = (yp + up * 1814 / 1024 - 227).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return rgbImage;
  }

  // =====================================================
  // START STREAM
  // =====================================================

  Future<void> startStreaming() async {

    if (controller == null) return;

    if (isStreaming) return;

    if (!controller!.value.isInitialized) return;

    isStreaming = true;

    startTimer();

    await controller!.startImageStream(

          (CameraImage image) async {

        if (!mounted) return;

        if (isDisposed) return;

        if (processingFrame) return;

        if (isPaused) return;

        processingFrame = true;

        try {

          final convertedImage =
          convertYUV420ToImage(image);

          final rotatedImage = img.copyRotate(
            convertedImage,
            angle: 270,
          );

          final fixedImage = img.flipHorizontal(
            rotatedImage,
          );

          final jpg = img.encodeJpg(
            fixedImage,
            quality: 70,
          );

          final base64Image = base64Encode(jpg);

          await ApiService.sendFrame(

            driverId: widget.driverId,

            imageBase64: base64Image,
          );

        } catch (e) {

          debugPrint(
            "STREAM ERROR: $e",
          );
        }

        processingFrame = false;
      },
    );
  }

  // =====================================================
  // PAUSE
  // =====================================================

  void togglePause() {

    setState(() {

      isPaused = !isPaused;
    });
  }

  // =====================================================
  // STOP SESSION
  // =====================================================

  Future<void> stopSession() async {

    if (isDisposed) return;

    isDisposed = true;

    timer?.cancel();

    try {

      if (controller != null) {

        if (controller!.value.isStreamingImages) {

          await controller!.stopImageStream();
        }

        await controller!.dispose();
      }

    } catch (e) {

      debugPrint("STOP ERROR: $e");
    }

    if (!mounted) return;

    Navigator.pushReplacement(

      context,

      MaterialPageRoute(

        builder: (_) => const HomeScreen(),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    AlertListenerService.stop();

    isDisposed = true;

    timer?.cancel();

    try {
      if (controller != null) {
        if (controller!.value.isStreamingImages) {
          controller!.stopImageStream();
        }

        controller!.dispose();
      }
    } catch (_) {}

    super.dispose();
  }
  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {

    if (controller == null ||
        !controller!.value.isInitialized) {

      return const Scaffold(

        backgroundColor: Colors.black,

        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      backgroundColor: Colors.black,

      body: Stack(

        children: [

          Positioned.fill(

            child: CameraPreview(
              controller!,
            ),
          ),

          Positioned(

            top: 50,
            left: 20,

            child: Row(

              children: [

                const Icon(
                  Icons.fiber_manual_record,
                  color: Colors.red,
                ),

                const SizedBox(width: 10),

                Text(

                  formattedTime,

                  style: const TextStyle(

                    color: Colors.white,

                    fontSize: 20,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Positioned(

            bottom: 40,
            left: 60,

            child: FloatingActionButton(

              heroTag: "pause_btn",

              backgroundColor: Colors.white,

              onPressed: togglePause,

              child: Icon(

                isPaused
                    ? Icons.play_arrow
                    : Icons.pause,

                color: Colors.green,
              ),
            ),
          ),

          Positioned(

            bottom: 40,
            right: 60,

            child: FloatingActionButton(

              heroTag: "stop_btn",

              backgroundColor: Colors.red,

              onPressed: stopSession,

              child: const Icon(
                Icons.stop,
              ),
            ),
          ),
        ],
      ),
    );
  }
}