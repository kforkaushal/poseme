import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/permissions/permission_service.dart';
import '../providers/camera_provider.dart';

class CameraPermissionView extends ConsumerWidget {
  final bool isPermanentlyDenied;
  final String? errorMessage;
  final bool noCameras;

  const CameraPermissionView({
    super.key,
    required this.isPermanentlyDenied,
    this.errorMessage,
    this.noCameras = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final elevatedBg =
        isDark ? AppTheme.darkBgElevated : AppTheme.lightBgElevated;
    final borderColor =
        isDark ? AppTheme.darkBorderHairline : AppTheme.lightBorderHairline;

    final title = noCameras
        ? 'No Camera Detected'
        : (isPermanentlyDenied
            ? 'Camera Permission Required'
            : 'Enable Camera');

    final message = noCameras
        ? 'No physical camera was detected. You can still browse the pose library and saved photos.'
        : (errorMessage ??
            'Pose Me requires camera access to preview frames and overlay pose guides.');

    final icon =
        noCameras ? Icons.no_photography_outlined : Icons.camera_alt_outlined;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: elevatedBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                icon,
                size: 28,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (!noCameras)
              ElevatedButton(
                onPressed: () async {
                  if (isPermanentlyDenied) {
                    await ref.read(permissionServiceProvider).openSettings();
                  } else {
                    await ref.read(cameraProvider.notifier).initializeCamera();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  foregroundColor:
                      isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  isPermanentlyDenied ? 'Open Settings' : 'Enable Camera',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
