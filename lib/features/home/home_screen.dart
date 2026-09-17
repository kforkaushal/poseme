import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/main_navigation_screen.dart';
import '../../app/theme.dart';
import '../../core/utils/string_utils.dart';
import '../camera/providers/overlay_provider.dart';
import '../pose_library/models/pose_reference.dart';
import '../pose_library/providers/favorites_provider.dart';
import '../pose_library/providers/pose_library_provider.dart';
import '../pose_library/providers/shot_list_provider.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedPoseCategoryProvider);
    final selectedTags = ref.watch(selectedPoseTagsProvider);
    final isLikedActive = ref.watch(isLikedFilterActiveProvider);
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final selectedPoses = ref.watch(selectedShotListProvider);
    final posesAsync = ref.watch(homeFilteredPosesProvider);

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

    // Reset scroll to top when category or tags change
    ref.listen(selectedPoseCategoryProvider, (_, _) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0.0);
    });
    ref.listen(selectedPoseTagsProvider, (_, _) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0.0);
    });
    ref.listen(isLikedFilterActiveProvider, (_, _) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0.0);
    });

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Pose Me',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          // "Select" / "Cancel" mode toggle
          TextButton(
            onPressed: () {
              if (isSelectionMode) {
                ref.read(selectedShotListProvider.notifier).clear();
                ref.read(isSelectionModeProvider.notifier).state = false;
              } else {
                ref.read(isSelectionModeProvider.notifier).state = true;
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: textColor,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(isSelectionMode ? 'Cancel' : 'Select'),
          ),

          // Settings gear
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Category Tabs + Liked Filter Chip
              SizedBox(
                height: 36,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    // "Liked" heart chip
                    _CategoryPill(
                      label: 'Liked',
                      icon: Icons.favorite_rounded,
                      isSelected: isLikedActive,
                      onTap: () {
                        ref.read(isLikedFilterActiveProvider.notifier).state =
                            !isLikedActive;
                      },
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      bgColor: bgColor,
                      elevatedBg: elevatedBg,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 6),

                    // Standard Category Tabs
                    ...PoseCategory.values.map((category) {
                      final isSelected =
                          !isLikedActive && category == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _CategoryPill(
                          label: category.displayName,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(isLikedFilterActiveProvider.notifier)
                                .state = false;
                            ref
                                .read(selectedPoseCategoryProvider.notifier)
                                .state = category;
                          },
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          bgColor: bgColor,
                          elevatedBg: elevatedBg,
                          borderColor: borderColor,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tag Chips Row (Scrollable Horizontal Multi-Select)
              SizedBox(
                height: 32,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: availablePoseTags.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final tag = availablePoseTags[index];
                    final isSelected = selectedTags.contains(tag);

                    return GestureDetector(
                      onTap: () {
                        final current = Set<String>.from(
                            ref.read(selectedPoseTagsProvider));
                        if (isSelected) {
                          current.remove(tag);
                        } else {
                          current.add(tag);
                        }
                        ref.read(selectedPoseTagsProvider.notifier).state =
                            current;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : borderColor,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(
                                Icons.check,
                                size: 12,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? (isDark ? Colors.black : Colors.white)
                                    : secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              Divider(color: borderColor, height: 1),

              // Masonry Grid
              Expanded(
                child: posesAsync.when(
                  loading: () => _HomeShimmerGrid(
                    scrollController: _scrollController,
                    elevatedBg: elevatedBg,
                    isDark: isDark,
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 40,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load poses',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check connection and try again.',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () =>
                                ref.refresh(homeFilteredPosesProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (poses) {
                    if (poses.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isLikedActive
                                    ? Icons.favorite_border_rounded
                                    : Icons.filter_alt_outlined,
                                size: 48,
                                color: secondaryTextColor.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isLikedActive
                                    ? 'No liked poses yet'
                                    : 'No poses matching filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isLikedActive
                                    ? 'Tap the heart on any pose card to save it here.'
                                    : 'Try clearing some tags or switching categories.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return MasonryGridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        isSelectionMode ? 80 : 24,
                      ),
                      gridDelegate:
                          const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      itemCount: poses.length + 1,
                      itemBuilder: (context, index) {
                        // Tile #0: Gallery import tile
                        if (index == 0) {
                          return _HomeGalleryTile(
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            borderColor: borderColor,
                            elevatedBg: elevatedBg,
                          );
                        }

                        final pose = poses[index - 1];
                        final isPoseSelected =
                            selectedPoses.any((p) => p.id == pose.id);

                        return _HomePoseTile(
                          pose: pose,
                          isSelectionMode: isSelectionMode,
                          isPoseSelected: isPoseSelected,
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

          // Floating Multi-Select "Start Shoot" Bar
          if (isSelectionMode)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _StartShootFloatingBar(
                selectedCount: selectedPoses.length,
                onStartShoot: selectedPoses.isEmpty
                    ? null
                    : () {
                        // Start session queue in camera
                        ref
                            .read(cameraQueueProvider.notifier)
                            .startQueue(selectedPoses);
                        ref
                            .read(overlayProvider.notifier)
                            .selectPose(selectedPoses.first);
                        ref.read(selectedShotListProvider.notifier).clear();
                        ref.read(isSelectionModeProvider.notifier).state =
                            false;
                        // Navigate to Camera tab
                        ref.read(navigationIndexProvider.notifier).state = 1;
                      },
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textColor;
  final Color secondaryTextColor;
  final Color bgColor;
  final Color elevatedBg;
  final Color borderColor;

  const _CategoryPill({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.textColor,
    required this.secondaryTextColor,
    required this.bgColor,
    required this.elevatedBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? textColor : elevatedBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? textColor : borderColor,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? bgColor : secondaryTextColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? bgColor : secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeGalleryTile extends ConsumerWidget {
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color elevatedBg;

  const _HomeGalleryTile({
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.elevatedBg,
  });

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery);
      if (xFile == null) return;

      int? width;
      int? height;
      try {
        final bytes = await xFile.readAsBytes();
        final decoded = await decodeImageFromList(bytes);
        width = decoded.width;
        height = decoded.height;
      } catch (_) {}

      final pose = PoseReference.fromGallery(
        filePath: xFile.path,
        width: width,
        height: height,
      );

      final isSelectionMode = ref.read(isSelectionModeProvider);
      if (isSelectionMode) {
        ref.read(selectedShotListProvider.notifier).togglePose(pose);
      } else {
        ref.read(overlayProvider.notifier).selectPose(pose);
        ref.read(cameraQueueProvider.notifier).clearQueue();
        ref.read(navigationIndexProvider.notifier).state = 1;
      }
    } catch (e) {
      debugPrint('Gallery picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: GestureDetector(
        onTap: () => _pickImage(context, ref),
        child: Container(
          decoration: BoxDecoration(
            color: elevatedBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLibrary),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: textColor.withValues(alpha: 0.08),
                  border: Border.all(
                    color: textColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 22,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'From gallery',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Use own photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePoseTile extends ConsumerWidget {
  final PoseReference pose;
  final bool isSelectionMode;
  final bool isPoseSelected;
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final Color elevatedBg;

  const _HomePoseTile({
    required this.pose,
    required this.isSelectionMode,
    required this.isPoseSelected,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    required this.elevatedBg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesMap = ref.watch(favoritesProvider);
    final isFavorite = favoritesMap.containsKey(pose.id);

    return AspectRatio(
      aspectRatio: pose.aspectRatio,
      child: GestureDetector(
        onTap: () {
          if (isSelectionMode) {
            ref.read(selectedShotListProvider.notifier).togglePose(pose);
          } else {
            // Instant selection & navigation to Camera tab
            ref.read(overlayProvider.notifier).selectPose(pose);
            ref.read(cameraQueueProvider.notifier).clearQueue();
            ref.read(navigationIndexProvider.notifier).state = 1;
          }
        },
        onLongPress: () {
          if (!isSelectionMode) {
            ref.read(isSelectionModeProvider.notifier).state = true;
            ref.read(selectedShotListProvider.notifier).togglePose(pose);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: elevatedBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLibrary),
            border: Border.all(
              color: isPoseSelected ? Colors.white : borderColor,
              width: isPoseSelected ? 2.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Grayscale thumbnail
              ColorFiltered(
                colorFilter:
                    const ColorFilter.matrix(AppTheme.grayscaleMatrix),
                child: pose.isNetworkImage
                    ? CachedNetworkImage(
                        imageUrl: pose.networkThumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _tileShimmer(isDark, elevatedBg),
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

              // Dim overlay when selected in multi-select mode
              if (isPoseSelected)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),

              // Selection checkmark (top-left)
              if (isSelectionMode)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPoseSelected
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.55),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: isPoseSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.black,
                          )
                        : null,
                  ),
                ),

              // Favorite heart button (top-right)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(pose);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.50),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: isFavorite ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),

              // Photographer caption badge at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  color: (isDark ? Colors.black : Colors.white)
                      .withValues(alpha: 0.80),
                  child: Text(
                    toTitleCase(
                      pose.isNetworkImage
                          ? (pose.photographer ?? '')
                          : pose.name,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isPoseSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileShimmer(bool isDark, Color elevatedBg) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF16181D) : const Color(0xFFE5E5E7),
      highlightColor:
          isDark ? const Color(0xFF22262F) : const Color(0xFFF2F2F4),
      child: Container(color: elevatedBg),
    );
  }
}

class _StartShootFloatingBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onStartShoot;

  const _StartShootFloatingBar({
    required this.selectedCount,
    required this.onStartShoot,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onStartShoot != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedCount == 0
                  ? 'Select poses to queue'
                  : '$selectedCount ${selectedCount == 1 ? 'pose' : 'poses'} selected',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onStartShoot,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start Shoot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? Colors.white : Colors.white24,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white24,
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeShimmerGrid extends StatelessWidget {
  final ScrollController scrollController;
  final Color elevatedBg;
  final bool isDark;

  const _HomeShimmerGrid({
    required this.scrollController,
    required this.elevatedBg,
    required this.isDark,
  });

  static const List<double> _shimmerRatios = [
    0.82,
    0.72,
    0.65,
    0.90,
    0.75,
    0.68,
    0.85,
    0.70,
  ];

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF16181D) : const Color(0xFFE5E5E7),
      highlightColor:
          isDark ? const Color(0xFF22262F) : const Color(0xFFF2F2F4),
      child: MasonryGridView.builder(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: _shimmerRatios.length,
        itemBuilder: (context, index) {
          return AspectRatio(
            aspectRatio: _shimmerRatios[index % _shimmerRatios.length],
            child: Container(
              decoration: BoxDecoration(
                color: elevatedBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusLibrary),
              ),
            ),
          );
        },
      ),
    );
  }
}
