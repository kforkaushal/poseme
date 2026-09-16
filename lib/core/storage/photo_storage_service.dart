import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/gallery/models/captured_photo.dart';

final photoStorageServiceProvider = Provider<PhotoStorageService>((ref) {
  return PhotoStorageService();
});

class PhotoStorageService {
  static const String _photosStorageKey = 'poseme_captured_photos';

  /// Saves an XFile captured from camera to persistent app documents directory,
  /// exports it to the device photo library using Gal, and records its metadata.
  Future<CapturedPhoto> saveCapturedPhoto({
    required String tempPath,
    String? poseId,
    String? poseAssetPath,
    String? poseName,
    bool isFrontCamera = false,
    String? poseNetworkUrl,
    String? poseLocalFilePath,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'captured_poses'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = p.extension(tempPath).isNotEmpty ? p.extension(tempPath) : '.jpg';
    final permanentPath = p.join(photosDir.path, 'pose_$id$ext');

    // Copy the temporary image to permanent app documents
    final tempFile = File(tempPath);
    await tempFile.copy(permanentPath);

    // Try to save to the device's system photo gallery
    try {
      await Gal.putImage(permanentPath);
    } catch (_) {
      // If saving to system album fails (e.g. permission or desktop/emulator),
      // we still retain the in-app copy.
    }

    final photo = CapturedPhoto(
      id: id,
      filePath: permanentPath,
      createdAt: DateTime.now(),
      poseId: poseId,
      poseAssetPath: poseAssetPath,
      poseName: poseName,
      isFrontCamera: isFrontCamera,
      poseNetworkUrl: poseNetworkUrl,
      poseLocalFilePath: poseLocalFilePath,
    );

    await _persistPhotoMetadata(photo);
    return photo;
  }

  /// Loads all saved photos from local persistent storage.
  Future<List<CapturedPhoto>> loadSavedPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_photosStorageKey) ?? [];

    final photos = <CapturedPhoto>[];
    for (final jsonString in jsonList) {
      try {
        final photo = CapturedPhoto.fromJson(jsonString);
        // Only return photos whose file actually still exists on disk
        if (File(photo.filePath).existsSync()) {
          photos.add(photo);
        }
      } catch (_) {
        // Skip corrupted entries
      }
    }

    // Sort newest first
    photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return photos;
  }

  /// Deletes a photo from the in-app directory and updates local storage.
  /// (Does not delete from device system gallery, conforming to spec).
  Future<void> deletePhoto(String photoId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_photosStorageKey) ?? [];

    final updatedJsonList = <String>[];
    for (final jsonString in jsonList) {
      try {
        final photo = CapturedPhoto.fromJson(jsonString);
        if (photo.id == photoId) {
          // Delete file from disk
          final file = File(photo.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } else {
          updatedJsonList.add(jsonString);
        }
      } catch (_) {
        // Drop invalid
      }
    }

    await prefs.setStringList(_photosStorageKey, updatedJsonList);
  }

  Future<void> _persistPhotoMetadata(CapturedPhoto photo) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_photosStorageKey) ?? [];
    jsonList.insert(0, photo.toJson());
    await prefs.setStringList(_photosStorageKey, jsonList);
  }
}
