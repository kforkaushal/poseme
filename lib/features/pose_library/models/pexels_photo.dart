import 'dart:convert';

/// Represents a single photo from the Pexels API response.
class PexelsPhoto {
  final int id;
  final String thumbnailUrl;
  final String overlayUrl;
  final String photographer;

  const PexelsPhoto({
    required this.id,
    required this.thumbnailUrl,
    required this.overlayUrl,
    required this.photographer,
  });

  factory PexelsPhoto.fromJson(Map<String, dynamic> json) {
    final src = json['src'] as Map<String, dynamic>;
    return PexelsPhoto(
      id: json['id'] as int,
      thumbnailUrl: src['medium'] as String,
      overlayUrl: src['portrait'] as String,
      photographer: json['photographer'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'src': {
          'medium': thumbnailUrl,
          'portrait': overlayUrl,
        },
        'photographer': photographer,
      };

  /// Convenience: encode a list for cache storage.
  static String encodeList(List<PexelsPhoto> photos) =>
      jsonEncode(photos.map((p) => p.toJson()).toList());

  /// Convenience: decode a list from cache storage.
  static List<PexelsPhoto> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => PexelsPhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PexelsPhoto && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
