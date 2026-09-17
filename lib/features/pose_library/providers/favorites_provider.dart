import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pose_reference.dart';

/// StateNotifier that manages favorited poses, persisted locally in SharedPreferences.
class FavoritesNotifier extends StateNotifier<Map<String, PoseReference>> {
  static const String _storageKey = 'user_favorite_poses';

  FavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        final map = <String, PoseReference>{};
        for (final item in decoded) {
          final pose = PoseReference.fromMap(item as Map<String, dynamic>);
          map[pose.id] = pose;
        }
        state = map;
      }
    } catch (_) {
      // Fallback silently if storage read fails
    }
  }

  Future<void> toggleFavorite(PoseReference pose) async {
    final updated = Map<String, PoseReference>.from(state);
    if (updated.containsKey(pose.id)) {
      updated.remove(pose.id);
    } else {
      updated[pose.id] = pose;
    }
    state = updated;
    await _persist();
  }

  bool isFavorite(String poseId) {
    return state.containsKey(poseId);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = state.values.map((p) => p.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {
      // Ignore write failures gracefully
    }
  }
}

/// Global provider for favorites state
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Map<String, PoseReference>>((ref) {
  return FavoritesNotifier();
});

/// List of all favorited poses as a convenience provider
final favoritesListProvider = Provider<List<PoseReference>>((ref) {
  final favoritesMap = ref.watch(favoritesProvider);
  return favoritesMap.values.toList();
});
