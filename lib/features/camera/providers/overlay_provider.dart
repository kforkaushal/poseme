import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pose_library/models/pose_reference.dart';

/// Which visual style to render as the camera overlay.
enum OverlayMode {
  /// Translucent grayscale photo of the pose.
  photo,

  /// Artistic white-on-transparent line sketch capturing posture and contours.
  sketch,
}

class OverlayState {
  final PoseReference? selectedPose;
  final double opacity;
  final Offset offset;
  final double scale;
  final double rotation;
  final bool isMirrored;
  final bool isUserMirrorOverridden;
  final bool burnInOverlay;
  final bool isControlsVisible;

  /// Which visual mode is active (photo or sketch).
  final OverlayMode overlayMode;

  /// True while background processing is generating the sketch.
  final bool isProcessingSketch;

  /// True if sketch generation failed; UI should fall back to photo.
  final bool sketchFailed;

  const OverlayState({
    this.selectedPose,
    this.opacity = 0.40,
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isMirrored = false,
    this.isUserMirrorOverridden = false,
    this.burnInOverlay = false,
    this.isControlsVisible = true,
    this.overlayMode = OverlayMode.photo,
    this.isProcessingSketch = false,
    this.sketchFailed = false,
  });

  OverlayState copyWith({
    PoseReference? selectedPose,
    bool clearPose = false,
    double? opacity,
    Offset? offset,
    double? scale,
    double? rotation,
    bool? isMirrored,
    bool? isUserMirrorOverridden,
    bool? burnInOverlay,
    bool? isControlsVisible,
    OverlayMode? overlayMode,
    bool? isProcessingSketch,
    bool? sketchFailed,
  }) {
    return OverlayState(
      selectedPose: clearPose ? null : (selectedPose ?? this.selectedPose),
      opacity: opacity ?? this.opacity,
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isMirrored: isMirrored ?? this.isMirrored,
      isUserMirrorOverridden:
          isUserMirrorOverridden ?? this.isUserMirrorOverridden,
      burnInOverlay: burnInOverlay ?? this.burnInOverlay,
      isControlsVisible: isControlsVisible ?? this.isControlsVisible,
      overlayMode: overlayMode ?? this.overlayMode,
      isProcessingSketch: isProcessingSketch ?? this.isProcessingSketch,
      sketchFailed: sketchFailed ?? this.sketchFailed,
    );
  }
}

final overlayProvider =
    StateNotifierProvider<OverlayNotifier, OverlayState>((ref) {
  return OverlayNotifier();
});

class OverlayNotifier extends StateNotifier<OverlayState> {
  OverlayNotifier({PoseReference? initialPose})
      : super(OverlayState(selectedPose: initialPose));

  void selectPose(PoseReference? pose) {
    // Reset sketch state whenever the pose changes so the new pose
    // triggers fresh sketch loading if needed.
    state = state.copyWith(
      selectedPose: pose,
      clearPose: pose == null,
      overlayMode: OverlayMode.photo,
      isProcessingSketch: false,
      sketchFailed: false,
    );
  }

  /// Cycle between Photo and Sketch modes.
  void cycleOverlayMode() {
    final next = state.overlayMode == OverlayMode.photo
        ? OverlayMode.sketch
        : OverlayMode.photo;
    state = state.copyWith(
      overlayMode: next,
      isProcessingSketch: next == OverlayMode.sketch,
      sketchFailed: false,
    );
  }

  void setSketchProcessing(bool value) {
    state = state.copyWith(isProcessingSketch: value);
  }

  void setSketchFailed(bool value) {
    if (value) {
      // Auto-revert to photo mode on failure.
      state = state.copyWith(
        overlayMode: OverlayMode.photo,
        isProcessingSketch: false,
        sketchFailed: true,
      );
    } else {
      state = state.copyWith(sketchFailed: false);
    }
  }

  void setOpacity(double opacity) {
    state = state.copyWith(opacity: opacity.clamp(0.0, 1.0));
  }

  void updateTransform({
    required Offset offset,
    required double scale,
    required double rotation,
  }) {
    state = state.copyWith(
      offset: offset,
      scale: scale.clamp(0.2, 4.0),
      rotation: rotation,
    );
  }

  void resetTransform() {
    state = state.copyWith(
      offset: Offset.zero,
      scale: 1.0,
      rotation: 0.0,
    );
  }

  void toggleMirror() {
    state = state.copyWith(
      isMirrored: !state.isMirrored,
      isUserMirrorOverridden: true,
    );
  }

  /// Automatically matches front camera mirroring unless user manually overrode it
  void setAutoMirrorForCamera(bool isFront) {
    if (!state.isUserMirrorOverridden) {
      state = state.copyWith(isMirrored: isFront);
    }
  }

  void toggleBurnIn() {
    state = state.copyWith(burnInOverlay: !state.burnInOverlay);
  }

  void toggleControlsVisibility() {
    state = state.copyWith(isControlsVisible: !state.isControlsVisible);
  }

  void clearPose() {
    state = state.copyWith(clearPose: true);
  }
}
