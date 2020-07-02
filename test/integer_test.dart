import 'package:strict_config/strict_config.dart';
import 'package:test/test.dart';

//================================================================

final badFormat = throwsA(TypeMatcher<ConfigExceptionFormat>());

final missingKey = throwsA(TypeMatcher<ConfigExceptionKeyMissing>());

final badValue = throwsA(TypeMatcher<ConfigExceptionValue>());

//================================================================

void main() {
  group('range check', () {
    for (final num in [32, 33, 211, 212]) {
      test('in range: $num', () {
        final cfg = ConfigMap('x: $num');

        expect(cfg.integer('x', min: 32, max: 212), equals(num));
      });
    }

    for (final num in [0, 30, 31, 213, 214, -459]) {
      test('out of range: $num', () {
        final cfg = ConfigMap('x: $num');

        expect(() => cfg.integer('x', min: 32, max: 212), badValue);
      });
    }

    for (final num in [0, 30, 31, 213, 214, -459]) {
      test('default out of range: $num', () {
        final cfg = ConfigMap('');
        expect(() => cfg.integer('x', min: 32, max: 212, defaultValue: num),
            badValue);
      });
    }
  });
}
