import 'package:strict_config/strict_config.dart';
import 'package:test/test.dart';

//================================================================

final badFormat = throwsA(const TypeMatcher<ConfigExceptionFormat>());

final missingKey = throwsA(const TypeMatcher<ConfigExceptionKeyMissing>());

//================================================================

void main() {
  group('bad keys', () {
    test('non-string keys', () {
      // YAML permits non-string values to be keys, but strict_config does not.

      for (final text in [
        'true: "boolean key not allowed"',
        'false: "boolean key not allowed"',
        '42: "integer key not allowed"'
      ]) {
        // Creating a config will always succeed. It is only when the keys are
        // all examined that invalid keys are detected. This is deliberate
        // behaviour to allow programs to deliberately ignore extra content in
        // the config they don't use, but might be used by other programs that
        // use the same config.

        final cfg = ConfigMap(text);

        // These are the two methods that cause all the keys to be examined.

        expect(cfg.keys, badFormat);

        expect(cfg.unusedKeysCheck, badFormat);
      }
    });

    test('duplicate keys', () {
      expect(() => ConfigMap('a: 1\nb: 2\na: 3'), badFormat);
    });
  });

  test('mandatory extractors throws exception if key is missing', () {
    final cfg = ConfigMap('a: b');
    expect(() => cfg.boolean('x'), missingKey);
    expect(() => cfg.integer('x'), missingKey);
    expect(() => cfg.string('x'), missingKey);
    expect(() => cfg.booleans('x'), missingKey);
    expect(() => cfg.integers('x'), missingKey);
    expect(() => cfg.strings('x'), missingKey);
    expect(() => cfg.maps('x'), missingKey);
  });

  test('mandatory extractors with defaults returns it if key is missing', () {
    final cfg = ConfigMap('a: b');
    expect(cfg.boolean('x', defaultValue: false), equals(false));
    expect(cfg.boolean('x', defaultValue: true), equals(true));
    expect(cfg.integer('x', defaultValue: 0), equals(0));
    expect(cfg.integer('x', defaultValue: 42), equals(42));
    expect(cfg.integer('x', defaultValue: -1), equals(-1));
    expect(cfg.string('x', defaultValue: 'foobar'), equals('foobar'));
  });

  test('optional extractors returns null if key is missing', () {
    final cfg = ConfigMap('a: b');
    expect(cfg.booleanOptional('x'), isNull);
    expect(cfg.integerOptional('x'), isNull);
    expect(cfg.stringOptional('x'), isNull);
    expect(cfg.booleansOptional('x'), isNull);
    expect(cfg.integersOptional('x'), isNull);
    expect(cfg.stringsOptional('x'), isNull);
    expect(cfg.mapsOptional('x'), isNull);
  });
}
