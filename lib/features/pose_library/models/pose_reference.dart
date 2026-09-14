import 'pexels_photo.dart';

/// Pose categories mapped to Pexels API search queries.
///
/// Each value (except [all]) has a fixed [apiQuery] that is sent to
/// the Pexels search endpoint. The user sees [displayName] — never
/// the raw search term.
enum PoseCategory {
  all('All', ''),
  portrait('Portrait', 'portrait pose photography'),
  fullBody('Full Body', 'fashion pose full body'),
  couple('Couple', 'couple pose photography'),
  outdoor('Outdoor', 'outdoor portrait pose'),
  studio('Studio', 'studio portrait pose');

  final String displayName;
  final String apiQuery;
  const PoseCategory(this.displayName, this.apiQuery);

  /// All categories that have an API query (excludes [all]).
  static List<PoseCategory> get fetchable =>
      values.where((c) => c != all).toList();
}

class PoseReference {
  final String id;
  final String name;
  final PoseCategory category;
  final String assetPath;
  final String description;
  final List<String> tips;
  final String difficulty;

  /// Network image URLs (from Pexels API) — null for bundled assets.
  final String? networkThumbnailUrl;
  final String? networkOverlayUrl;
  final String? photographer;

  const PoseReference({
    required this.id,
    required this.name,
    required this.category,
    this.assetPath = '',
    this.description = '',
    this.tips = const [],
    this.difficulty = 'Easy',
    this.networkThumbnailUrl,
    this.networkOverlayUrl,
    this.photographer,
  });

  /// Create a [PoseReference] from a Pexels API photo.
  factory PoseReference.fromPexels(PexelsPhoto photo, PoseCategory category) {
    return PoseReference(
      id: 'pexels_${photo.id}',
      name: photo.photographer,
      category: category,
      networkThumbnailUrl: photo.thumbnailUrl,
      networkOverlayUrl: photo.overlayUrl,
      photographer: photo.photographer,
    );
  }

  /// Whether this pose uses a network image (Pexels) vs a bundled asset.
  bool get isNetworkImage => networkOverlayUrl != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoseReference &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

