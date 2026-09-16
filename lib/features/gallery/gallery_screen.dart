import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'models/captured_photo.dart';
import 'providers/gallery_provider.dart';
import 'widgets/photo_comparison_sheet.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  void _openPhotoDetail(
      BuildContext context, CapturedPhoto photo, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoDetailView(photo: photo),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosState = ref.watch(galleryPhotosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor =
        isDark ? AppTheme.darkBorderHairline : AppTheme.lightBorderHairline;
    final elevatedBg =
        isDark ? AppTheme.darkBgElevated : AppTheme.lightBgElevated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Captured Photos'),
      ),
      body: photosState.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(textColor),
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Failed to load gallery: $err',
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
        data: (photos) {
          if (photos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: elevatedBg,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        Icons.photo_outlined,
                        size: 26,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No photos yet — tap the shutter to take your first one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () => _openPhotoDetail(context, photo, ref),
                child: Container(
                  decoration: BoxDecoration(
                    color: elevatedBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(photo.filePath),
                        fit: BoxFit.cover,
                      ),
                      if (photo.poseName != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            color: Colors.black.withValues(alpha: 0.7),
                            child: Text(
                              photo.poseName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PhotoDetailView extends ConsumerWidget {
  final CapturedPhoto photo;

  const _PhotoDetailView({required this.photo});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedBg =
        isDark ? AppTheme.darkBgElevated : AppTheme.lightBgElevated;
    final textColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: elevatedBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          title: Text(
            'Delete Photo?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          content: Text(
            'This removes the photo from the app gallery. Any copy in your device camera roll will remain saved.',
            style: TextStyle(color: secondaryTextColor, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
            ),
            TextButton(
              onPressed: () {
                ref.read(galleryPhotosProvider.notifier).deletePhoto(photo.id);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          photo.poseName ?? 'Photo',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        actions: [
          if (photo.hasReferenceImage)
            IconButton(
              icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
              tooltip: 'Compare with Pose Guide',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.9,
                    child: PhotoComparisonSheet(photo: photo),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Delete Photo',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(photo.filePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
