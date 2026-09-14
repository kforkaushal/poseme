import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pexels_photo.dart';

/// Local cache for Pexels API responses using shared_preferences.
///
/// Each category's photo list is stored as JSON with a timestamp.
/// Cache entries older than [_maxAge] are treated as stale and
/// trigger a fresh API fetch (but are still returned as fallback
/// if the fetch fails).
class PexelsCacheService {
  static const Duration _maxAge = Duration(hours: 6);

  static String _cacheKey(String category) => 'pexels_cache_$category';
  static String _timestampKey(String category) => 'pexels_ts_$category';

  /// Returns cached photos if they exist and are under 6 hours old.
  /// Returns null if no cache or if cache is stale.
  Future<List<PexelsPhoto>?> getCachedPhotos(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheKey(category));
    final timestamp = prefs.getInt(_timestampKey(category));

    if (json == null || timestamp == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cachedAt) > _maxAge) return null;

    return PexelsPhoto.decodeList(json);
  }

  /// Returns any cached photos regardless of age (fallback for network failures).
  Future<List<PexelsPhoto>?> getStaleCachedPhotos(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheKey(category));
    if (json == null) return null;
    return PexelsPhoto.decodeList(json);
  }

  /// Cache a category's photo list with the current timestamp.
  Future<void> cachePhotos(
    String category,
    List<PexelsPhoto> photos,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(category), PexelsPhoto.encodeList(photos));
    await prefs.setInt(
      _timestampKey(category),
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Riverpod provider for the Pexels cache service.
final pexelsCacheServiceProvider = Provider<PexelsCacheService>((ref) {
  return PexelsCacheService();
});
