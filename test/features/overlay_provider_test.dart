import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poseme/features/camera/providers/overlay_provider.dart';
import 'package:poseme/features/pose_library/models/pose_reference.dart';

void main() {
  group('OverlayProvider Tests', () {
    test('Initial state has default values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(overlayProvider);
      expect(state.opacity, 0.40);
      expect(state.scale, 1.0);
      expect(state.offset, Offset.zero);
      expect(state.rotation, 0.0);
      expect(state.isMirrored, false);
      expect(state.burnInOverlay, false);
      expect(state.selectedPose, isNull);
    });

    test('Updating opacity clamps value correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(overlayProvider.notifier);

      notifier.setOpacity(0.75);
      expect(container.read(overlayProvider).opacity, 0.75);

      // Clamps above 1.0
      notifier.setOpacity(1.5);
      expect(container.read(overlayProvider).opacity, 1.0);

      // Clamps below 0.0
      notifier.setOpacity(-0.2);
      expect(container.read(overlayProvider).opacity, 0.0);
    });

    test('Updating transform modifies offset, scale, and rotation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(overlayProvider.notifier);

      notifier.updateTransform(
        offset: const Offset(50, 100),
        scale: 1.5,
        rotation: 0.25,
      );

      final state = container.read(overlayProvider);
      expect(state.offset, const Offset(50, 100));
      expect(state.scale, 1.5);
      expect(state.rotation, 0.25);

      // Reset transform restores defaults
      notifier.resetTransform();
      final resetState = container.read(overlayProvider);
      expect(resetState.offset, Offset.zero);
      expect(resetState.scale, 1.0);
      expect(resetState.rotation, 0.0);
    });

    test('Auto-mirroring activates for front camera unless user overrides', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(overlayProvider.notifier);

      // Front camera sets mirror
      notifier.setAutoMirrorForCamera(true);
      expect(container.read(overlayProvider).isMirrored, true);

      // Back camera disables mirror
      notifier.setAutoMirrorForCamera(false);
      expect(container.read(overlayProvider).isMirrored, false);

      // User manual override prevents automatic change
      notifier.toggleMirror();
      expect(container.read(overlayProvider).isMirrored, true);

      notifier.setAutoMirrorForCamera(false);
      expect(container.read(overlayProvider).isMirrored, true); // Still true due to override
    });

    test('Selecting and clearing pose works', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(overlayProvider.notifier);

      notifier.clearPose();
      expect(container.read(overlayProvider).selectedPose, isNull);

      const customPose = PoseReference(
        id: 'test_pose',
        name: 'Test Pose',
        category: PoseCategory.portrait,
        assetPath: 'assets/poses/portrait_01.png',
        description: 'Test description',
      );

      notifier.selectPose(customPose);
      expect(container.read(overlayProvider).selectedPose?.id, 'test_pose');
    });
  });
}
