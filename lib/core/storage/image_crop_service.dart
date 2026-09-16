import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/camera/models/camera_state.dart';

/// Center-crops a JPEG captured photo to the target [CameraAspectRatio].
/// Returns the original [sourcePath] unchanged when [ratio] is [CameraAspectRatio.full].
/// Otherwise writes a new JPEG to the app temp directory and returns its path.
Future<String> cropToAspectRatio(
  String sourcePath,
  CameraAspectRatio ratio,
) async {
  // Nothing to do for full-sensor mode
  if (ratio == CameraAspectRatio.full || ratio.ratio == null) {
    return sourcePath;
  }

  final bytes = await File(sourcePath).readAsBytes();
  final original = img.decodeImage(bytes);
  if (original == null) return sourcePath; // fallback: keep original

  final srcW = original.width;
  final srcH = original.height;
  final targetRatio = ratio.ratio!;

  int cropW, cropH;
  // Determine the largest centered rectangle at the target ratio that fits
  // within the source image dimensions.
  if (srcW / srcH > targetRatio) {
    // Source is wider than target — crop width
    cropH = srcH;
    cropW = (srcH * targetRatio).round();
  } else {
    // Source is taller than target — crop height
    cropW = srcW;
    cropH = (srcW / targetRatio).round();
  }

  final offsetX = (srcW - cropW) ~/ 2;
  final offsetY = (srcH - cropH) ~/ 2;

  final cropped = img.copyCrop(
    original,
    x: offsetX,
    y: offsetY,
    width: cropW,
    height: cropH,
  );

  final tmpDir = await getTemporaryDirectory();
  final outPath = p.join(
    tmpDir.path,
    'crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  await File(outPath).writeAsBytes(img.encodeJpg(cropped, quality: 92));
  return outPath;
}
