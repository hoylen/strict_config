import 'package:strict_config/strict_config.dart';
import 'package:test/test.dart';

//================================================================

final badFormat = throwsA(TypeMatcher<ConfigExceptionFormat>());

final missingKey = throwsA(TypeMatcher<ConfigExceptionKeyMissing>());

final badValue = throwsA(TypeMatcher<ConfigExceptionValue>());

//================================================================

void main() {
  test('false', () {
    final cfg = ConfigMap('x: false');
    expect(cfg.boolean('x'), isFalse);
  });
  test('true', () {
    final cfg = ConfigMap('x: true');
    expect(cfg.boolean('x'), isTrue);
  });

  test('default false: used if key does not exist', () {
    final cfg = ConfigMap('');
    expect(cfg.boolean('x', defaultValue: false), isFalse);
  });
  test('default false: ignored if key exists', () {
    final cfg = ConfigMap('x: true');
    expect(cfg.boolean('x', defaultValue: false), isTrue);
  });

  test('default true: used if key does not exist', () {
    final cfg = ConfigMap('');
    expect(cfg.boolean('x', defaultValue: true), isTrue);
  });
  test('default true: ignored if key exists', () {
    final cfg = ConfigMap('x: false');
    expect(cfg.boolean('x', defaultValue: true), isFalse);
  });

  test('optional: false', () {
    final cfg = ConfigMap('x: false');
    expect(cfg.booleanOptional('x'), isFalse);
  });
  test('optional: true', () {
    final cfg = ConfigMap('x: true');
    expect(cfg.booleanOptional('x'), isTrue);
  });
  test('optional: missing', () {
    final cfg = ConfigMap('');
    expect(cfg.booleanOptional('x'), isNull);
  });
}
