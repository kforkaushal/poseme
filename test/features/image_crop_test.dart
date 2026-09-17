import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('img.bakeOrientation exists and functions', () {
    final image = img.Image(width: 100, height: 100);
    final baked = img.bakeOrientation(image);
    expect(baked, isNotNull);
  });
}
