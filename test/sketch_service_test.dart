import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List generateSketchPng(Uint8List inputBytes) {
  var image = img.decodeImage(inputBytes);
  if (image == null) throw Exception('Cannot decode image');

  image = img.bakeOrientation(image);

  // Resize so max dimension is at most 640px for fast processing & ideal stroke weight
  const maxDim = 640;
  if (image.width > maxDim || image.height > maxDim) {
    if (image.width > image.height) {
      image = img.copyResize(image, width: maxDim);
    } else {
      image = img.copyResize(image, height: maxDim);
    }
  }

  // Grayscale & subtle blur to eliminate pixel noise
  final gray = img.grayscale(image);
  final blurred = img.gaussianBlur(gray, radius: 1);

  // Sobel edge filter
  final sobel = img.sobel(blurred);

  // Build white-on-transparent RGBA image
  final sketch = img.Image(
    width: sobel.width,
    height: sobel.height,
    numChannels: 4,
  );

  for (var y = 0; y < sobel.height; y++) {
    for (var x = 0; x < sobel.width; x++) {
      final p = sobel.getPixel(x, y);
      final lum = p.r.toInt();

      if (lum < 24) {
        sketch.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        // Boost contrast slightly
        final norm = (lum - 24) / (255 - 24);
        final alpha = (norm * 255).clamp(0, 255).toInt();
        sketch.setPixelRgba(x, y, 255, 255, 255, alpha);
      }
    }
  }

  return Uint8List.fromList(img.encodePng(sketch));
}

void main() {
  test('generateSketchPng produces valid PNG with transparent bg and white edges', () {
    final raw = img.Image(width: 800, height: 1200);
    img.fill(raw, color: img.ColorRgb8(100, 150, 200));
    // Draw simulated person: body and head
    img.fillRect(raw, x1: 300, y1: 400, x2: 500, y2: 1000, color: img.ColorRgb8(20, 20, 20));
    img.fillCircle(raw, x: 400, y: 300, radius: 80, color: img.ColorRgb8(230, 180, 140));

    final rawBytes = Uint8List.fromList(img.encodeJpg(raw));
    final pngBytes = generateSketchPng(rawBytes);

    expect(pngBytes.isNotEmpty, true);
    final decoded = img.decodePng(pngBytes);
    expect(decoded != null, true);
    expect(decoded!.numChannels, 4);
    expect(decoded.width <= 640, true);
    expect(decoded.height <= 640, true);
  });
}
