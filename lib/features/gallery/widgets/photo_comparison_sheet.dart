import 'dart:io';
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

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    final hasPose = photo.poseAssetPath != null;

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
                  child: ColorFiltered(
                    colorFilter:
                        const ColorFilter.matrix(AppTheme.grayscaleMatrix),
                    child: Image.asset(
                      photo.poseAssetPath!,
                      fit: BoxFit.contain,
                    ),
                  ),
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

              // Top Layer: Pose Reference Clipped (Grayscale)
              ClipRect(
                clipper: _HorizontalSplitClipper(ratio: _splitRatio),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  child: ColorFiltered(
                    colorFilter:
                        const ColorFilter.matrix(AppTheme.grayscaleMatrix),
                    child: Image.asset(
                      photo.poseAssetPath!,
                      fit: BoxFit.contain,
                    ),
                  ),
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
