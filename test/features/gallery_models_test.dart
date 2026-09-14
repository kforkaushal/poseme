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
    });
  });
}
