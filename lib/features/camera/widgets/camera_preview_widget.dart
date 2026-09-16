import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/camera_state.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final bool isInitialized;
  final CameraAspectRatio aspectRatioMode;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.isInitialized,
    this.aspectRatioMode = CameraAspectRatio.full,
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed live feed
              Center(
                child: AspectRatio(
                  aspectRatio: previewRatio,
                  child: CameraPreview(controller!),
                ),
              ),

              // Letterbox crop guide — dim bars outside the selected crop region
              if (aspectRatioMode != CameraAspectRatio.full)
                _CropGuideOverlay(
                  previewRatio: previewRatio,
                  cropRatio: aspectRatioMode.ratio!,
                  constraints: constraints,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Draws two semi-transparent black bars (top+bottom or left+right) to indicate
/// the crop boundary for the selected aspect ratio. Does not affect the saved image
/// format — that is handled by [cropToAspectRatio] at save time.
class _CropGuideOverlay extends StatelessWidget {
  final double previewRatio;
  final double cropRatio;
  final BoxConstraints constraints;

  const _CropGuideOverlay({
    required this.previewRatio,
    required this.cropRatio,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    // Size of the full preview inside the container
    double previewW, previewH;
    if (w / h > previewRatio) {
      previewH = h;
      previewW = h * previewRatio;
    } else {
      previewW = w;
      previewH = w / previewRatio;
    }

    // Size of the crop window inside the preview
    double cropW, cropH;
    if (previewW / previewH > cropRatio) {
      cropH = previewH;
      cropW = previewH * cropRatio;
    } else {
      cropW = previewW;
      cropH = previewW / cropRatio;
    }

    final barColor = Colors.black.withValues(alpha: 0.55);
    final hBar = (previewH - cropH) / 2; // top & bottom bar height
    final vBar = (previewW - cropW) / 2; // left & right bar width

    // Horizontal bars (for tall crops like 9:16 or 4:5)
    if (hBar > 0) {
      final topOffset = (h - previewH) / 2;
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: topOffset,
            left: 0,
            right: 0,
            height: hBar,
            child: Container(color: barColor),
          ),
          Positioned(
            bottom: topOffset,
            left: 0,
            right: 0,
            height: hBar,
            child: Container(color: barColor),
          ),
        ],
      );
    }

    // Vertical bars (for wide crops — e.g. 1:1 from a very tall sensor)
    if (vBar > 0) {
      final leftOffset = (w - previewW) / 2;
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: leftOffset,
            width: vBar,
            child: Container(color: barColor),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: leftOffset,
            width: vBar,
            child: Container(color: barColor),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
