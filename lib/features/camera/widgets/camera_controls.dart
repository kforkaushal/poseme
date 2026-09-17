import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/storage/image_crop_service.dart';
import '../../../core/storage/photo_storage_service.dart';
import '../../../core/utils/string_utils.dart';
import '../../gallery/gallery_screen.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../../pose_library/providers/shot_list_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/settings_screen.dart';
import '../providers/camera_provider.dart';
import '../providers/overlay_provider.dart';
import 'camera_pose_queue_strip.dart';
import 'camera_quick_menu.dart';

class CameraControls extends ConsumerStatefulWidget {
  const CameraControls({super.key});

  @override
  ConsumerState<CameraControls> createState() => _CameraControlsState();
}

class _CameraControlsState extends ConsumerState<CameraControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _shutterAnimController;
  bool _showShutterFlash = false;
  int? _countdownSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _shutterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shutterAnimController.dispose();
    super.dispose();
  }

  void _onShutterPressed() {
    final settings = ref.read(settingsProvider);

    if (_countdownSeconds != null) {
      // Tapping during countdown cancels it
      _cancelCountdown();
      return;
    }

    if (settings.timerSeconds > 0) {
      _startCountdown(settings.timerSeconds);
    } else {
      _executeCapture();
    }
  }

  void _startCountdown(int seconds) {
    setState(() => _countdownSeconds = seconds);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds! <= 1) {
        timer.cancel();
        setState(() => _countdownSeconds = null);
        _executeCapture();
      } else {
        setState(() => _countdownSeconds = _countdownSeconds! - 1);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = null);
  }

  Future<void> _executeCapture() async {
    final cameraNotifier = ref.read(cameraProvider.notifier);
    final overlayState = ref.read(overlayProvider);
    final cameraState = ref.read(cameraProvider);
    final settings = ref.read(settingsProvider);
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion = mediaQuery.disableAnimations;

    if (cameraState.isCapturing || !cameraState.isInitialized) return;

    if (!reduceMotion) {
      setState(() => _showShutterFlash = true);
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _showShutterFlash = false);
      });
      _shutterAnimController.reverse().then((_) {
        if (mounted) _shutterAnimController.forward();
      });
    }

    // Capture clean raw frame
    final xFile = await cameraNotifier.takePicture();
    if (xFile == null) return;

    // Process photo in background isolate: orientation, aspect ratio crop, and watermark
    final processedPath = await processCapturedPhoto(
      sourcePath: xFile.path,
      ratio: cameraState.aspectRatioMode,
      addWatermark: settings.addWatermark,
    );

    try {
      final storageService = ref.read(photoStorageServiceProvider);
      final savedPhoto = await storageService.saveCapturedPhoto(
        tempPath: processedPath,
        poseId: overlayState.selectedPose?.id,
        poseAssetPath: overlayState.selectedPose?.assetPath,
        poseName: overlayState.selectedPose?.name,
        isFrontCamera: cameraState.isFrontCamera,
        poseNetworkUrl: overlayState.selectedPose?.networkOverlayUrl,
        poseLocalFilePath: overlayState.selectedPose?.localFilePath,
      );

      ref.read(galleryPhotosProvider.notifier).addPhoto(savedPhoto);
    } catch (_) {
      // Handled silently to avoid interrupting shooting flow
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraProvider);
    final overlayState = ref.watch(overlayProvider);
    final queueState = ref.watch(cameraQueueProvider);
    final latestPhoto = ref.watch(latestCapturedPhotoProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shutterFill =
        isDark ? AppTheme.darkShutterFill : AppTheme.lightShutterFill;
    final shutterRing =
        isDark ? AppTheme.darkShutterRing : AppTheme.lightShutterRing;

    return Stack(
      children: [
        // Shutter flash effect
        if (_showShutterFlash)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),

        // Countdown display in center of viewfinder
        if (_countdownSeconds != null)
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$_countdownSeconds',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Chrome controls container
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // TOP BAR (Settings · Title · Timer) on scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Settings Icon
                          _IconButton(
                            icon: Icons.settings_outlined,
                            tooltip: 'Settings',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),

                          // Title
                          const Text(
                            'Pose Me',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),

                          // Timer Switcher (Off, 3s, 10s)
                          _IconButton(
                            icon: settings.timerSeconds == 0
                                ? Icons.timer_outlined
                                : (settings.timerSeconds == 3
                                    ? Icons.timer_3_outlined
                                    : Icons.timer_10_outlined),
                            tooltip: settings.timerSeconds == 0
                                ? 'Timer: Off'
                                : 'Timer: ${settings.timerSeconds}s',
                            badgeText: settings.timerSeconds > 0
                                ? '${settings.timerSeconds}s'
                                : null,
                            onPressed: () {
                              ref.read(settingsProvider.notifier).cycleTimer();
                            },
                          ),
                        ],
                      ),
                    ),
                    const CameraQuickMenu(),

                    // ATTRIBUTION RENDERER — NOTE: This is the ONLY attribution renderer
                    // in the entire camera screen and codebase. Do not add another one elsewhere!
                    if (overlayState.selectedPose != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6, bottom: 4),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.controlSurface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                overlayState.selectedPose!.isLocalImage
                                    ? 'From Gallery'
                                    : (overlayState.selectedPose!.isNetworkImage
                                        ? '${toTitleCase(overlayState.selectedPose!.photographer ?? overlayState.selectedPose!.name)} · Pexels'
                                        : toTitleCase(overlayState.selectedPose!.name)),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                ref.read(overlayProvider.notifier).clearPose();
                                ref.read(cameraQueueProvider.notifier).clearQueue();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // BOTTOM BAR & MODE SWITCHER
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // If queue session is active, show the horizontal queue strip
                    if (queueState.isActive) ...[
                      const CameraPoseQueueStrip(),
                      const SizedBox(height: 18),
                    ],

                    // Controls Row: Gallery · Shutter · Flip
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 24,
                        left: 32,
                        right: 32,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Gallery Thumbnail (48x48dp with 4dp corner radius)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const GalleryScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: latestPhoto != null &&
                                      File(latestPhoto.filePath).existsSync()
                                  ? Image.file(
                                      File(latestPhoto.filePath),
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.photo_outlined,
                                      color: Colors.white70,
                                      size: 22,
                                    ),
                            ),
                          ),

                          // 72dp Inverted Shutter Button
                          ScaleTransition(
                            scale: _shutterAnimController,
                            child: GestureDetector(
                              onTap: _onShutterPressed,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: shutterRing,
                                    width: 3.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4.5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cameraState.isCapturing
                                        ? Colors.grey
                                        : shutterFill,
                                  ),
                                  child: cameraState.isCapturing
                                      ? Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      shutterRing),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),

                          // Camera Flip Button (1.5dp outline, min 44x44 touch target)
                          _IconButton(
                            icon: Icons.flip_camera_ios_outlined,
                            tooltip: 'Flip Camera',
                            onPressed: () {
                              ref
                                  .read(cameraProvider.notifier)
                                  .switchCamera();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final String? badgeText;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
              if (badgeText != null)
                Positioned(
                  top: 4,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
