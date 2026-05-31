import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool processingFrame = false;
  bool isPaused = false;
  bool isDisposed = false;

  Timer? timer;

  int seconds = 0;

  DateTime lastFrameSent = DateTime.now();

  Uint8List? debugFrame;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    AlertListenerService.start(context);

    initializeCamera();
  }

  // =====================================================
  // CAMERA INIT
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
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller!.initialize();

      await controller!.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      if (!mounted) return;

      setState(() {});

      await startStreaming();
    } catch (e) {
      debugPrint(
        "CAMERA INIT ERROR: $e",
      );
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
        if (!mounted || isPaused) return;

        setState(() {
          seconds++;
        });
      },
    );
  }

  String get formattedTime {
    final minutes = seconds ~/ 60;

    final sec = seconds % 60;

    return "${minutes.toString().padLeft(2, '0')}:"
        "${sec.toString().padLeft(2, '0')}";
  }

  // =====================================================
  // YUV420 -> RGB
  // =====================================================

  img.Image convertYUV420(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yBuffer = image.planes[0].bytes;
    final uBuffer = image.planes[1].bytes;
    final vBuffer = image.planes[2].bytes;

    final yRowStride =
        image.planes[0].bytesPerRow;

    final uvRowStride =
        image.planes[1].bytesPerRow;

    final uvPixelStride =
    image.planes[1].bytesPerPixel!;

    final rgbImage = img.Image(
      width: width,
      height: height,
    );

    for (int y = 0; y < height; y++) {
      final yRow = yRowStride * y;
      final uvRow = uvRowStride * (y >> 1);

      for (int x = 0; x < width; x++) {
        final uvOffset =
            uvRow +
                (x >> 1) * uvPixelStride;

        final yp = yBuffer[yRow + x];
        final up = uBuffer[uvOffset];
        final vp = vBuffer[uvOffset];

        int r =
        (yp + vp * 1436 / 1024 - 179)
            .round();

        int g =
        (yp -
            up *
                46549 /
                131072 +
            44 -
            vp *
                93604 /
                131072 +
            91)
            .round();

        int b =
        (yp + up * 1814 / 1024 - 227)
            .round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return rgbImage;
  }

  // =====================================================
  // STREAMING
  // =====================================================

  Future<void> startStreaming() async {
    if (controller == null) return;

    if (!controller!.value.isInitialized) {
      return;
    }

    if (isStreaming) return;

    isStreaming = true;

    startTimer();

    await controller!.startImageStream(
          (CameraImage image) async {
        if (!mounted) return;

        if (isDisposed) return;

        if (isPaused) return;

        if (processingFrame) return;

        // THROTTLE
        final now = DateTime.now();

        if (now
            .difference(lastFrameSent)
            .inMilliseconds <
            300) {
          return;
        }

        lastFrameSent = now;

        processingFrame = true;

        try {
          // =====================================
          // CONVERT CAMERA IMAGE
          // =====================================

          img.Image converted =
          convertYUV420(image);

          // =====================================
          // FIX ROTATION
          // =====================================

          converted = img.copyRotate(
            converted,
            angle: -90,
          );

          // =====================================
          // MIRROR FRONT CAMERA
          // =====================================

          converted = img.flipHorizontal(
            converted,
          );

          // =====================================
          // RESIZE
          // =====================================

          converted = img.copyResize(
            converted,
            width: 640,
          );

          // =====================================
          // JPG ENCODE
          // =====================================

          final jpg = img.encodeJpg(
            converted,
            quality: 95,
          );

          // =====================================
          // DEBUG AI FRAME
          // =====================================

          debugFrame = Uint8List.fromList(jpg);

          if (mounted) {
            setState(() {});
          }

          // =====================================
          // SEND TO BACKEND
          // =====================================

          final base64Image =
          base64Encode(jpg);

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
        if (controller!
            .value
            .isStreamingImages) {
          await controller!
              .stopImageStream();
        }

        await controller!.dispose();
      }
    } catch (e) {
      debugPrint(
        "STOP ERROR: $e",
      );
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const HomeScreen(),
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
        if (controller!
            .value
            .isStreamingImages) {
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
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          // =====================================
          // CAMERA PREVIEW
          // =====================================

          Positioned.fill(
            child: CameraPreview(
              controller!,
            ),
          ),

          // =====================================
          // AI FRAME
          // =====================================

          Positioned(
            top: 120,
            right: 20,
            child: Container(
              width: 170,
              height: 230,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red,
                  width: 3,
                ),
                color: Colors.black,
              ),
              child: debugFrame == null
                  ? const Center(
                child: Text(
                  "Loading...",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              )
                  : Image.memory(
                debugFrame!,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // =====================================
          // AI LABEL
          // =====================================

          Positioned(
            top: 85,
            right: 20,
            child: Container(
              color: Colors.red,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: const Text(
                "AI FRAME",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // =====================================
          // TIMER
          // =====================================

          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                const Icon(
                  Icons.fiber_manual_record,
                  color: Colors.red,
                  size: 30,
                ),

                const SizedBox(width: 10),

                Text(
                  formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // =====================================
          // PAUSE BUTTON
          // =====================================

          Positioned(
            bottom: 40,
            left: 60,
            child: FloatingActionButton(
              heroTag: "pause_btn",
              backgroundColor:
              Colors.white,
              onPressed: togglePause,
              child: Icon(
                isPaused
                    ? Icons.play_arrow
                    : Icons.pause,
                color: Colors.green,
                size: 32,
              ),
            ),
          ),

          // =====================================
          // STOP BUTTON
          // =====================================

          Positioned(
            bottom: 40,
            right: 60,
            child: FloatingActionButton(
              heroTag: "stop_btn",
              backgroundColor:
              Colors.red,
              onPressed: stopSession,
              child: const Icon(
                Icons.stop,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}