import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List processPhotoSync({
  required Uint8List sourceBytes,
  required double? targetAspectRatio,
  required Uint8List? watermarkBytes,
  bool addWatermark = true,
}) {
  var photo = img.decodeImage(sourceBytes);
  if (photo == null) throw Exception('Cannot decode photo');
  photo = img.bakeOrientation(photo);

  if (targetAspectRatio != null) {
    final srcW = photo.width;
    final srcH = photo.height;
    int cropW, cropH;
    if (srcW / srcH > targetAspectRatio) {
      cropH = srcH;
      cropW = (srcH * targetAspectRatio).round();
    } else {
      cropW = srcW;
      cropH = (srcW / targetAspectRatio).round();
    }
    final offsetX = (srcW - cropW) ~/ 2;
    final offsetY = (srcH - cropH) ~/ 2;
    photo = img.copyCrop(photo, x: offsetX, y: offsetY, width: cropW, height: cropH);
  }

  if (addWatermark && watermarkBytes != null) {
    final watermark = img.decodePng(watermarkBytes);
    if (watermark != null) {
      final targetSize = (photo.width * 0.075).round().clamp(48, 180);
      final resizedWatermark = img.copyResize(watermark, width: targetSize, height: targetSize);
      final padding = (photo.width * 0.025).round().clamp(12, 60);
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

  return Uint8List.fromList(img.encodeJpg(photo, quality: 92));
}

void main() {
  test('processPhotoSync crops and applies watermark correctly', () {
    final raw = img.Image(width: 1200, height: 1600);
    img.fill(raw, color: img.ColorRgb8(30, 40, 50));
    final rawBytes = Uint8List.fromList(img.encodeJpg(raw));

    final watermarkBytes = File('assets/splash/transparent-image.png').readAsBytesSync();

    // Process with 1:1 aspect ratio + watermark
    final processedBytes = processPhotoSync(
      sourceBytes: rawBytes,
      targetAspectRatio: 1.0,
      watermarkBytes: watermarkBytes,
      addWatermark: true,
    );

    final resultImg = img.decodeJpg(processedBytes);
    expect(resultImg != null, true);
    expect(resultImg!.width, 1200);
    expect(resultImg.height, 1200); // 1:1 square crop
  });
}
