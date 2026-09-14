import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final bool isInitialized;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.isInitialized,
  });

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                size: 48,
                color: Colors.white38,
              ),
              SizedBox(height: 12),
              Text(
                'Camera Initializing...',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // CameraPreview in Flutter Camera plugin
    return LayoutBuilder(
      builder: (context, constraints) {
        final cameraAspectRatio = controller!.value.aspectRatio;

        // In portrait mode, camera preview aspect ratio is inverted (height / width)
        final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
        final previewRatio = isPortrait ? (1 / cameraAspectRatio) : cameraAspectRatio;

        return ClipRect(
          child: Center(
            child: AspectRatio(
              aspectRatio: previewRatio,
              child: CameraPreview(controller!),
            ),
          ),
        );
      },
    );
  }
}
