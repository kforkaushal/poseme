import 'dart:convert';

class CapturedPhoto {
  final String id;
  final String filePath;
  final DateTime createdAt;
  final String? poseId;
  /// Bundled asset path — only populated for poses bundled with the app.
  /// Empty string for Pexels/network poses and gallery picks.
  final String? poseAssetPath;
  final String? poseName;
  final bool isFrontCamera;

  /// Network URL (Pexels overlay image) — populated when the active pose was a
  /// Pexels result. Used by the comparison view to render the reference panel.
  final String? poseNetworkUrl;

  /// Local file path — populated when the active pose was picked from the
  /// device gallery. Used by the comparison view to render the reference panel.
  final String? poseLocalFilePath;

  const CapturedPhoto({
    required this.id,
    required this.filePath,
    required this.createdAt,
    this.poseId,
    this.poseAssetPath,
    this.poseName,
    this.isFrontCamera = false,
    this.poseNetworkUrl,
    this.poseLocalFilePath,
  });

  /// True if this photo has a reference pose that can be shown in the comparison view.
  bool get hasReferenceImage =>
      (poseAssetPath != null && poseAssetPath!.isNotEmpty) ||
      poseNetworkUrl != null ||
      poseLocalFilePath != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'poseId': poseId,
      'poseAssetPath': poseAssetPath,
      'poseName': poseName,
      'isFrontCamera': isFrontCamera,
      'poseNetworkUrl': poseNetworkUrl,
      'poseLocalFilePath': poseLocalFilePath,
    };
  }

  factory CapturedPhoto.fromMap(Map<String, dynamic> map) {
    return CapturedPhoto(
      id: map['id'] as String,
      filePath: map['filePath'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      poseId: map['poseId'] as String?,
      poseAssetPath: map['poseAssetPath'] as String?,
      poseName: map['poseName'] as String?,
      isFrontCamera: (map['isFrontCamera'] as bool?) ?? false,
      poseNetworkUrl: map['poseNetworkUrl'] as String?,
      poseLocalFilePath: map['poseLocalFilePath'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory CapturedPhoto.fromJson(String source) =>
      CapturedPhoto.fromMap(json.decode(source) as Map<String, dynamic>);
}
