import 'package:strict_config/strict_config.dart';
import 'package:test/test.dart';

//================================================================

void main() {
  group('basic functionality', () {
    test('test', () {
      final cfg = ConfigMap('x: [1, 2, 3]');
      final values = cfg.integers('x');
      expect(values.length, equals(3));
      expect(values, equals([1, 2, 3]));
    });

    test('empty list: accepted by default', () {
      final cfg = ConfigMap('x: []');
      final values = cfg.integers('x');
      expect(values.length, equals(0));
    });

    test('empty list: allowEmpty=false', () {
      final cfg = ConfigMap('x: []');
      expect(() => cfg.integers('x', allowEmptyList: false),
          throwsA(TypeMatcher<ConfigExceptionValueEmptyList>()));
    });

    test('mixed member type rejected', () {
      final cfg = ConfigMap('x: [42, "not an integer"]');
      expect(() => cfg.integers('x', allowEmptyList: false),
          throwsA(TypeMatcher<ConfigExceptionValue>()));
    });
  });

  group('range check', () {
    test('in range: $num', () {
      final cfg = ConfigMap('x: [32, 33, 211, 212]');
      final values = cfg.integers('x', min: 32, max: 212);
      expect(values.length, equals(4));
    });

    test('out of range: $num', () {
      final cfg = ConfigMap('x: [32, 33, 211, -459]');
      expect(() => cfg.integers('x', min: 32, max: 212),
          throwsA(TypeMatcher<ConfigExceptionValue>()));
    });
  });
}
