import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pose_reference.dart';
import '../services/pexels_cache_service.dart';
import '../services/pexels_service.dart';

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
