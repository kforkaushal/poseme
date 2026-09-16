import 'package:camera/camera.dart';

/// The display / save crop ratio selected from the quick menu.
enum CameraAspectRatio {
  /// Full sensor — no crop applied to preview or saved file.
  full('Full', null),
  /// 9:16 portrait (standard Reels/Shorts format).
  ratio9x16('9:16', 9 / 16),
  /// 4:5 portrait (Instagram portrait).
  ratio4x5('4:5', 4 / 5),
  /// Square.
  ratio1x1('1:1', 1.0);

  final String label;
  /// Target width/height ratio; null means no crop.
  final double? ratio;
  const CameraAspectRatio(this.label, this.ratio);
}

class CameraState {
  final bool isInitialized;
  final bool isInitializing;
  final bool hasPermission;
  final bool isPermanentlyDenied;
  final List<CameraDescription> availableCameras;
  final int selectedCameraIndex;
  final FlashMode flashMode;
  final bool isCapturing;
  final String? errorMessage;
  final CameraAspectRatio aspectRatioMode;

  const CameraState({
    this.isInitialized = false,
    this.isInitializing = false,
    this.hasPermission = false,
    this.isPermanentlyDenied = false,
    this.availableCameras = const [],
    this.selectedCameraIndex = 0,
    this.flashMode = FlashMode.auto,
    this.isCapturing = false,
    this.errorMessage,
    this.aspectRatioMode = CameraAspectRatio.full,
  });

  bool get hasCameras => availableCameras.isNotEmpty;

  CameraDescription? get currentCamera =>
      hasCameras && selectedCameraIndex < availableCameras.length
          ? availableCameras[selectedCameraIndex]
          : null;

  bool get isFrontCamera =>
      currentCamera?.lensDirection == CameraLensDirection.front;

  CameraState copyWith({
    bool? isInitialized,
    bool? isInitializing,
    bool? hasPermission,
    bool? isPermanentlyDenied,
    List<CameraDescription>? availableCameras,
    int? selectedCameraIndex,
    FlashMode? flashMode,
    bool? isCapturing,
    String? errorMessage,
    bool clearError = false,
    CameraAspectRatio? aspectRatioMode,
  }) {
    return CameraState(
      isInitialized: isInitialized ?? this.isInitialized,
      isInitializing: isInitializing ?? this.isInitializing,
      hasPermission: hasPermission ?? this.hasPermission,
      isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
      availableCameras: availableCameras ?? this.availableCameras,
      selectedCameraIndex: selectedCameraIndex ?? this.selectedCameraIndex,
      flashMode: flashMode ?? this.flashMode,
      isCapturing: isCapturing ?? this.isCapturing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      aspectRatioMode: aspectRatioMode ?? this.aspectRatioMode,
    );
  }
}
