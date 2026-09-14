import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/permission_service.dart';
import '../models/camera_state.dart';
import 'overlay_provider.dart';

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  final notifier = CameraNotifier(ref, permissionService);
  ref.onDispose(() {
    notifier.disposeController();
  });
  return notifier;
});

class CameraNotifier extends StateNotifier<CameraState> with WidgetsBindingObserver {
  final Ref _ref;
  final PermissionService _permissionService;
  CameraController? _controller;

  CameraNotifier(this._ref, this._permissionService)
      : super(const CameraState()) {
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
  }

  CameraController? get controller => _controller;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;

    // App state changed before we got the chance to initialize
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Free camera resource when app is backgrounded
      disposeController();
      this.state = this.state.copyWith(isInitialized: false);
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize camera on foreground resume
      initializeCamera();
    }
  }

  Future<void> initializeCamera() async {
    state = state.copyWith(isInitializing: true, clearError: true);

    // 1. Permission Check
    var hasPermission = await _permissionService.hasCameraPermission();
    if (!hasPermission) {
      hasPermission = await _permissionService.requestCameraPermission();
      if (!hasPermission) {
        final permanentlyDenied =
            await _permissionService.isCameraPermanentlyDenied();
        state = state.copyWith(
          isInitializing: false,
          hasPermission: false,
          isPermanentlyDenied: permanentlyDenied,
          errorMessage: 'Camera permission is required to align poses and capture photos.',
        );
        return;
      }
    }

    state = state.copyWith(hasPermission: true, isPermanentlyDenied: false);

    // 2. Discover available cameras
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          isInitializing: false,
          availableCameras: [],
          errorMessage: 'No cameras found on this device.',
        );
        return;
      }

      state = state.copyWith(availableCameras: cameras);

      final selectedIndex = state.selectedCameraIndex.clamp(0, cameras.length - 1);
      await _startController(cameras[selectedIndex]);
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        errorMessage: 'Failed to access camera: $e',
      );
    }
  }

  Future<void> _startController(CameraDescription cameraDescription) async {
    await disposeController();

    final newController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = newController;

    try {
      await newController.initialize();
      await newController.setFlashMode(state.flashMode);

      final isFront = cameraDescription.lensDirection == CameraLensDirection.front;
      // Auto mirror the overlay for front camera so user doesn't have to think about it
      _ref.read(overlayProvider.notifier).setAutoMirrorForCamera(isFront);

      state = state.copyWith(
        isInitialized: true,
        isInitializing: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: false,
        isInitializing: false,
        errorMessage: 'Could not initialize camera preview: $e',
      );
    }
  }

  /// Switches between front and back cameras
  Future<void> switchCamera() async {
    if (!state.hasCameras || state.availableCameras.length < 2 || state.isInitializing) {
      return;
    }

    final nextIndex = (state.selectedCameraIndex + 1) % state.availableCameras.length;
    state = state.copyWith(selectedCameraIndex: nextIndex, isInitializing: true);
    await _startController(state.availableCameras[nextIndex]);
  }

  /// Cycles flash mode (auto -> off -> always)
  Future<void> cycleFlashMode() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    FlashMode nextMode;
    switch (state.flashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      case FlashMode.off:
      default:
        nextMode = FlashMode.auto;
        break;
    }

    try {
      await ctrl.setFlashMode(nextMode);
      state = state.copyWith(flashMode: nextMode);
    } catch (_) {
      // Some cameras (like front cameras) don't support torch/flash
    }
  }

  /// Takes a raw photo frame from camera
  Future<XFile?> takePicture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || state.isCapturing) {
      return null;
    }

    try {
      state = state.copyWith(isCapturing: true);
      final picture = await ctrl.takePicture();
      state = state.copyWith(isCapturing: false);
      return picture;
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        errorMessage: 'Capture failed: $e',
      );
      return null;
    }
  }

  Future<void> disposeController() async {
    final ctrl = _controller;
    _controller = null;
    if (ctrl != null) {
      try {
        await ctrl.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeController();
    super.dispose();
  }
}
