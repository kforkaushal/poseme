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

  /// Photo dimensions & aspect ratio
  final int? width;
  final int? height;

  /// Local gallery image reference
  final String? localFilePath;
  final bool isLocalImage;

  /// Whether to bypass B&W grayscale filter (e.g. for user gallery photos)
  final bool skipGrayscale;

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
    this.width,
    this.height,
    this.localFilePath,
    this.isLocalImage = false,
    this.skipGrayscale = false,
  });

  /// Computed aspect ratio clamped to aesthetic limits (portrait-leaning)
  double get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return (width! / height!).clamp(0.55, 1.4);
    }
    return 2 / 3;
  }

  /// Create a [PoseReference] from a Pexels API photo.
  factory PoseReference.fromPexels(PexelsPhoto photo, PoseCategory category) {
    return PoseReference(
      id: 'pexels_${photo.id}',
      name: photo.photographer,
      category: category,
      networkThumbnailUrl: photo.thumbnailUrl,
      networkOverlayUrl: photo.overlayUrl,
      photographer: photo.photographer,
      width: photo.width,
      height: photo.height,
    );
  }

  /// Create a [PoseReference] from a picked gallery photo.
  factory PoseReference.fromGallery({
    required String filePath,
    int? width,
    int? height,
  }) {
    return PoseReference(
      id: 'gallery_${DateTime.now().millisecondsSinceEpoch}',
      name: 'From Gallery',
      category: PoseCategory.all,
      localFilePath: filePath,
      isLocalImage: true,
      skipGrayscale: true,
      width: width,
      height: height,
    );
  }

  /// Whether this pose uses a network image (Pexels) vs a bundled asset or local file.
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

