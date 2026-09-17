import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../providers/overlay_provider.dart';
import 'sketch_overlay.dart';

class OverlayLayer extends ConsumerStatefulWidget {
  const OverlayLayer({super.key});

  @override
  ConsumerState<OverlayLayer> createState() => _OverlayLayerState();
}

class _OverlayLayerState extends ConsumerState<OverlayLayer> {
  Offset _startFocalPoint = Offset.zero;
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;
  double _startRotation = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pose = ref.read(overlayProvider).selectedPose;
    if (pose != null &&
        !pose.isNetworkImage &&
        !pose.isLocalImage &&
        pose.assetPath.isNotEmpty) {
      precacheImage(AssetImage(pose.assetPath), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayState = ref.watch(overlayProvider);
    final pose = overlayState.selectedPose;

    if (pose == null) {
      return const SizedBox.shrink();
    }

    // Precache asset images when pose changes
    if (!pose.isNetworkImage &&
        !pose.isLocalImage &&
        pose.assetPath.isNotEmpty) {
      precacheImage(AssetImage(pose.assetPath), context);
    }

    // Build raw image widget
    Widget rawImage;
    if (pose.isLocalImage && pose.localFilePath != null) {
      rawImage = Image.file(
        File(pose.localFilePath!),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    } else if (pose.isNetworkImage) {
      rawImage = CachedNetworkImage(
        imageUrl: pose.networkOverlayUrl!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        placeholder: (context, url) => const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white38,
            ),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white38,
          size: 48,
        ),
      );
    } else {
      rawImage = Image.asset(
        pose.assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      );
    }

    // Select visual display based on mode: artistic sketch or grayscale photo
    final imageDisplay = overlayState.overlayMode == OverlayMode.sketch
        ? SketchOverlay(pose: pose)
        : (pose.skipGrayscale
            ? rawImage
            : ColorFiltered(
                colorFilter: const ColorFilter.matrix(AppTheme.grayscaleMatrix),
                child: rawImage,
              ));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (details) {
        _startFocalPoint = details.focalPoint;
        _startOffset = overlayState.offset;
        _startScale = overlayState.scale;
        _startRotation = overlayState.rotation;
      },
      onScaleUpdate: (details) {
        final delta = details.focalPoint - _startFocalPoint;
        final newOffset = _startOffset + delta;
        final newScale = _startScale * details.scale;
        final newRotation = _startRotation + details.rotation;

        ref.read(overlayProvider.notifier).updateTransform(
              offset: newOffset,
              scale: newScale,
              rotation: newRotation,
            );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ghosted Pose Image or Sketch with Interactive Transform
          Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translateByDouble(
                  overlayState.offset.dx,
                  overlayState.offset.dy,
                  0.0,
                  1.0,
                )
                ..rotateZ(overlayState.rotation)
                ..scaleByDouble(
                  overlayState.isMirrored
                      ? -overlayState.scale
                      : overlayState.scale,
                  overlayState.scale,
                  1.0,
                  1.0,
                ),
              child: Opacity(
                opacity: overlayState.opacity,
                child: imageDisplay,
              ),
            ),
          ),


          // Transform reset & mirror quick buttons (4dp radius)
          if (overlayState.isControlsVisible &&
              (overlayState.offset != Offset.zero ||
                  overlayState.scale != 1.0 ||
                  overlayState.rotation != 0.0 ||
                  overlayState.isMirrored))
            Positioned(
              top: 96,
              right: 16,
              child: Column(
                children: [
                  _QuickToolButton(
                    icon: Icons.restart_alt_rounded,
                    tooltip: 'Reset Pose Position',
                    onTap: () {
                      ref.read(overlayProvider.notifier).resetTransform();
                    },
                  ),
                  const SizedBox(height: 6),
                  _QuickToolButton(
                    icon: Icons.flip,
                    tooltip: 'Flip Mirror',
                    isSelected: overlayState.isMirrored,
                    onTap: () {
                      ref.read(overlayProvider.notifier).toggleMirror();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isSelected;

  const _QuickToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : AppTheme.controlSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
