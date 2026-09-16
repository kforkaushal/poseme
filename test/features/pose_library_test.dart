import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poseme/features/pose_library/models/pexels_photo.dart';
import 'package:poseme/features/pose_library/models/pose_reference.dart';
import 'package:poseme/features/pose_library/providers/pose_library_provider.dart';

void main() {
  group('Pose Library Tests', () {
    test('PoseCategory enum has correct display names and API queries', () {
      expect(PoseCategory.all.displayName, 'All');
      expect(PoseCategory.all.apiQuery, '');
      expect(PoseCategory.portrait.displayName, 'Portrait');
      expect(PoseCategory.portrait.apiQuery, 'portrait pose photography');
      expect(PoseCategory.fullBody.displayName, 'Full Body');
      expect(PoseCategory.couple.displayName, 'Couple');
      expect(PoseCategory.outdoor.displayName, 'Outdoor');
      expect(PoseCategory.studio.displayName, 'Studio');
    });

    test('PoseCategory.fetchable excludes "all"', () {
      final fetchable = PoseCategory.fetchable;
      expect(fetchable.contains(PoseCategory.all), false);
      expect(fetchable.length, 5);
    });

    test('PexelsPhoto serializes and deserializes correctly', () {
      const photo = PexelsPhoto(
        id: 12345,
        thumbnailUrl: 'https://example.com/thumb.jpg',
        overlayUrl: 'https://example.com/portrait.jpg',
        photographer: 'Test Photographer',
      );

      final json = photo.toJson();
      expect(json['id'], 12345);
      expect(json['photographer'], 'Test Photographer');

      final decoded = PexelsPhoto.fromJson(json);
      expect(decoded.id, photo.id);
      expect(decoded.thumbnailUrl, photo.thumbnailUrl);
      expect(decoded.overlayUrl, photo.overlayUrl);
      expect(decoded.photographer, photo.photographer);
    });

    test('PexelsPhoto list encode/decode roundtrip works', () {
      const photos = [
        PexelsPhoto(
          id: 1,
          thumbnailUrl: 'https://example.com/1.jpg',
          overlayUrl: 'https://example.com/1p.jpg',
          photographer: 'Alice',
        ),
        PexelsPhoto(
          id: 2,
          thumbnailUrl: 'https://example.com/2.jpg',
          overlayUrl: 'https://example.com/2p.jpg',
          photographer: 'Bob',
        ),
      ];

      final encoded = PexelsPhoto.encodeList(photos);
      expect(encoded, isA<String>());

      final decoded = PexelsPhoto.decodeList(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].id, 1);
      expect(decoded[1].photographer, 'Bob');
    });

    test('PoseReference.fromPexels maps fields correctly', () {
      const photo = PexelsPhoto(
        id: 99,
        thumbnailUrl: 'https://example.com/thumb.jpg',
        overlayUrl: 'https://example.com/overlay.jpg',
        photographer: 'Jane Doe',
      );

      final pose = PoseReference.fromPexels(photo, PoseCategory.portrait);
      expect(pose.id, 'pexels_99');
      expect(pose.name, 'Jane Doe');
      expect(pose.category, PoseCategory.portrait);
      expect(pose.networkThumbnailUrl, photo.thumbnailUrl);
      expect(pose.networkOverlayUrl, photo.overlayUrl);
      expect(pose.photographer, 'Jane Doe');
      expect(pose.isNetworkImage, true);
    });

    test('PoseReference with only assetPath is not a network image', () {
      const pose = PoseReference(
        id: 'bundled_01',
        name: 'Test Pose',
        category: PoseCategory.portrait,
        assetPath: 'assets/poses/test.png',
      );

      expect(pose.isNetworkImage, false);
      expect(pose.networkOverlayUrl, null);
    });

    test('Selected category defaults to All', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final category = container.read(selectedPoseCategoryProvider);
      expect(category, PoseCategory.all);
    });

    test('Selected category can be changed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedPoseCategoryProvider.notifier).state =
          PoseCategory.studio;
      expect(
        container.read(selectedPoseCategoryProvider),
        PoseCategory.studio,
      );
    });

    test('PexelsPhoto fromJson handles Pexels API response format', () {
      final apiResponse = {
        'id': 55555,
        'photographer': 'Studio Pro',
        'width': 2000,
        'height': 3000,
        'src': {
          'medium': 'https://images.pexels.com/photos/55555/medium.jpg',
          'portrait': 'https://images.pexels.com/photos/55555/portrait.jpg',
          'large': 'https://images.pexels.com/photos/55555/large.jpg',
        },
      };

      final photo = PexelsPhoto.fromJson(apiResponse);
      expect(photo.id, 55555);
      expect(photo.photographer, 'Studio Pro');
      expect(photo.width, 2000);
      expect(photo.height, 3000);
      expect(photo.aspectRatio, closeTo(2 / 3, 0.01));
      expect(photo.thumbnailUrl, contains('medium'));
      expect(photo.overlayUrl, contains('portrait'));
    });

    test('PoseReference.fromGallery creates valid local pose reference', () {
      final galleryPose = PoseReference.fromGallery(
        filePath: '/data/user/0/com.example/test_picked.jpg',
        width: 1080,
        height: 1920,
      );

      expect(galleryPose.id, startsWith('gallery_'));
      expect(galleryPose.name, 'From Gallery');
      expect(galleryPose.localFilePath, '/data/user/0/com.example/test_picked.jpg');
      expect(galleryPose.isLocalImage, true);
      expect(galleryPose.isNetworkImage, false);
      expect(galleryPose.skipGrayscale, true);
      expect(galleryPose.aspectRatio, closeTo(1080 / 1920, 0.01));
    });

    test('PoseReference clamps aspect ratio within aesthetic limits', () {
      final widePose = PoseReference.fromGallery(
        filePath: '/test.jpg',
        width: 4000,
        height: 1000,
      );
      expect(widePose.aspectRatio, 1.4);

      final tallPose = PoseReference.fromGallery(
        filePath: '/test.jpg',
        width: 100,
        height: 4000,
      );
      expect(widePose.aspectRatio, 1.4);
      expect(tallPose.aspectRatio, 0.55);
    });
  });
}
