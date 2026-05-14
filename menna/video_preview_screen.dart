import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;

  const VideoPreviewScreen(this.videoPath, {super.key});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        controller.play();
      });
  }

  @override
  void dispose() {
    controller.dispose(); // منع memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        )
            : const CircularProgressIndicator(),
      ),

      // Floating buttons row
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /// PLAY / PAUSE
          FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
            child: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),

          /// DELETE
          FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.delete),
          ),

          /// CONFIRM (back to first screen)
          FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Icon(Icons.check),
          ),
        ],
      ),
    );
  }
}