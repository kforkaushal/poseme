import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide OverlayState;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/image/pose_sketch_cache.dart';
import '../../pose_library/models/pose_reference.dart';
import '../providers/overlay_provider.dart';

/// Renders an artistic white-on-transparent line sketch of the pose.
///
/// If the sketch is being processed for the first time, it temporarily displays
/// the grayscale photo with a subtle loader so the user never sees a blank screen,
/// then smoothly transitions to the sketch once ready.
class SketchOverlay extends ConsumerStatefulWidget {
  final PoseReference pose;

  const SketchOverlay({
    super.key,
    required this.pose,
  });

  @override
  ConsumerState<SketchOverlay> createState() => _SketchOverlayState();
}

class _SketchOverlayState extends ConsumerState<SketchOverlay> {
  Uint8List? _sketchBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSketch();
    });
  }

  @override
  void didUpdateWidget(SketchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose.id != widget.pose.id) {
      setState(() {
        _sketchBytes = null;
      });
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadSketch();
      });
    }
  }

  Future<void> _loadSketch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    ref.read(overlayProvider.notifier).setSketchProcessing(true);

    try {
      final bytes = await PoseSketchCache.instance.getSketch(widget.pose);
      if (!mounted) return;

      if (bytes == null || bytes.isEmpty) {
        ref.read(overlayProvider.notifier).setSketchFailed(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't generate sketch — using Photo mode",
              style: TextStyle(fontSize: 13),
            ),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _sketchBytes = bytes;
          _isLoading = false;
        });
        ref.read(overlayProvider.notifier).setSketchProcessing(false);
      }
    } catch (e) {
      debugPrint('SketchOverlay error: $e');
      if (mounted) {
        ref.read(overlayProvider.notifier).setSketchFailed(true);
      }
    }
  }

  Widget _buildFallbackPhoto() {
    Widget img;
    if (widget.pose.isLocalImage && widget.pose.localFilePath != null) {
      img = Image.file(
        File(widget.pose.localFilePath!),
        fit: BoxFit.contain,
      );
    } else if (widget.pose.isNetworkImage) {
      img = CachedNetworkImage(
        imageUrl: widget.pose.networkOverlayUrl!,
        fit: BoxFit.contain,
      );
    } else {
      img = Image.asset(
        widget.pose.assetPath,
        fit: BoxFit.contain,
      );
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(AppTheme.grayscaleMatrix),
      child: Opacity(
        opacity: 0.35,
        child: img,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sketchBytes != null) {
      return Image.memory(
        _sketchBytes!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      );
    }

    // While processing, show fallback photo with a subtle spinner
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildFallbackPhoto(),
        if (_isLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
      ],
    );
  }
}
