import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class CameraRecordingScreen extends StatefulWidget {
  const CameraRecordingScreen({super.key});

  @override
  State<CameraRecordingScreen> createState() =>
      _CameraRecordingScreenState();
}

class _CameraRecordingScreenState
    extends State<CameraRecordingScreen> {

  CameraController? controller;

  bool isStreaming = false;

  bool isSendingFrame = false;

  Timer? frameTimer;

  static const String SERVER_URL =
      "http://192.168.1.64:8000/frame";

  @override
  void initState() {
    super.initState();

    initCamera();
  }

  // ================= CAMERA =================

  Future<void> initCamera() async {

    try {

      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
            (camera) =>
        camera.lensDirection ==
            CameraLensDirection.front,
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

      debugPrint("CAMERA INITIALIZED");

      startStreaming();

    } catch (e) {

      debugPrint("CAMERA INIT ERROR: $e");
    }
  }

  // ================= STREAM =================

  Future<void> startStreaming() async {

    if (controller == null) return;

    if (isStreaming) return;

    isStreaming = true;

    debugPrint("STREAM STARTED");

    await controller!.startImageStream(

          (CameraImage image) async {

        if (isSendingFrame) return;

        isSendingFrame = true;

        try {

          debugPrint("FRAME RECEIVED");

          Uint8List? jpegBytes =
          convertYUV420ToJpeg(image);

          if (jpegBytes == null) {

            debugPrint("JPEG CONVERSION FAILED");

            isSendingFrame = false;

            return;
          }

          String base64Image =
          base64Encode(jpegBytes);

          await sendFrame(base64Image);

        } catch (e) {

          debugPrint("STREAM ERROR: $e");

        } finally {

          isSendingFrame = false;
        }
      },
    );
  }

  // ================= SEND FRAME =================

  Future<void> sendFrame(String base64Image) async {

    try {

      final response = await http.post(

        Uri.parse(SERVER_URL),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({

          "image": base64Image,

          "driver_id": 1,
        }),
      );

      debugPrint(
          "FRAME SENT => ${response.statusCode}");

      debugPrint(
          "SERVER RESPONSE => ${response.body}");

    } catch (e) {

      debugPrint("UPLOAD ERROR: $e");
    }
  }

  // ================= IMAGE CONVERSION =================

  Uint8List? convertYUV420ToJpeg(
      CameraImage image) {

    try {

      final int width = image.width;

      final int height = image.height;

      final img.Image rgbImage =
      img.Image(
        width: width,
        height: height,
      );

      final planeY = image.planes[0];

      final planeU = image.planes[1];

      final planeV = image.planes[2];

      final int uvRowStride =
          planeU.bytesPerRow;

      final int uvPixelStride =
          planeU.bytesPerPixel ?? 1;

      for (int y = 0; y < height; y++) {

        for (int x = 0; x < width; x++) {

          final int uvIndex =
              uvPixelStride * (x ~/ 2) +
                  uvRowStride * (y ~/ 2);

          final int index =
              y * width + x;

          final yp =
          planeY.bytes[index];

          final up =
          planeU.bytes[uvIndex];

          final vp =
          planeV.bytes[uvIndex];

          int r =
          (yp + vp * 1436 / 1024 - 179)
              .round();

          int g =
          (yp -
              up * 46549 / 131072 +
              44 -
              vp * 93604 / 131072 +
              91)
              .round();

          int b =
          (yp + up * 1814 / 1024 - 227)
              .round();

          r = r.clamp(0, 255);

          g = g.clamp(0, 255);

          b = b.clamp(0, 255);

          rgbImage.setPixelRgb(
              x,
              y,
              r,
              g,
              b
          );
        }
      }

      return Uint8List.fromList(

        img.encodeJpg(
          rgbImage,
          quality: 40,
        ),
      );

    } catch (e) {

      debugPrint(
          "IMAGE CONVERSION ERROR: $e");

      return null;
    }
  }

  // ================= STOP STREAM =================

  Future<void> stopStreaming() async {

    try {

      if (controller != null &&
          controller!.value.isStreamingImages) {

        await controller!.stopImageStream();

        debugPrint("STREAM STOPPED");
      }

    } catch (e) {

      debugPrint("STOP STREAM ERROR: $e");
    }
  }

  // ================= DISPOSE =================

  @override
  void dispose() {

    stopStreaming();

    controller?.dispose();

    super.dispose();
  }

  // ================= UI =================

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

          SizedBox.expand(
            child: CameraPreview(controller!),
          ),

          Positioned(

            top: 40,

            left: 20,

            child: IconButton(

              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30,
              ),

              onPressed: () async {

                await stopStreaming();

                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ),

          Positioned(

            bottom: 40,

            left: 0,

            right: 0,

            child: const Center(

              child: Text(

                "AI STREAMING ACTIVE",

                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
