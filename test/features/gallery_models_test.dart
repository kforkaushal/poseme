import 'package:flutter_test/flutter_test.dart';
import 'package:poseme/features/gallery/models/captured_photo.dart';

void main() {
  group('CapturedPhoto Model Tests', () {
    test('Serializes to and from Map correctly', () {
      final now = DateTime.now();
      final photo = CapturedPhoto(
        id: '123456',
        filePath: '/data/user/0/com.example.poseme/app_flutter/captured_poses/pose_123.jpg',
        createdAt: now,
        poseId: 'portrait_01',
        poseAssetPath: 'assets/poses/portrait_01.png',
        poseName: 'Classic Studio Portrait',
        isFrontCamera: true,
      );

      final map = photo.toMap();
      expect(map['id'], '123456');
      expect(map['poseId'], 'portrait_01');
      expect(map['isFrontCamera'], true);

      final fromMap = CapturedPhoto.fromMap(map);
      expect(fromMap.id, photo.id);
      expect(fromMap.filePath, photo.filePath);
      expect(fromMap.poseId, photo.poseId);
      expect(fromMap.poseAssetPath, photo.poseAssetPath);
      expect(fromMap.poseName, photo.poseName);
      expect(fromMap.isFrontCamera, photo.isFrontCamera);
      expect(fromMap.hasReferenceImage, true);
    });

    test('Serializes to and from Map with network and local pose references', () {
      final now = DateTime.now();
      final pexelsPhoto = CapturedPhoto(
        id: 'net_1',
        filePath: '/test/net.jpg',
        createdAt: now,
        poseNetworkUrl: 'https://images.pexels.com/photos/123/test.jpg',
        poseName: 'Pexels Model',
      );
      final pexelsRoundtrip = CapturedPhoto.fromMap(pexelsPhoto.toMap());
      expect(pexelsRoundtrip.poseNetworkUrl, 'https://images.pexels.com/photos/123/test.jpg');
      expect(pexelsRoundtrip.hasReferenceImage, true);

      final localPhoto = CapturedPhoto(
        id: 'local_1',
        filePath: '/test/loc.jpg',
        createdAt: now,
        poseLocalFilePath: '/storage/gallery/pose.jpg',
      );
      final localRoundtrip = CapturedPhoto.fromMap(localPhoto.toMap());
      expect(localRoundtrip.poseLocalFilePath, '/storage/gallery/pose.jpg');
      expect(localRoundtrip.hasReferenceImage, true);
    });

    test('Serializes to and from JSON string correctly', () {
      final now = DateTime.now();
      final photo = CapturedPhoto(
        id: '999',
        filePath: '/test/path.jpg',
        createdAt: now,
      );

      final jsonStr = photo.toJson();
      final fromJson = CapturedPhoto.fromJson(jsonStr);

      expect(fromJson.id, '999');
      expect(fromJson.filePath, '/test/path.jpg');
      expect(fromJson.poseId, isNull);
      expect(fromJson.isFrontCamera, false);
      expect(fromJson.hasReferenceImage, false);
    });
  });
}
