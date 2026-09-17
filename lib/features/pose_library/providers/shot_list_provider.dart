import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pose_reference.dart';

/// Tracks whether Home grid is in multi-selection mode.
final isSelectionModeProvider = StateProvider<bool>((ref) => false);

/// StateNotifier that manages selected poses while in selection mode on Home screen.
class SelectedShotListNotifier extends StateNotifier<List<PoseReference>> {
  SelectedShotListNotifier() : super([]);

  void togglePose(PoseReference pose) {
    if (state.any((p) => p.id == pose.id)) {
      state = state.where((p) => p.id != pose.id).toList();
    } else {
      state = [...state, pose];
    }
  }

  bool isSelected(String poseId) {
    return state.any((p) => p.id == poseId);
  }

  void clear() {
    state = [];
  }
}

final selectedShotListProvider =
    StateNotifierProvider<SelectedShotListNotifier, List<PoseReference>>((ref) {
  return SelectedShotListNotifier();
});

/// Immutable state for the active multi-pose camera session.
class CameraQueueState {
  final List<PoseReference> poses;
  final int activeIndex;

  const CameraQueueState({
    this.poses = const [],
    this.activeIndex = 0,
  });

  bool get isActive => poses.isNotEmpty;

  PoseReference? get activePose =>
      isActive && activeIndex >= 0 && activeIndex < poses.length
          ? poses[activeIndex]
          : null;

  CameraQueueState copyWith({
    List<PoseReference>? poses,
    int? activeIndex,
  }) {
    return CameraQueueState(
      poses: poses ?? this.poses,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }
}

/// Manages ephemeral queue of poses loaded into the camera viewfinder session.
class CameraQueueNotifier extends StateNotifier<CameraQueueState> {
  CameraQueueNotifier() : super(const CameraQueueState());

  void startQueue(List<PoseReference> poses) {
    if (poses.isEmpty) {
      state = const CameraQueueState();
    } else {
      state = CameraQueueState(
        poses: List.unmodifiable(poses),
        activeIndex: 0,
      );
    }
  }

  void selectIndex(int index) {
    if (!state.isActive) return;
    final clamped = index.clamp(0, state.poses.length - 1);
    state = state.copyWith(activeIndex: clamped);
  }

  void clearQueue() {
    state = const CameraQueueState();
  }
}

final cameraQueueProvider =
    StateNotifierProvider<CameraQueueNotifier, CameraQueueState>((ref) {
  return CameraQueueNotifier();
});
