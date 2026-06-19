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
import 'services/socket_service.dart';

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

  // ── camera ──────────────────────────────────────────────
  CameraController? controller;
  List<CameraDescription> _allCameras = [];
  int _currentCameraIndex = 0;         // tracks which camera is active

  // ── state flags ─────────────────────────────────────────
  bool isStreaming     = false;
  bool processingFrame = false;
  bool isPaused        = false;
  bool isDisposed      = false;
  bool _isFlipping     = false;        // prevents double-tap during flip

  // ── timer ───────────────────────────────────────────────
  Timer? timer;
  int   seconds = 0;

  // ── frame throttle ──────────────────────────────────────
  DateTime lastFrameSent = DateTime.now();

  // ── live detection log ──────────────────────────────────
  StreamSubscription? _frameResultSub;

  bool    _drowsy   = false;
  bool    _yawn     = false;
  bool    _phone    = false;
  bool    _seatbelt = true;
  String? _lastEvent;

  final List<Map<String, dynamic>> _logRows          = [];
  final ScrollController           _logScrollController = ScrollController();
  static const int                 _maxLogRows        = 100;

  bool _showLog = false;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    AlertListenerService.start(context);
    _subscribeToFrameResults();
    initializeCamera();
  }

  // =====================================================
  // FRAME RESULT SUBSCRIPTION
  // =====================================================

  void _subscribeToFrameResults() {
    _frameResultSub = SocketService.frameResultStream.listen((data) {
      if (!mounted) return;

      setState(() {
        _drowsy    = data["drowsy"]   == true;
        _yawn      = data["yawn"]     == true;
        _phone     = data["phone"]    == true;
        _seatbelt  = data["seatbelt"] != false;
        _lastEvent = data["event_type"] as String?;

        _logRows.add({
          "time":       data["timestamp"] ?? _nowTime(),
          "event_type": _lastEvent,
          "drowsy":     _drowsy,
          "yawn":       _yawn,
          "phone":      _phone,
          "seatbelt":   _seatbelt,
          "confidence": data["confidence"] ?? 0.0,
        });

        if (_logRows.length > _maxLogRows) _logRows.removeAt(0);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  String _nowTime() {
    final n = DateTime.now();
    return "${n.hour.toString().padLeft(2, '0')}:"
        "${n.minute.toString().padLeft(2, '0')}:"
        "${n.second.toString().padLeft(2, '0')}";
  }

  // =====================================================
  // CAMERA INIT
  // =====================================================

  Future<void> initializeCamera() async {
    try {
      _allCameras = await availableCameras();

      // Default to front camera
      _currentCameraIndex = _allCameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      await _startCamera(_allCameras[_currentCameraIndex]);
    } catch (e) {
      debugPrint("CAMERA INIT ERROR: $e");
    }
  }

  // =====================================================
  // START / SWAP CAMERA
  //
  // Fix for "black screen on flip":
  //   1. The OLD controller is now stopped + disposed BEFORE the
  //      new controller is assigned to `controller` / before setState.
  //      Previously the old controller was disposed AFTER the swap,
  //      which meant two CameraController instances briefly held the
  //      camera hardware at once — on a lot of Android devices this
  //      silently breaks the new preview texture (no error, just a
  //      black surface).
  //   2. lockCaptureOrientation is now called AFTER the new
  //      controller has been mounted into the widget tree (with a
  //      short delay), instead of immediately after initialize().
  //      Locking orientation before the platform view exists can
  //      leave the preview without a valid first frame.
  // =====================================================

  Future<void> _startCamera(CameraDescription cameraDescription) async {
    final newController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await newController.initialize();

    if (!mounted) return;

    // Dispose the OLD controller BEFORE swapping in the new one.
    final old = controller;
    try {
      if (old != null) {
        if (old.value.isStreamingImages) {
          await old.stopImageStream();
        }
        await old.dispose();
      }
    } catch (e) {
      debugPrint("OLD CONTROLLER DISPOSE ERROR: $e");
    }

    if (!mounted) return;

    setState(() {
      controller  = newController;
      isStreaming = false;
    });

    // Give the new platform view a frame to mount before touching it.
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted || isDisposed) return;

    try {
      await newController.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );
    } catch (e) {
      debugPrint("ORIENTATION LOCK ERROR: $e");
    }

    await startStreaming();
  }

  // =====================================================
  // FLIP CAMERA
  // =====================================================

  Future<void> flipCamera() async {
    if (_isFlipping || _allCameras.length < 2) return;

    _isFlipping = true;

    try {
      // Stop current stream before switching
      if (controller != null &&
          controller!.value.isStreamingImages) {
        await controller!.stopImageStream();
      }

      _currentCameraIndex =
          (_currentCameraIndex + 1) % _allCameras.length;

      isStreaming = false;

      await _startCamera(_allCameras[_currentCameraIndex]);
    } catch (e) {
      debugPrint("FLIP CAMERA ERROR: $e");
    }

    _isFlipping = false;
  }

  // =====================================================
  // TIMER
  // =====================================================

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || isPaused) return;
      setState(() => seconds++);
    });
  }

  String get formattedTime {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // =====================================================
  // YUV420 -> RGB
  // =====================================================

  img.Image convertYUV420(CameraImage image) {
    final width  = image.width;
    final height = image.height;

    final yBuffer       = image.planes[0].bytes;
    final uBuffer       = image.planes[1].bytes;
    final vBuffer       = image.planes[2].bytes;
    final yRowStride    = image.planes[0].bytesPerRow;
    final uvRowStride   = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final rgbImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      final yRow  = yRowStride * y;
      final uvRow = uvRowStride * (y >> 1);

      for (int x = 0; x < width; x++) {
        final uvOffset = uvRow + (x >> 1) * uvPixelStride;

        final yp = yBuffer[yRow + x];
        final up = uBuffer[uvOffset];
        final vp = vBuffer[uvOffset];

        int r = (yp + vp * 1436 / 1024 - 179).round();
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round();
        int b = (yp + up * 1814 / 1024 - 227).round();

        rgbImage.setPixelRgb(
          x, y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        );
      }
    }

    return rgbImage;
  }

  // =====================================================
  // STREAMING
  // =====================================================

  Future<void> startStreaming() async {
    if (controller == null || !controller!.value.isInitialized) return;
    if (isStreaming) return;

    isStreaming = true;
    startTimer();

    await controller!.startImageStream((CameraImage image) async {
      if (!mounted || isDisposed || isPaused || processingFrame) return;

      final now = DateTime.now();
      if (now.difference(lastFrameSent).inMilliseconds < 300) return;

      lastFrameSent   = now;
      processingFrame = true;

      try {
        img.Image converted = convertYUV420(image);
        converted = img.copyRotate(converted, angle: -90);
        converted = img.flipHorizontal(converted);
        converted = img.copyResize(converted, width: 640);

        final jpg = img.encodeJpg(converted, quality: 95);

        await ApiService.sendFrame(
          driverId:    widget.driverId,
          imageBase64: base64Encode(jpg),
        );
      } catch (e) {
        debugPrint("STREAM ERROR: $e");
      }

      processingFrame = false;
    });
  }

  // =====================================================
  // PAUSE / STOP
  // =====================================================

  void togglePause() {
    setState(() => isPaused = !isPaused);
  }

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
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    AlertListenerService.stop();
    _frameResultSub?.cancel();
    _logScrollController.dispose();

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
  // HELPERS — status chips
  // =====================================================

  Color _statusColor(bool active, {bool isWarning = false}) {
    if (!active) return Colors.green;
    return isWarning ? Colors.orange : Colors.red;
  }

  Widget _statusChip(String label, bool active, {bool isWarning = false}) {
    final color = _statusColor(active, isWarning: isWarning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.15),
        border:       Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color:      color,
              fontSize:   11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── single log row ────────────────────────────────────
  Widget _buildLogRow(Map<String, dynamic> row) {
    final event    = row["event_type"] as String?;
    final hasEvent = event != null && event.isNotEmpty;

    Color rowColor = Colors.transparent;
    if (hasEvent) {
      rowColor = event == "Yawning"
          ? Colors.orange.withOpacity(0.08)
          : Colors.red.withOpacity(0.08);
    }

    return Container(
      color:   rowColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              row["time"] as String,
              style: const TextStyle(
                color:      Colors.white38,
                fontSize:   10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: hasEvent
                  ? (event == "Yawning"
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2))
                  : Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              hasEvent ? event! : "clear",
              style: TextStyle(
                color: hasEvent
                    ? (event == "Yawning" ? Colors.orange : Colors.red)
                    : Colors.white38,
                fontSize:   10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 4,
              children: [
                if (row["drowsy"] == true)    _miniFlag("drowsy",    Colors.red),
                if (row["yawn"]   == true)    _miniFlag("yawn",      Colors.orange),
                if (row["phone"]  == true)    _miniFlag("phone",     Colors.red),
                if (row["seatbelt"] == false) _miniFlag("no belt",   Colors.red),
                if (row["drowsy"]   != true &&
                    row["yawn"]     != true &&
                    row["phone"]    != true &&
                    row["seatbelt"] != false)
                  _miniFlag("all clear", Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniFlag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border:       Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9)),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

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

          // ── camera preview ────────────────────────────
          Positioned.fill(
            child: CameraPreview(controller!),
          ),

          // ── timer (top left) ──────────────────────────
          Positioned(
            top:  50,
            left: 20,
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record,
                    color: Colors.red, size: 30),
                const SizedBox(width: 10),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── detection status chips (top right) ────────
          Positioned(
            top:   50,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusChip("Drowsy",  _drowsy, isWarning: false),
                const SizedBox(height: 5),
                _statusChip("Yawning", _yawn,   isWarning: true),
                const SizedBox(height: 5),
                _statusChip("Phone",   _phone,  isWarning: false),
                const SizedBox(height: 5),
                _statusChip(
                  _seatbelt ? "Seatbelt ✓" : "No Seatbelt",
                  !_seatbelt,
                  isWarning: false,
                ),
              ],
            ),
          ),

          // ── live log panel (toggleable) ───────────────
          if (_showLog)
            Positioned(
              bottom: 110,
              left:   10,
              right:  10,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color:        Colors.black.withOpacity(0.80),
                  border:       Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.white12)),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "Live detection log",
                            style: TextStyle(
                              color:      Colors.white70,
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _logRows.clear()),
                            child: const Text(
                              "Clear",
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // rows
                    Expanded(
                      child: _logRows.isEmpty
                          ? const Center(
                        child: Text(
                          "Waiting for first frame…",
                          style: TextStyle(
                              color: Colors.white30, fontSize: 12),
                        ),
                      )
                          : ListView.separated(
                        controller:      _logScrollController,
                        itemCount:       _logRows.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1, color: Colors.white10,
                          thickness: 0.5,
                        ),
                        itemBuilder: (_, i) =>
                            _buildLogRow(_logRows[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── log toggle button ─────────────────────────
          Positioned(
            bottom: 105,
            left:   10,
            child: GestureDetector(
              onTap: () => setState(() => _showLog = !_showLog),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        Colors.black54,
                  border:       Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showLog
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.white54,
                      size:  16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showLog ? "Hide log" : "Show log",
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width:  7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── bottom action buttons ─────────────────────
          //    [ PAUSE ]   [ FLIP ]   [ STOP ]
          Positioned(
            bottom: 40,
            left:   0,
            right:  0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Pause / Resume
                FloatingActionButton(
                  heroTag:         "pause_btn",
                  backgroundColor: Colors.white,
                  onPressed:       togglePause,
                  child: Icon(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.green,
                    size:  32,
                  ),
                ),

                const SizedBox(width: 28),

                // Flip camera
                FloatingActionButton(
                  heroTag:         "flip_btn",
                  backgroundColor: Colors.white24,
                  onPressed:       _isFlipping ? null : flipCamera,
                  child: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size:  28,
                  ),
                ),

                const SizedBox(width: 28),

                // Stop
                FloatingActionButton(
                  heroTag:         "stop_btn",
                  backgroundColor: Colors.red,
                  onPressed:       stopSession,
                  child: const Icon(Icons.stop, size: 32),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}