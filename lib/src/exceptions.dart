part of strict_config;

//################################################################
/// Base class for all config exceptions.

abstract class ConfigException implements Exception {
  ConfigException(this.message);
  final String message;

  @override
  String toString() => message;
}

//################################################################
/// Indicates a syntax error in the config.

class ConfigExceptionFormat extends ConfigException {
  ConfigExceptionFormat(this.details) : super('invalid format');

  /// Extra details about the error.

  final String details;

  @override
  String toString() => '$message\n$details';
}

//################################################################
/// Indicates a problem with a config item.

class ConfigExceptionKey extends ConfigException {
  ConfigExceptionKey(String message, this.path, this.key) : super(message);

  /// The key that caused the exception.

  final String key;

  /// Path to the key that caused the exception.
  ///
  /// Null means the key is at the top-level of the config.

  final String path;

  @override
  String toString() => '$message: ${path.isEmpty ? '' : '$path/'}$key';
}

//################################################################
/// Indicates a key is missing.

class ConfigExceptionKeyMissing extends ConfigExceptionKey {
  ConfigExceptionKeyMissing(String path, String k) : super('missing', path, k);
}

//################################################################
/// Indicates a key is unexpected.

class ConfigExceptionKeyUnexpected extends ConfigExceptionKey {
  ConfigExceptionKeyUnexpected(String path, String k)
      : super('unexpected', path, k);
}

//################################################################
/// Indicates a problem with the value associated with a config item.

class ConfigExceptionValue extends ConfigExceptionKey {
  ConfigExceptionValue(String message, String path, String key, [this.value])
      : super(message, path, key);

  /// The value that caused the exception.
  ///
  /// Null means there is no value to display. For example, this is used when
  /// the message is sufficient (e.g. an error about an empty string does not
  /// need to show the empty string value).

  final Object? value;

  @override
  String toString() {
    String text;

    final v = value;
    if (v is String) {
      var str = v
          .replaceAll('\\', '\\\\')
          .replaceAll('\t', '\\t')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r')
          .replaceAll('"', '\\"');
      text = ': "$str"';
    } else if (v != null) {
      text = ': $v';
    } else {
      text = '';
    }

    return '${super.toString()}$text';
  }
}

//################################################################
/// Indicates the value is a list, but it is empty.
///
/// This is thrown by the list extraction methods, when their _allowEmpty_
/// parameter is true and the value in the config is an empty list.

class ConfigExceptionValueEmptyList extends ConfigExceptionValue {
  ConfigExceptionValueEmptyList(String path, String key)
      : super('list is empty', path, key);
}
