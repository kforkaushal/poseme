import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/main_navigation_screen.dart';
import '../../app/theme.dart';
import '../settings/providers/settings_provider.dart';
import '../settings/settings_screen.dart';
import 'providers/camera_provider.dart';
import 'widgets/camera_controls.dart';
import 'widgets/camera_crosshair.dart';
import 'widgets/camera_grid_lines.dart';
import 'widgets/camera_permission_view.dart';
import 'widgets/camera_preview_widget.dart';
import 'widgets/opacity_slider.dart';
import 'widgets/overlay_layer.dart';
import 'widgets/camera_quick_menu.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);
    final cameraNotifier = ref.read(cameraProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;

    // If permission denied or no cameras available
    if (!cameraState.hasPermission || !cameraState.hasCameras) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Pose Me'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.crop_free_rounded),
              tooltip: 'Browse Poses',
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).state = 0;
              },
            ),
            IconButton(
              icon: const Icon(Icons.photo_outlined),
              tooltip: 'Gallery',
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).state = 2;
              },
            ),
          ],
        ),
        body: CameraPermissionView(
          isPermanentlyDenied: cameraState.isPermanentlyDenied,
          errorMessage: cameraState.errorMessage,
          noCameras: !cameraState.hasCameras && cameraState.hasPermission,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Touching viewfinder wakes up the opacity slider and quick menu for 2 seconds
          ref.read(opacitySliderVisibilityProvider.notifier).show();
          ref.read(quickMenuVisibilityProvider.notifier).show();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Live Camera Preview (Full-bleed edge-to-edge)
            CameraPreviewWidget(
              controller: cameraNotifier.controller,
              isInitialized: cameraState.isInitialized,
              aspectRatioMode: cameraState.aspectRatioMode,
            ),

            // 2. Rule of Thirds Grid Lines (if enabled)
            if (settings.showGridLines) const CameraGridLines(),

            // 2b. Center Crosshair (if enabled)
            if (settings.showCrosshair) const CameraCrosshair(),

            // 3. Grayscale Pose Overlay Layer
            const OverlayLayer(),

            // 4. Slim Opacity Slider (auto-collapses after 2s)
            const Positioned(
              bottom: 156,
              left: 0,
              right: 0,
              child: OpacitySlider(),
            ),

            // 5. Camera Controls (Top & Bottom Bars)
            const CameraControls(),
          ],
        ),
      ),
    );
  }
}
