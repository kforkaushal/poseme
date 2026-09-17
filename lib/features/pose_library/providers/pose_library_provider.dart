import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pose_reference.dart';
import '../services/pexels_cache_service.dart';
import '../services/pexels_service.dart';
import 'favorites_provider.dart';

/// Fetches and caches Pexels photos for a single [PoseCategory].
///
/// Strategy:
/// 1. Check local cache (shared_preferences, 6h TTL).
/// 2. If fresh cache exists → return immediately.
/// 3. Otherwise → fetch from API, cache results, return.
/// 4. On fetch failure + valid stale cache → return stale silently.
/// 5. On fetch failure + no cache → rethrow (UI shows retry).
///
/// Only used for individual categories (not [PoseCategory.all]).
final singleCategoryProvider = FutureProvider.family
    .autoDispose<List<PoseReference>, PoseCategory>((ref, category) async {
  final cacheService = ref.watch(pexelsCacheServiceProvider);
  final pexelsService = ref.watch(pexelsServiceProvider);

  // 1. Check fresh cache
  final cached = await cacheService.getCachedPhotos(category.apiQuery);
  if (cached != null && cached.isNotEmpty) {
    return cached
        .map((photo) => PoseReference.fromPexels(photo, category))
        .toList();
  }

  // 2. Fetch from API
  try {
    final photos = await pexelsService.fetchCategory(category.apiQuery);
    // Cache the results
    await cacheService.cachePhotos(category.apiQuery, photos);
    return photos
        .map((photo) => PoseReference.fromPexels(photo, category))
        .toList();
  } catch (e) {
    // 3. Fallback to stale cache on failure
    final stale = await cacheService.getStaleCachedPhotos(category.apiQuery);
    if (stale != null && stale.isNotEmpty) {
      return stale
          .map((photo) => PoseReference.fromPexels(photo, category))
          .toList();
    }
    // 4. No cache at all — rethrow so UI shows retry
    rethrow;
  }
});

/// Aggregates all fetchable categories into a single list.
/// Used when the user selects the "All" tab.
final allCategoriesProvider =
    FutureProvider.autoDispose<List<PoseReference>>((ref) async {
  final List<PoseReference> allPoses = [];
  for (final c in PoseCategory.fetchable) {
    try {
      final poses = await ref.watch(singleCategoryProvider(c).future);
      allPoses.addAll(poses);
    } catch (_) {
      // Skip failed categories — others still load
    }
  }
  return allPoses;
});

/// Main entry point: routes to either the "all" aggregator or a single
/// category provider based on the requested category.
final pexelsCategoryProvider = FutureProvider.family
    .autoDispose<List<PoseReference>, PoseCategory>((ref, category) async {
  if (category == PoseCategory.all) {
    return ref.watch(allCategoriesProvider.future);
  }
  return ref.watch(singleCategoryProvider(category).future);
});

/// Currently selected category tab.
final selectedPoseCategoryProvider = StateProvider<PoseCategory>((ref) {
  return PoseCategory.all;
});

/// Curated fixed tag list for fine-grained pose discovery.
const List<String> availablePoseTags = [
  'standing',
  'sitting',
  'close-up',
  'full-body',
  'side',
  'outdoor',
  'studio',
  'couple',
  'solo',
];

/// Mapping of UI tags to search query keywords.
const Map<String, String> poseTagQueryMap = {
  'standing': 'standing',
  'sitting': 'sitting',
  'close-up': 'close up portrait',
  'full-body': 'full body',
  'side': 'side profile',
  'outdoor': 'outdoor natural light',
  'studio': 'studio lighting',
  'couple': 'couple',
  'solo': 'solo',
};

/// Currently selected tags (multi-select).
final selectedPoseTagsProvider = StateProvider<Set<String>>((ref) {
  return {};
});

/// Whether the "Liked" / Favorites filter is active.
final isLikedFilterActiveProvider = StateProvider<bool>((ref) {
  return false;
});

/// Helper to build combined query for category + tags.
String buildPoseFilterQuery(PoseCategory category, Set<String> tags) {
  final baseQuery = category == PoseCategory.all
      ? 'fashion model pose photography'
      : category.apiQuery;
  if (tags.isEmpty) return baseQuery;
  final tagTerms = tags.map((t) => poseTagQueryMap[t] ?? t).join(' ');
  return '$baseQuery $tagTerms';
}

/// Fetches photos for any custom composed query string with caching.
final pexelsCustomQueryProvider = FutureProvider.family
    .autoDispose<List<PoseReference>, String>((ref, query) async {
  final cacheService = ref.watch(pexelsCacheServiceProvider);
  final pexelsService = ref.watch(pexelsServiceProvider);

  // 1. Check fresh cache
  final cached = await cacheService.getCachedPhotos(query);
  if (cached != null && cached.isNotEmpty) {
    return cached
        .map((photo) => PoseReference.fromPexels(photo, PoseCategory.all))
        .toList();
  }

  // 2. Fetch from API
  try {
    final photos = await pexelsService.fetchCategory(query);
    await cacheService.cachePhotos(query, photos);
    return photos
        .map((photo) => PoseReference.fromPexels(photo, PoseCategory.all))
        .toList();
  } catch (e) {
    // 3. Fallback to stale cache
    final stale = await cacheService.getStaleCachedPhotos(query);
    if (stale != null && stale.isNotEmpty) {
      return stale
          .map((photo) => PoseReference.fromPexels(photo, PoseCategory.all))
          .toList();
    }
    rethrow;
  }
});

/// Primary provider for Home screen poses, reacting to:
/// - Category selection
/// - Multi-selected tags
/// - Liked filter toggle
final homeFilteredPosesProvider =
    FutureProvider.autoDispose<List<PoseReference>>((ref) async {
  final isLikedActive = ref.watch(isLikedFilterActiveProvider);
  final category = ref.watch(selectedPoseCategoryProvider);
  final tags = ref.watch(selectedPoseTagsProvider);

  // If "Liked" filter is selected, show locally favorited poses
  if (isLikedActive) {
    final favoritesMap = ref.watch(favoritesProvider);
    var favorites = favoritesMap.values.toList();
    if (category != PoseCategory.all) {
      favorites = favorites.where((p) => p.category == category).toList();
    }
    return favorites;
  }

  // If tags are applied, run refined query
  if (tags.isNotEmpty) {
    final query = buildPoseFilterQuery(category, tags);
    return ref.watch(pexelsCustomQueryProvider(query).future);
  }

  // Otherwise, use standard category provider
  return ref.watch(pexelsCategoryProvider(category).future);
});
