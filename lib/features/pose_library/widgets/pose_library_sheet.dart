import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/theme.dart';
import '../../camera/providers/overlay_provider.dart';
import '../models/pose_reference.dart';
import '../providers/pose_library_provider.dart';

class PoseLibrarySheet extends ConsumerWidget {
  const PoseLibrarySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PoseLibrarySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedPoseCategoryProvider);
    final posesAsync = ref.watch(pexelsCategoryProvider(selectedCategory));
    final activePose = ref.watch(overlayProvider).selectedPose;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final textColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor =
        isDark ? AppTheme.darkBorderHairline : AppTheme.lightBorderHairline;
    final elevatedBg =
        isDark ? AppTheme.darkBgElevated : AppTheme.lightBgElevated;

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusSmall),
            ),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // Top drag handle
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: secondaryTextColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title and Dismiss / Clear button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pose Library',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (activePose != null)
                          TextButton(
                            onPressed: () {
                              ref.read(overlayProvider.notifier).clearPose();
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: secondaryTextColor,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text('Clear',
                                style: TextStyle(fontSize: 13)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: textColor,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Category filter row
              SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: PoseCategory.values.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final category = PoseCategory.values[index];
                    final isSelected = category == selectedCategory;

                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(selectedPoseCategoryProvider.notifier)
                            .state = category;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? textColor : elevatedBg,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: isSelected ? textColor : borderColor,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          category.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? bgColor : secondaryTextColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              Divider(color: borderColor, height: 1),

              // Grid content: loading / error / data
              Expanded(
                child: posesAsync.when(
                  loading: () => _ShimmerGrid(
                    scrollController: scrollController,
                    elevatedBg: elevatedBg,
                    isDark: isDark,
                  ),
                  error: (error, _) => _ErrorRetryView(
                    category: selectedCategory,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  data: (poses) {
                    if (poses.isEmpty) {
                      return Center(
                        child: Text(
                          'No poses found in this category.',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      );
                    }
                    return GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2 / 3,
                      ),
                      itemCount: poses.length,
                      itemBuilder: (context, index) {
                        final pose = poses[index];
                        final isSelected = activePose?.id == pose.id;

                        return _PoseTile(
                          pose: pose,
                          isSelected: isSelected,
                          isDark: isDark,
                          textColor: textColor,
                          borderColor: borderColor,
                          elevatedBg: elevatedBg,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A single pose thumbnail tile in the grid.
class _PoseTile extends ConsumerWidget {
  final PoseReference pose;
  final bool isSelected;
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final Color elevatedBg;

  const _PoseTile({
    required this.pose,
    required this.isSelected,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    required this.elevatedBg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(overlayProvider.notifier).selectPose(pose);
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: elevatedBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? textColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Grayscale Pose Thumbnail
            ColorFiltered(
              colorFilter:
                  const ColorFilter.matrix(AppTheme.grayscaleMatrix),
              child: pose.isNetworkImage
                  ? CachedNetworkImage(
                      imageUrl: pose.networkThumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _tileShimmer(isDark),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white38,
                          size: 24,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        pose.assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),

            // Photographer / pose name caption at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                color: (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.8),
                child: Text(
                  pose.isNetworkImage
                      ? pose.photographer ?? ''
                      : pose.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _tileShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor:
          isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: Container(color: Colors.white),
    );
  }
}

/// Shimmer skeleton grid shown while a category is loading.
class _ShimmerGrid extends StatelessWidget {
  final ScrollController scrollController;
  final Color elevatedBg;
  final bool isDark;

  const _ShimmerGrid({
    required this.scrollController,
    required this.elevatedBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor:
          isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2 / 3,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          );
        },
      ),
    );
  }
}

/// Inline error + retry widget for a failed category.
class _ErrorRetryView extends ConsumerWidget {
  final PoseCategory category;
  final Color textColor;
  final Color secondaryTextColor;

  const _ErrorRetryView({
    required this.category,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: secondaryTextColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Couldn\'t load poses',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again.',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                // Invalidate the provider to trigger a refetch
                ref.invalidate(pexelsCategoryProvider(category));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: textColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  'Tap to retry',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkBgPrimary
                        : AppTheme.lightBgPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
