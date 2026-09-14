import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

class PermissionService {
  /// Checks whether camera permission is currently granted.
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Requests camera permission. Returns true if granted.
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Checks whether camera is permanently denied (requires opening settings).
  Future<bool> isCameraPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  /// Checks whether photo library access is granted for saving pictures.
  Future<bool> hasPhotoAccess() async {
    try {
      return await Gal.hasAccess(toAlbum: false);
    } catch (_) {
      // Fallback to permission_handler if Gal check encounters platform variation
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    }
  }

  /// Requests access to save to the photo gallery.
  Future<bool> requestPhotoAccess() async {
    try {
      return await Gal.requestAccess(toAlbum: false);
    } catch (_) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }
  }

  /// Opens the device app settings screen so the user can enable permissions.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
