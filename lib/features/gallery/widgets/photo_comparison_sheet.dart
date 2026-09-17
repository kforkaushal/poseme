import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../models/captured_photo.dart';

class PhotoComparisonSheet extends StatefulWidget {
  final CapturedPhoto photo;

  const PhotoComparisonSheet({super.key, required this.photo});

  @override
  State<PhotoComparisonSheet> createState() => _PhotoComparisonSheetState();
}

class _PhotoComparisonSheetState extends State<PhotoComparisonSheet> {
  bool _isSideBySide = true;
  double _splitRatio = 0.5;

  /// Builds the reference pose image, branching on source type.
  /// Returns a graceful placeholder if the source is genuinely unavailable
  /// (e.g. a photo captured before this metadata existed).
  Widget _buildReferenceImage(CapturedPhoto photo) {
    Widget child;
    if (photo.poseNetworkUrl != null) {
      child = CachedNetworkImage(
        imageUrl: photo.poseNetworkUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white38,
          ),
        ),
        errorWidget: (context, url, error) => const _ReferencePlaceholder(
          message: 'Could not load reference image',
        ),
      );
    } else if (photo.poseLocalFilePath != null) {
      child = Image.file(
        File(photo.poseLocalFilePath!),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _ReferencePlaceholder(
          message: 'Gallery photo no longer available',
        ),
      );
    } else if (photo.poseAssetPath != null && photo.poseAssetPath!.isNotEmpty) {
      child = Image.asset(
        photo.poseAssetPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _ReferencePlaceholder(
          message: 'Bundled pose not found',
        ),
      );
    } else {
      return const _ReferencePlaceholder(
        message: 'Reference image unavailable',
      );
    }

    // Apply grayscale filter (Pexels + bundled assets; skip for user gallery)
    if (photo.poseLocalFilePath != null) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(AppTheme.grayscaleMatrix),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    final hasPose = photo.hasReferenceImage;

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Top action bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    photo.poseName ?? 'Captured Photo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasPose)
                    IconButton(
                      icon: Icon(
                        _isSideBySide
                            ? Icons.view_column_outlined
                            : Icons.compare_arrows_rounded,
                        color: Colors.white,
                      ),
                      tooltip: _isSideBySide
                          ? 'Switch to Split Slider'
                          : 'Switch to Side-by-Side',
                      onPressed: () {
                        setState(() => _isSideBySide = !_isSideBySide);
                      },
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Comparison View
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: hasPose
                    ? (_isSideBySide
                        ? _buildSideBySide(photo)
                        : _buildSplitSlider(photo))
                    : _buildSinglePhoto(photo),
              ),
            ),

            // Bottom Caption
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Captured on ${_formatDate(photo.createdAt)}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePhoto(CapturedPhoto photo) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Image.file(
          File(photo.filePath),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  Widget _buildSideBySide(CapturedPhoto photo) {
    return Row(
      children: [
        // Reference Pose (in Grayscale)
        Expanded(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'reference pose',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.all(16),
                  child: _buildReferenceImage(photo),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // User Captured Photo
        Expanded(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'your shot',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    File(photo.filePath),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitSlider(CapturedPhoto photo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Bottom Layer: Your Shot
              Image.file(
                File(photo.filePath),
                fit: BoxFit.cover,
              ),

              // Top Layer: Pose Reference Clipped
              ClipRect(
                clipper: _HorizontalSplitClipper(ratio: _splitRatio),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  child: _buildReferenceImage(photo),
                ),
              ),

              // Split Divider Handle (High-contrast B&W)
              Positioned(
                left: (w * _splitRatio) - 1,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _splitRatio =
                          (details.localPosition.dx / w).clamp(0.05, 0.95);
                    });
                  },
                  child: Container(
                    width: 2,
                    color: Colors.white,
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.drag_handle,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _HorizontalSplitClipper extends CustomClipper<Rect> {
  final double ratio;
  _HorizontalSplitClipper({required this.ratio});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * ratio, size.height);
  }

  @override
  bool shouldReclip(_HorizontalSplitClipper oldClipper) =>
      oldClipper.ratio != ratio;
}

/// Shown when the reference image source is unavailable (no URL, no local file,
/// no bundled asset) — e.g. for photos captured before source metadata was tracked.
class _ReferencePlaceholder extends StatelessWidget {
  final String message;
  const _ReferencePlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined,
              color: Colors.white30, size: 36),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
