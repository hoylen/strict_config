import 'package:strict_config/strict_config.dart';
import 'package:test/test.dart';

//================================================================

const name = 'string_example';

String callString(ConfigMap cfg, bool kws, bool ab, bool ae) =>
    cfg.string(name, keepWhitespace: kws, allowBlank: ab, allowEmpty: ae);

final callingTheString = callString; // alias with long name so code line up

final rejected = throwsA(TypeMatcher<ConfigExceptionValue>());

const cleanW = false; // default
const keepWS = true;

const noBlank = false; // default
const blankOk = true;

const noEmpty = false; // default
const emptyOk = true;

//================================================================

void main() {
  group('optional', () {
    test('value exists', () {
      final cfg = ConfigMap('$name: "has value"');

      expect(cfg.stringOptional(name), equals('has value'));
      expect(cfg.string(name, defaultValue: 'default'), equals('has value'));
      expect(cfg.string(name), equals('has value'));
    });

    test('value missing', () {
      final cfg = ConfigMap('');

      expect(cfg.stringOptional(name), isNull);
      expect(cfg.string(name, defaultValue: 'default'), equals('default'));
      expect(() => cfg.string(name),
          throwsA(TypeMatcher<ConfigExceptionKeyMissing>()));
    });
  });

  group('whitespace behaviour', () {
    const str = 'x';
    group('input without any extra whitespace "$str"', () {
      final cf = ConfigMap('$name: "$str"');

      test('remove extra whitespace', () {
        expect(callingTheString(cf, cleanW, noBlank, noEmpty), equals('x'));
        expect(callingTheString(cf, cleanW, noBlank, emptyOk), equals('x'));
        expect(callingTheString(cf, cleanW, blankOk, noEmpty), equals('x'));
        expect(callingTheString(cf, cleanW, blankOk, emptyOk), equals('x'));
      });

      test('keep whitespace', () {
        expect(callingTheString(cf, keepWS, noBlank, noEmpty), equals('x'));
        expect(callingTheString(cf, keepWS, noBlank, emptyOk), equals('x'));
        expect(callingTheString(cf, keepWS, blankOk, noEmpty), equals('x'));
        expect(callingTheString(cf, keepWS, blankOk, emptyOk), equals('x'));
      });
    });

    for (final input in ['  x y \t', '\t x \t y', 'x\ty  ', 'x \t y']) {
      group('input with extra whitespace', () {
        assert(input.startsWith(' ') ||
            input.startsWith('\t') ||
            input.endsWith(' ') ||
            input.endsWith('\t') ||
            RegExp(r'[ \t\n\r]{2}').hasMatch(input));

        final cf = ConfigMap('$name: "$input"');

        test('remove extra whitespace', () {
          expect(callingTheString(cf, cleanW, noBlank, noEmpty), equals('x y'));
          expect(callingTheString(cf, cleanW, noBlank, emptyOk), equals('x y'));
          expect(callingTheString(cf, cleanW, blankOk, noEmpty), equals('x y'));
          expect(callingTheString(cf, cleanW, blankOk, emptyOk), equals('x y'));
        });

        test('keep whitespace', () {
          expect(callingTheString(cf, keepWS, noBlank, noEmpty), equals(input));
          expect(callingTheString(cf, keepWS, noBlank, emptyOk), equals(input));
          expect(callingTheString(cf, keepWS, blankOk, noEmpty), equals(input));
          expect(callingTheString(cf, keepWS, blankOk, emptyOk), equals(input));
        });
      });
    }

    for (final blk in ['\u0020', '\u0020\u0020', '\t', '\t\t', '\t\u0020\t']) {
      group('input blank', () {
        assert(blk.isNotEmpty);
        assert(RegExp(r'^[ \t]+').hasMatch(blk));

        final cfg = ConfigMap('$name: "$blk"');

        test('remove extra whitespace', () {
          expect(() => callString(cfg, cleanW, noBlank, noEmpty), rejected);
          expect(callingTheString(cfg, cleanW, noBlank, emptyOk), equals(''));
          expect(() => callString(cfg, cleanW, blankOk, noEmpty), rejected);
          expect(callingTheString(cfg, cleanW, blankOk, emptyOk), equals(''));
        });

        test('keep whitespace', () {
          expect(() => callString(cfg, keepWS, noBlank, noEmpty), rejected);
          expect(() => callString(cfg, keepWS, noBlank, emptyOk), rejected);
          expect(callingTheString(cfg, keepWS, blankOk, noEmpty), equals(blk));
          expect(callingTheString(cfg, keepWS, blankOk, emptyOk), equals(blk));
        });
      });
    }

    const emptyString = '';
    group('input empty "$emptyString"', () {
      assert(emptyString.isEmpty);

      final cfg = ConfigMap('$name: "$emptyString"');

      test('remove extra whitespace', () {
        expect(() => callString(cfg, cleanW, noBlank, noEmpty), rejected);
        expect(callingTheString(cfg, cleanW, noBlank, emptyOk), equals(''));
        expect(() => callString(cfg, cleanW, blankOk, noEmpty), rejected);
        expect(callingTheString(cfg, cleanW, blankOk, emptyOk), equals(''));
      });

      test('keep whitespace', () {
        expect(() => callString(cfg, keepWS, noBlank, noEmpty), rejected);
        expect(callingTheString(cfg, keepWS, noBlank, emptyOk), equals(''));
        expect(() => callString(cfg, keepWS, blankOk, noEmpty), rejected);
        expect(callingTheString(cfg, keepWS, blankOk, emptyOk), equals(''));
      });
    });
  });

  group('permitted', () {
    const goodValues = ['foo', 'bar', 'baz'];

    group('correct values accepted', () {
      for (final value in goodValues) {
        test('correct value "$value"', () {
          final cfg1 = ConfigMap('$name: "$value"');
          expect(cfg1.string(name, permitted: goodValues), equals(value));
        });
      }

      test('allowEmpty overrides', () {
        // Even though the empty string is not one of the permitted values,
        // it is accepted since allowEmpty is true.
        final cfg1 = ConfigMap('$name: ""');
        expect(cfg1.string(name, permitted: goodValues, allowEmpty: true),
            equals(''));
      });

      // Note: behaviour is undefined if permitted used with allowBlank,
      // so it is not tested.
    });

    group('wrong values rejected', () {
      for (final value in ['Foo', 'BAR', 'baZ', 'something else']) {
        test('wrong "$value"', () {
          final cfg2 = ConfigMap('$name: "Foo"');
          expect(() => cfg2.string(name, permitted: goodValues), rejected);
        });
      }

      final goodValuesWithEmptyAndTab = [...goodValues, '', '\t'];

      test('allowEmpty overrides', () {
        // Even though the empty string is one of the permitted values,
        // it is rejected since allowEmpty is false.
        // It does not make sense to put empty strings in the permitted values.
        final cfg1 = ConfigMap('$name: ""');
        expect(
            () => cfg1.string(name,
                permitted: goodValuesWithEmptyAndTab, allowEmpty: false),
            rejected);
      });

      test('allowBlank overrides', () {
        // Even though the string with a single tab character is one of the
        // permitted values, it is rejected since allowBlank is false.
        // It does not make sense to put blank strings in the permitted values.
        final cfg1 = ConfigMap('$name: "\t"');
        expect(
            () => cfg1.string(name,
                permitted: goodValuesWithEmptyAndTab, allowBlank: false),
            rejected);
      });
    });
  });
}
