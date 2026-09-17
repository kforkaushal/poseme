import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poseme/features/pose_library/models/pose_reference.dart';
import 'package:poseme/features/pose_library/providers/favorites_provider.dart';
import 'package:poseme/features/pose_library/providers/pose_library_provider.dart';
import 'package:poseme/features/pose_library/providers/shot_list_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial favorites map is empty and toggling adds/removes pose', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const pose = PoseReference(
        id: 'pose_test_1',
        name: 'Test Pose',
        category: PoseCategory.portrait,
      );

      final notifier = container.read(favoritesProvider.notifier);
      expect(container.read(favoritesProvider).isEmpty, true);
      expect(notifier.isFavorite(pose.id), false);

      // Toggle favorite -> added
      await notifier.toggleFavorite(pose);
      expect(container.read(favoritesProvider).containsKey(pose.id), true);
      expect(notifier.isFavorite(pose.id), true);
      expect(container.read(favoritesListProvider).length, 1);

      // Toggle favorite -> removed
      await notifier.toggleFavorite(pose);
      expect(container.read(favoritesProvider).containsKey(pose.id), false);
      expect(notifier.isFavorite(pose.id), false);
      expect(container.read(favoritesListProvider).isEmpty, true);
    });
  });

  group('Shot List & Camera Queue Tests', () {
    test('SelectedShotListNotifier toggles selection and clears correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const poseA = PoseReference(
        id: 'pose_a',
        name: 'Pose A',
        category: PoseCategory.fullBody,
      );
      const poseB = PoseReference(
        id: 'pose_b',
        name: 'Pose B',
        category: PoseCategory.couple,
      );

      final notifier = container.read(selectedShotListProvider.notifier);
      expect(container.read(selectedShotListProvider).isEmpty, true);

      notifier.togglePose(poseA);
      expect(container.read(selectedShotListProvider).length, 1);
      expect(notifier.isSelected(poseA.id), true);

      notifier.togglePose(poseB);
      expect(container.read(selectedShotListProvider).length, 2);

      notifier.togglePose(poseA);
      expect(container.read(selectedShotListProvider).length, 1);
      expect(notifier.isSelected(poseA.id), false);
      expect(notifier.isSelected(poseB.id), true);

      notifier.clear();
      expect(container.read(selectedShotListProvider).isEmpty, true);
    });

    test('CameraQueueNotifier manages queue session and active pose selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const pose1 = PoseReference(
        id: 'p1',
        name: 'Pose 1',
        category: PoseCategory.portrait,
      );
      const pose2 = PoseReference(
        id: 'p2',
        name: 'Pose 2',
        category: PoseCategory.studio,
      );

      final notifier = container.read(cameraQueueProvider.notifier);
      expect(container.read(cameraQueueProvider).isActive, false);
      expect(container.read(cameraQueueProvider).activePose, isNull);

      notifier.startQueue([pose1, pose2]);
      final state = container.read(cameraQueueProvider);
      expect(state.isActive, true);
      expect(state.poses.length, 2);
      expect(state.activeIndex, 0);
      expect(state.activePose?.id, 'p1');

      notifier.selectIndex(1);
      expect(container.read(cameraQueueProvider).activeIndex, 1);
      expect(container.read(cameraQueueProvider).activePose?.id, 'p2');

      notifier.clearQueue();
      expect(container.read(cameraQueueProvider).isActive, false);
      expect(container.read(cameraQueueProvider).activePose, isNull);
    });
  });

  group('Tag Query Composition Tests', () {
    test('buildPoseFilterQuery appends tags to category query', () {
      final queryPortrait = buildPoseFilterQuery(PoseCategory.portrait, {});
      expect(queryPortrait, PoseCategory.portrait.apiQuery);

      final queryWithTags =
          buildPoseFilterQuery(PoseCategory.portrait, {'standing', 'side'});
      expect(queryWithTags.contains(PoseCategory.portrait.apiQuery), true);
      expect(queryWithTags.contains('standing'), true);
      expect(queryWithTags.contains('side profile'), true);

      final queryAllWithTags =
          buildPoseFilterQuery(PoseCategory.all, {'close-up'});
      expect(queryAllWithTags.contains('fashion model pose photography'), true);
      expect(queryAllWithTags.contains('close up portrait'), true);
    });
  });
}
