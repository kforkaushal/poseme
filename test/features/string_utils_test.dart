import 'package:flutter_test/flutter_test.dart';
import 'package:poseme/core/utils/string_utils.dart';

void main() {
  group('String Utils Tests', () {
    test('toTitleCase normalizes uppercase, lowercase, and mixed casing', () {
      expect(toTitleCase('DAVID BARAHONA'), 'David Barahona');
      expect(toTitleCase('the Amritdev'), 'The Amritdev');
      expect(toTitleCase('rubn nava'), 'Rubn Nava');
      expect(toTitleCase('jimmy elizarraras'), 'Jimmy Elizarraras');
      expect(toTitleCase(''), '');
      expect(toTitleCase('A'), 'A');
    });
  });
}
