import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/camera/models/camera_state.dart';

Uint8List? _cachedWatermarkBytes;

Future<Uint8List?> _loadWatermarkBytes() async {
  if (_cachedWatermarkBytes != null) return _cachedWatermarkBytes;
  try {
    final byteData =
        await rootBundle.load('assets/splash/transparent-image.png');
    _cachedWatermarkBytes = byteData.buffer.asUint8List();
    return _cachedWatermarkBytes;
  } catch (e) {
    debugPrint('Failed to load watermark asset: $e');
    return null;
  }
}

/// Center-crops a JPEG captured photo to the target [CameraAspectRatio].
/// Preserved for backward compatibility.
Future<String> cropToAspectRatio(
  String sourcePath,
  CameraAspectRatio ratio,
) {
  return processCapturedPhoto(
    sourcePath: sourcePath,
    ratio: ratio,
    addWatermark: false,
  );
}

/// Processes a captured photo in a background isolate:
/// 1. Bakes EXIF orientation into the image buffer.
/// 2. Center-crops to the selected aspect ratio (if not full).
/// 3. Stamps the crisp [assets/splash/transparent-image.png] brand watermark
///    in the bottom-right corner with bicubic resampling if [addWatermark] is enabled.
/// 4. Encodes and writes to a temporary file at high JPEG quality (96).
///
/// Runs entirely in [Isolate.run] to ensure zero UI stutter or shutter delay.
Future<String> processCapturedPhoto({
  required String sourcePath,
  required CameraAspectRatio ratio,
  bool addWatermark = true,
  Uint8List? explicitWatermarkBytes,
}) async {
  final needsCrop = ratio != CameraAspectRatio.full && ratio.ratio != null;
  if (!needsCrop && !addWatermark) {
    return sourcePath;
  }

  final watermarkBytes = explicitWatermarkBytes ??
      (addWatermark ? await _loadWatermarkBytes() : null);
  final fileBytes = await File(sourcePath).readAsBytes();

  try {
    final processedBytes = await Isolate.run(() {
      var photo = img.decodeImage(fileBytes);
      if (photo == null) return null;
      photo = img.bakeOrientation(photo);

      if (needsCrop) {
        final srcW = photo.width;
        final srcH = photo.height;
        final targetRatio = ratio.ratio!;
        int cropW, cropH;
        if (srcW / srcH > targetRatio) {
          cropH = srcH;
          cropW = (srcH * targetRatio).round();
        } else {
          cropW = srcW;
          cropH = (srcW / targetRatio).round();
        }
        final offsetX = (srcW - cropW) ~/ 2;
        final offsetY = (srcH - cropH) ~/ 2;
        photo = img.copyCrop(
          photo,
          x: offsetX,
          y: offsetY,
          width: cropW,
          height: cropH,
        );
      }

      if (addWatermark && watermarkBytes != null) {
        final watermark = img.decodePng(watermarkBytes);
        if (watermark != null) {
          // Sharp brand watermark sized to ~11% of photo width, clamped [80, 320]
          final targetWidth = (photo.width * 0.11).round().clamp(80, 320);
          final targetHeight =
              (targetWidth * (watermark.height / watermark.width)).round();
          final resizedWatermark = img.copyResize(
            watermark,
            width: targetWidth,
            height: targetHeight,
            interpolation: img.Interpolation.cubic, // Bicubic for razor-sharp vector/logo downscaling
          );

          // 2.5% margin from bottom-right corner
          final padding = (photo.width * 0.025).round().clamp(16, 60);
          final posX = photo.width - resizedWatermark.width - padding;
          final posY = photo.height - resizedWatermark.height - padding;

          img.compositeImage(
            photo,
            resizedWatermark,
            dstX: posX,
            dstY: posY,
          );
        }
      }

      // Quality 96 for crystal clear output without compression noise
      return Uint8List.fromList(img.encodeJpg(photo, quality: 96));
    });

    if (processedBytes == null) return sourcePath;

    final tmpDir = await getTemporaryDirectory();
    final outPath = p.join(
      tmpDir.path,
      'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(outPath).writeAsBytes(processedBytes);
    return outPath;
  } catch (e) {
    debugPrint('processCapturedPhoto error: $e');
    return sourcePath;
  }
}
