import 'package:strict_config/strict_config.dart';
import 'package:test/test.dart';

//================================================================

void main() {
  group('basic functionality', () {
    test('test', () {
      final cfg = ConfigMap('x: ["foo", "bar", "baz"]');
      final values = cfg.strings('x');
      expect(values.length, equals(3));
      expect(values, equals(['foo', 'bar', 'baz']));
    });

    test('empty list: accepted by default', () {
      final cfg = ConfigMap('x: []');
      final values = cfg.strings('x');
      expect(values.length, equals(0));
    });

    test('empty list: allowEmptyList=false', () {
      final cfg = ConfigMap('x: []');
      expect(() => cfg.strings('x', allowEmptyList: false),
          throwsA(TypeMatcher<ConfigExceptionValueEmptyList>()));
    });

    test('mixed member type rejected', () {
      final cfg = ConfigMap('x: ["foo", 42]');
      expect(() => cfg.strings('x', allowEmptyList: false),
          throwsA(TypeMatcher<ConfigExceptionValue>()));
    });
  });

  // TODO: add tests using keepWhitespace, allowEmpty and allowBlank

  group('permitted', () {
    const goodValues = ['foo', 'bar', 'baz'];

    test('correct', () {
      final cfg = ConfigMap('x: [baz, "bar ", foo, "foo", bar, " baz "]');
      final values = cfg.strings('x', permitted: goodValues);
      expect(values.length, equals(6));
    });

    test('incorrect', () {
      final cfg = ConfigMap('x: [foo, something-unexpected, baz]');
      expect(() => cfg.strings('x', permitted: goodValues),
          throwsA(TypeMatcher<ConfigExceptionValue>()));
    });
  });
}
