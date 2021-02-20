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
  ConfigExceptionValue(String message, String path, String key, this.value)
      : super(message, path, key);

  /// String representation of the value that caused the exception.

  final String value;

  @override
  String toString() => '${super.toString()}: $value';
}

//################################################################
/// Indicates the value is a list, but it is empty.
///
/// This is thrown by the list extraction methods, when their _allowEmpty_
/// parameter is true and the value in the config is an empty list.

class ConfigExceptionValueEmptyList extends ConfigExceptionValue {
  ConfigExceptionValueEmptyList(String path, String key)
      : super('list is empty', path, key, '[]');
}
