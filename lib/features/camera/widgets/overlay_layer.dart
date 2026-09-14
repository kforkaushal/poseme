import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../providers/overlay_provider.dart';

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
    if (pose != null && !pose.isNetworkImage) {
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
    if (!pose.isNetworkImage) {
      precacheImage(AssetImage(pose.assetPath), context);
    }

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
          // Ghosted Pose Image with Interactive Transform (Enforced Grayscale)
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
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.matrix(AppTheme.grayscaleMatrix),
                  child: pose.isNetworkImage
                      ? CachedNetworkImage(
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
                        )
                      : Image.asset(
                          pose.assetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                        ),
                ),
              ),
            ),
          ),

          // Active Pose Tag at top (Disciplined B&W, 4dp radius)
          if (overlayState.isControlsVisible)
            Positioned(
              top: 56,
              left: 16,
              right: 16,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.controlSurface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pose.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              ref.read(overlayProvider.notifier).clearPose();
                            },
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Photographer attribution (Pexels images only)
                    if (pose.isNetworkImage && pose.photographer != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Photo: ${pose.photographer} / Pexels',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
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
