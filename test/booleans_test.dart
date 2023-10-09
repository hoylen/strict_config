import 'package:strict_config/strict_config.dart';
import 'package:test/test.dart';

//================================================================
// Lists of booleans have been implemented so the library has list extractors
// corresponding to every scalar extractor. Real applications will probably
// never need a list of booleans!

void main() {
  group('basic functionality', () {
    test('test', () {
      final cfg = ConfigMap('x: [true, false, true]');
      final values = cfg.booleans('x');
      expect(values.length, equals(3));
      expect(values, equals([true, false, true]));
    });

    test('empty list: accepted by default', () {
      final cfg = ConfigMap('x: []');
      final values = cfg.booleans('x');
      expect(values.length, equals(0));
    });

    test('empty list: allowEmpty=false', () {
      final cfg = ConfigMap('x: []');
      expect(() => cfg.booleans('x', allowEmptyList: false),
          throwsA(const TypeMatcher<ConfigExceptionValueEmptyList>()));
    });

    test('mixed member type rejected', () {
      final cfg = ConfigMap('x: [true, "not a boolean"]');
      expect(() => cfg.integers('x', allowEmptyList: false),
          throwsA(const TypeMatcher<ConfigExceptionValue>()));
    });
  });
}
