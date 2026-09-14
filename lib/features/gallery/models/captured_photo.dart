import 'dart:convert';

class CapturedPhoto {
  final String id;
  final String filePath;
  final DateTime createdAt;
  final String? poseId;
  final String? poseAssetPath;
  final String? poseName;
  final bool isFrontCamera;

  const CapturedPhoto({
    required this.id,
    required this.filePath,
    required this.createdAt,
    this.poseId,
    this.poseAssetPath,
    this.poseName,
    this.isFrontCamera = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'poseId': poseId,
      'poseAssetPath': poseAssetPath,
      'poseName': poseName,
      'isFrontCamera': isFrontCamera,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory CapturedPhoto.fromJson(String source) =>
      CapturedPhoto.fromMap(json.decode(source) as Map<String, dynamic>);
}
