import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/photo_storage_service.dart';
import '../models/captured_photo.dart';

final galleryPhotosProvider =
    StateNotifierProvider<GalleryPhotosNotifier, AsyncValue<List<CapturedPhoto>>>(
  (ref) {
    final storageService = ref.watch(photoStorageServiceProvider);
    return GalleryPhotosNotifier(storageService);
  },
);

final latestCapturedPhotoProvider = Provider<CapturedPhoto?>((ref) {
  final photosState = ref.watch(galleryPhotosProvider);
  return photosState.valueOrNull?.firstOrNull;
});

class GalleryPhotosNotifier extends StateNotifier<AsyncValue<List<CapturedPhoto>>> {
  final PhotoStorageService _storageService;

  GalleryPhotosNotifier(this._storageService)
      : super(const AsyncValue.loading()) {
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    try {
      final photos = await _storageService.loadSavedPhotos();
      state = AsyncValue.data(photos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addPhoto(CapturedPhoto photo) {
    final currentList = state.valueOrNull ?? [];
    state = AsyncValue.data([photo, ...currentList]);
  }

  Future<void> deletePhoto(String photoId) async {
    final currentList = state.valueOrNull ?? [];
    state = AsyncValue.data(currentList.where((p) => p.id != photoId).toList());
    try {
      await _storageService.deletePhoto(photoId);
    } catch (e) {
      // If error occurs, reload original list
      await loadPhotos();
    }
  }
}
