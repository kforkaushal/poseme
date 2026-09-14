import 'package:camera/camera.dart';

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
    );
  }
}
