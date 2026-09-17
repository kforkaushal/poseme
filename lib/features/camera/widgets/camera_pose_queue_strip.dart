import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../pose_library/models/pose_reference.dart';
import '../../pose_library/providers/shot_list_provider.dart';
import '../providers/overlay_provider.dart';

/// Horizontal thumbnail strip displayed above the shutter when a multi-pose
/// shot list session is active. Allows switching poses in 1 tap without leaving
/// the camera viewfinder.
class CameraPoseQueueStrip extends ConsumerWidget {
  const CameraPoseQueueStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(cameraQueueProvider);
    if (!queueState.isActive) return const SizedBox.shrink();

    final poses = queueState.poses;
    final activeIndex = queueState.activeIndex;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.controlSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Queue index counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(height: 2),
                Text(
                  '${activeIndex + 1}/${poses.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 0.5,
            height: 36,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 6),

          // Scrollable thumbnail list
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              itemCount: poses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final pose = poses[index];
                final isActive = index == activeIndex;

                return GestureDetector(
                  onTap: () {
                    ref.read(cameraQueueProvider.notifier).selectIndex(index);
                    ref.read(overlayProvider.notifier).selectPose(pose);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                        width: isActive ? 2.0 : 1.0,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Opacity(
                      opacity: isActive ? 1.0 : 0.6,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(
                            AppTheme.grayscaleMatrix),
                        child: _buildPoseImage(pose),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Close / Exit queue session button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: Colors.white54,
            tooltip: 'End Pose Queue',
            onPressed: () {
              ref.read(cameraQueueProvider.notifier).clearQueue();
              ref.read(overlayProvider.notifier).clearPose();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPoseImage(PoseReference pose) {
    if (pose.isLocalImage && pose.localFilePath != null) {
      return Image.file(
        File(pose.localFilePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: Colors.black26),
      );
    } else if (pose.isNetworkImage && pose.networkThumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: pose.networkThumbnailUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => Container(color: Colors.black26),
      );
    } else if (pose.assetPath.isNotEmpty) {
      return Image.asset(
        pose.assetPath,
        fit: BoxFit.cover,
      );
    }
    return Container(color: Colors.black26);
  }
}
