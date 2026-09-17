import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Service for converting pose photos into artistic white-on-transparent line sketches.
class PoseSketchService {
  const PoseSketchService._();

  /// Runs the sketch generation pipeline in a background isolate to keep UI responsive.
  static Future<Uint8List?> generateSketch(Uint8List inputBytes) async {
    try {
      return await Isolate.run(() => _processSketchSync(inputBytes));
    } catch (e) {
      debugPrint('PoseSketchService error: $e');
      return null;
    }
  }

  /// Pure Dart image processing pipeline. Runs synchronously inside the isolate.
  static Uint8List? _processSketchSync(Uint8List inputBytes) {
    var image = img.decodeImage(inputBytes);
    if (image == null) return null;

    image = img.bakeOrientation(image);

    // Downscale so max dimension is 640px. This yields sub-100ms processing
    // and optimal stroke thickness relative to the mobile display.
    const maxDim = 640;
    if (image.width > maxDim || image.height > maxDim) {
      if (image.width > image.height) {
        image = img.copyResize(image, width: maxDim);
      } else {
        image = img.copyResize(image, height: maxDim);
      }
    }

    // Convert to grayscale and apply gentle blur to remove camera noise/grain
    final gray = img.grayscale(image);
    final blurred = img.gaussianBlur(gray, radius: 1);

    // Sobel gradient operator extracts body contours and gesture lines
    final sobel = img.sobel(blurred);

    // Construct white-on-transparent RGBA image
    final sketch = img.Image(
      width: sobel.width,
      height: sobel.height,
      numChannels: 4,
    );

    for (var y = 0; y < sobel.height; y++) {
      for (var x = 0; x < sobel.width; x++) {
        final p = sobel.getPixel(x, y);
        final lum = p.r.toInt();

        // Suppress background gradients/noise below threshold
        if (lum < 24) {
          sketch.setPixelRgba(x, y, 0, 0, 0, 0);
        } else {
          // Normalize alpha to highlight contours cleanly
          final norm = (lum - 24) / (255 - 24);
          final alpha = (norm * 255).clamp(0, 255).toInt();
          sketch.setPixelRgba(x, y, 255, 255, 255, alpha);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(sketch));
  }
}
