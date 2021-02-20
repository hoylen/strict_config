part of strict_config;

//################################################################
/// Possible types returned by [ConfigMap.type].
///
/// These correspond to all the extractor methods on a [ConfigMap], plus two
/// special values: _unavailable_ and _unknownList_.

enum ConfigType {
  unavailable,
  unknownList,
  boolean,
  booleans,
  integer,
  integers,
  map,
  maps,
  string,
  strings,
}

//################################################################
/// Represents a config item with keys and values.
///
/// Create a config map by passing in config text to the constructor.
/// Config maps can also be obtained by extracting it from an existing config
/// map using one of the map extraction methods.
///
/// ## Extracting values
///
/// Values can be extracted by passing the name of the key to the extraction
/// methods.
///
/// Extraction methods for mandatory scalar values:
///
/// - [boolean]
/// - [integer]
/// - [string]
///
/// Extraction methods for optional scalar values (returns null if the key
/// does not exist):
///
/// - [booleanOptional]
/// - [integerOptional]
/// - [stringOptional]
///
/// Extraction methods for lists of scalars (by default empty lists are
/// permitted):
///
/// - [booleans]
/// - [integers]
/// - [strings]
///
/// Extraction methods for optional lists of scalars:
///
/// - [booleansOptional]
/// - [integersOptional]
/// - [stringsOptional]
///
/// Values which are config maps, or lists of config maps, are extracted using:
///
/// - [map]
/// - [mapOptional]
/// - [maps]
/// - [mapsOptional]
///
/// ## Identifying unexpected keys
///
/// After using the extraction methods, the [unusedKeysCheck] method can be used
/// to check for keys which have not been extracted, which is usually identifies
/// an invalid config.
///
/// Alternatively, the permitted keys can be passed to the [keys] method.
///
/// ## Dynamic processing
///
/// A list of all the keys can be obtained with the [keys]
/// method and their value identified with the [type] method.

class ConfigMap {
  //================================================================
  // Constructors

  //----------------------------------------------------------------
  /// Parses text into a config map.
  ///
  /// The [text] is usually read from a config file, but can be obtained
  /// from other sources too. Since the strict_config config format is a subset
  /// of YAML, the text must be valid YAML.
  ///
  /// This implementation may accept YAML that is not _strict_config_ config
  /// format.
  /// This will not cause any problems unless that part of the YAML is examined.
  /// This allows the YAML to contain values that are used by other programs,
  /// but are not examined when it is used as a strict_config config. This is an
  /// implementation specific behaviour that is not guaranteed. But if
  /// it changes, it will be a breaking change indicated by incrementing the
  /// package's major version number. Currently, it is unlikely to change, since
  /// it would require a large amount of code to be written.
  ///
  /// Throws a [ConfigExceptionFormat] if the text has a syntax error that
  /// makes it invalid as a strict_config config.

  factory ConfigMap(String text) {
    try {
      final doc = loadYaml(text);
      if (doc is YamlMap) {
        // text contains a YAML map
        return ConfigMap._fromYamlMap('', doc);
      } else if (doc == null) {
        // no YAML data in text: treat as empty map
        return ConfigMap._fromYamlMap('', YamlMap());
      } else {
        throw ConfigExceptionFormat('top-level of config is not a map');
        // e.g. if the text only contains a single integer: it is valid YAML,
        // but not very useful as a config.
      }
    } on YamlException catch (e) {
      throw ConfigExceptionFormat(e.toString());
    }
  }

  //----------------------------------------------------------------
  /// Constructor for internal use only.
  ///
  /// Used by [configMap] and [configMapList] to convert a YAML map into a
  /// [ConfigMap].

  ConfigMap._fromYamlMap(this.path, this._yamlMap);

  //================================================================
  // Members

  /// Path to the config map.
  ///
  /// The empty string means the config map is the top-level of the config.

  final String path;

  /// Internal YAML map
  ///
  /// Note: the application using this package has no access to the underlying
  /// YAML. As far as it is concerned, it is dealing with a safe_config config
  /// that has no relationship to YAML.

  final YamlMap _yamlMap;

  /// Tracks keys where attempts to retrieve them have been performed.
  ///
  /// Used by [unusedKeysCheck] to determine which keys have not been used.

  final _used = <String>{};
  // This must be a set, because the extractors could be called with the same
  // key more than once and the [keys] method must not return a list with
  // duplicates in it.

  //================================================================
  // Methods for internal use (creates exceptions with the [path] from the map)

  /// Create a [ConfigExceptionKey] populating path from config map.

  ConfigExceptionKey _keyException(String msg, String key) =>
      ConfigExceptionKey(msg, path, key);

  /// Create a [ConfigExceptionKeyMissing] populating path from config map.

  ConfigExceptionKey _keyMissingException(String key) =>
      ConfigExceptionKeyMissing(path, key);

  /// Create a [ConfigExceptionKeyUnexpected] populating path from config map.

  ConfigExceptionKey _keyUnexpectedException(String key) =>
      ConfigExceptionKeyUnexpected(path, key);

  /// Create a [ConfigExceptionValue] populating path from config map.

  ConfigExceptionValue _valueException(String msg, String key, String value) =>
      ConfigExceptionValue(msg, path, key, value);

  /// Create a [ConfigExceptionValueEmptyList] populating path from config map.

  ConfigExceptionValueEmptyList _valueEmptyListException(String key) =>
      ConfigExceptionValueEmptyList(path, key);

  //================================================================
  // Extraction methods

  //----------------------------------------------------------------
  /// Extracts a boolean value.
  ///
  /// Returns the boolean value corresponding to the [key].
  ///
  /// The key must exist in the map or a [defaultValue] is provided.
  /// Otherwise, a [ConfigExceptionKeyMissing] exception will be thrown.
  ///
  /// To allow the key to be missing, use the [booleanOptional] method.
  ///
  /// ### Default value
  ///
  /// When a _defaultValue_ is provided a value is always returned. So while the
  /// key does not have to appear in the config, there is always a value
  /// available. To the config it is optional, but to the program it behaves the
  /// same as a mandatory key.

  bool boolean(String key, {bool? defaultValue}) =>
      _boolean(key, optional: false, defaultValue: defaultValue)!;

  //----------------
  /// Extracts an optional boolean value.
  ///
  /// Returns the boolean value corresponding to the [key] if it exists, or null
  /// if it does not exist. Use the _boolean_ method if the key must always
  /// exist.
  ///
  /// See [boolean] for more details.
  ///
  /// Note: this will return `bool?` once non-nullable Dart is available.

  bool? booleanOptional(String key) =>
      _boolean(key, optional: true, defaultValue: null);

  //----------------
  /// Internal implementation for [boolean] and [booleanOptional].

  bool? _boolean(String key, {required bool optional, bool? defaultValue}) {
    _used.add(key);

    final _value = _yamlMap[key];
    if (_value is bool) {
      return _value;
    } else if (_value == null) {
      if (defaultValue != null) {
        assert(!optional);
        return defaultValue;
      } else if (optional) {
        return null;
      } else {
        throw _keyMissingException(key);
      }
    } else {
      throw _valueException('not true or false', key, _value.toString());
    }
  }

  //----------------------------------------------------------------
  /// Extracts an integer value.
  ///
  /// Returns the integer value corresponding to the [key].
  ///
  /// The key must exist in the map or a [defaultValue] is provided.
  /// Otherwise, a [ConfigExceptionKeyMissing] exception will be thrown.
  ///
  /// To allow the key to be missing, use the [integerOptional] method.
  ///
  /// ### Default value
  ///
  /// When a _defaultValue_ is provided a value is always returned. So while the
  /// key does not have to appear in the config, there is always a value
  /// available. To the config it is optional, but to the program it behaves the
  /// same as a mandatory key.
  ///
  /// ### Range checking
  ///
  /// If either, or both, [min] and [max] are provided, range checking is
  /// performed on the value. If the value is smaller than _min_ or larger
  /// than _max_, a [ConfigExceptionValue] is thrown.

  int integer(String key, {int? defaultValue, int? min, int? max}) =>
      _integer(key,
          defaultValue: defaultValue, min: min, max: max, optional: false)!;

  //----------------
  /// Extracts an optional integer value.
  ///
  /// Returns the integer value corresponding to the [key] if it exists, or null
  /// if it does not exist. Use the _integer_ method if the key must always
  /// exist.
  ///
  /// See [integer] for more details.
  ///
  /// Note: this will return `int?` once non-nullable Dart is available.

  int? integerOptional(String key, {int? min, int? max}) =>
      _integer(key, min: min, max: max, optional: true);

  //----------------
  /// Internal implementation for [integer] and [integerOptional].

  int? _integer(String key,
      {required bool optional, int? defaultValue, int? min, int? max}) {
    _used.add(key);

    // Check default first, even if it won't be used in this instance

    if (min != null && defaultValue != null && defaultValue < min) {
      throw _valueException('default value out of range (minimum is $min)', key,
          defaultValue.toString());
    }
    if (max != null && defaultValue != null && max < defaultValue) {
      throw _valueException('default value out of range (maximum is $max)', key,
          defaultValue.toString());
    }

    final _value = _yamlMap[key];

    if (_value is int) {
      if (min != null && _value < min) {
        throw _valueException(
            'out of range (minimum is $min)', key, _value.toString());
      }
      if (max != null && max < _value) {
        throw _valueException(
            'out of range (maximum is $max)', key, _value.toString());
      }
      return _value;
    } else if (_value == null) {
      if (defaultValue != null) {
        assert(!optional);
        return defaultValue;
      } else if (optional) {
        return null;
      } else {
        throw _keyMissingException(key);
      }
    } else {
      throw _valueException('value is not an integer', key, _value.toString());
    }
  }

  //----------------------------------------------------------------
  /// Extracts a string value.
  ///
  /// Returns the string value corresponding to the [key].
  ///
  /// The key must exist in the map or a [defaultValue] is provided.
  /// Otherwise, a [ConfigExceptionKeyMissing] exception will be thrown.
  ///
  /// To allow the key to be missing, use the [stringOptional] method.
  ///
  /// ## Default value
  ///
  ///
  /// When a _defaultValue_ is provided a value is always returned. So while the
  /// key does not have to appear in the config, there is always a value
  /// available. To the config it is optional, but to the program it behaves the
  /// same as a mandatory key.
  ///
  /// ## Whitespaces in values
  ///
  /// The default behaviour is to return the string value after
  /// tidying up whitespace in it and empty strings (i.e. zero length strings)
  /// cause a [ConfigExceptionValue] to be thrown.
  ///
  /// Tidying up whitespace involves: collapsing sequences of one or more
  /// tabs and/or spaces into a single space, and removing any tabs and/or
  /// spaces from the beginning and end of the string (i.e. trimming it).
  ///
  /// Therefore, with the default behaviour, the value returned is never blank,
  /// never contains leading of trailing whitespace, never contains non-space
  /// whitespace (e.g. tabs) and never contains multiple spaces in a row.
  /// If spaces and tabs are significant, this behaviour can be changed by
  /// setting _keepWhitespace_, _allowEmpty_ and _allowBlank_.
  ///
  /// Tidying up of whitespace can be disabled by setting [keepWhitespace] to
  /// true. The default is false.
  ///
  /// If [allowedEmpty] is true, zero length strings are permitted. The default
  /// is false.
  ///
  /// If [allowBlank] is true and _keepWhitespace_ is true, values consisting
  /// entirely of one or more spaces and/or tabs are permitted. The default is
  /// for _allowBlank_ is false, so values must contain at least one
  /// non-whitespace character. If _keepWhitespace_ is false (the default),
  /// _allowBlank_ is ignored, since all blank values will become empty strings.
  ///
  /// Note: new line and carriage return characters never appear in the
  /// returned value, even if they appear in the string values in the config.
  /// They are always automatically removed, even if _keepWhitespace_ is true.
  ///
  /// ## Restricting values
  ///
  /// The default behaviour allows any string value (as long as it satisfies
  /// the whitespace rules).
  ///
  /// If a list of [permitted] values are provided, any other values cause
  /// a [ConfigExceptionValue] to be thrown.
  ///
  /// The _allowEmpty_ and _allowBlank_ rules will always apply, even if the
  /// _permitted_ values contains strings that are empty or blank (which is a
  /// strange thing to do anyway). The behaviour is undefined if both
  /// _keepWhitespace_ is set to true and [permitted] values are provided.

  String string(String key,
          {bool keepWhitespace = false,
          bool allowEmpty = false,
          bool allowBlank = false,
          Iterable<String>? permitted,
          String? defaultValue}) =>
      _string(key,
          keepWhitespace: keepWhitespace,
          allowEmpty: allowEmpty,
          allowBlank: allowBlank,
          permitted: permitted,
          defaultValue: defaultValue,
          optional: false)!;

  //----------------
  /// Extracts an optional string value.
  ///
  /// Returns the string value corresponding to the [key] if it exists, or null
  /// if it does not exist. Use the _string_ method if the key must always
  /// exist.
  ///
  /// See [string] for more details.
  ///
  /// Note: this will return `String?` once non-nullable Dart is available.

  String? stringOptional(String key,
          {bool keepWhitespace = false,
          bool allowEmpty = false,
          bool allowBlank = false,
          Iterable<String>? permitted}) =>
      _string(key,
          allowEmpty: allowEmpty,
          allowBlank: allowBlank,
          keepWhitespace: keepWhitespace,
          permitted: permitted,
          optional: true);

  //----------------
  /// Internal implementation for [string] and [stringOptional].

  String? _string(String key,
      {required bool keepWhitespace,
      required bool allowEmpty,
      required bool allowBlank,
      Iterable<String>? permitted,
      required bool optional,
      String? defaultValue}) {
    _used.add(key);

    assert(!optional || defaultValue == null, 'optional cannot have a default');

    if (permitted != null && defaultValue != null) {
      if (!permitted.contains(defaultValue)) {
        throw _valueException(
            'default value not in permitted values', key, defaultValue);
      }
    }
    if (permitted != null && keepWhitespace) {
      throw _keyException(
          'permitted values cannot be used with keepWhitespace', key);
    }

    final _rawValue = _yamlMap[key];

    if (_rawValue is String) {
      return _checkedString(key, _rawValue, permitted,
          keepWhitespace: keepWhitespace,
          allowEmpty: allowEmpty,
          allowBlank: allowBlank);
    } else if (_rawValue == null) {
      // Missing

      if (defaultValue != null) {
        assert(!optional);
        return defaultValue;
      } else if (optional) {
        return null;
      } else {
        throw _keyMissingException(key);
      }
    } else {
      throw _valueException('value is not string', key, _rawValue.toString());
    }
  }

  // Applies the constraints to the string.
  //
  // Returns string (possibly with whitespace tidied up) if it is acceptable,
  // otherwise an exception is thrown.
  //
  // All the booleans may be null: while the public methods have a default, the
  // program could override the default with a null. So this assumes null means
  // the same as the default.
  //
  // This method is used by both [_string] and [_stringList].

  String _checkedString(
      String key, String rawValue, Iterable<String>? permitted,
      {required bool keepWhitespace,
      required bool allowEmpty,
      required bool allowBlank}) {
    // Tidy whitespace, if requested

    final str = keepWhitespace
        ? rawValue
        : rawValue.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

    // Checks are applied to the value, after whitespace processing

    if (str.isEmpty) {
      // Value is empty
      if (allowEmpty) {
        return str; // return empty string: ignores any permitted values
      } else {
        throw _valueException('empty string not permitted', key, str);
      }
    } else if (RegExp(r'^[ \t]+$').hasMatch(str)) {
      // Value is blank
      assert(keepWhitespace, 'never blank if whitespace is not kept');

      if (allowBlank) {
        return str; // return blank string: ignoring any permitted values
      } else {
        throw _valueException('blank string not permitted', key, str);
      }
    } else {
      // Non-empty value
      if (permitted == null || permitted.contains(str)) {
        // Anything is permitted, or the value is one of the permitted values
        return str; // return value
      } else {
        throw _valueException('not a permitted value', key, str);
      }
    }
  }

  //----------------------------------------------------------------
  /// Extracts a config map.
  ///
  /// Returns the config map corresponding to the [key].
  ///
  /// The key must exist in the map.
  /// Otherwise, a [ConfigExceptionKeyMissing] exception will be thrown.
  ///
  /// To allow the key to be missing, use the [mapOptional] method.

  ConfigMap map(String key) => _map(key, optional: false)!;

  //----------------
  /// Extracts an optional boolean value.
  ///
  /// Returns the config map corresponding to the [key] if it exists, or null
  /// if it does not exist. Use the _map_ method if the key must always
  /// exist.
  ///
  /// See [map] for more details.
  ///
  /// Note: this will return `ConfigMap?` once non-nullable Dart is available.

  ConfigMap? mapOptional(String key) => _map(key, optional: true);

  //----------------
  /// Internal implementation for [map] and [mapOptional].

  ConfigMap? _map(String key, {required bool optional}) {
    _used.add(key);

    final _value = _yamlMap[key];
    if (_value is YamlMap) {
      return ConfigMap._fromYamlMap(key, _value);
    } else if (_value == null) {
      if (optional) {
        return null;
      } else {
        throw _keyMissingException(key);
      }
    } else {
      throw _valueException('value is not a map', key, _value.toString());
    }
  }

  //----------------------------------------------------------------
  /// Extracts a list of booleans.
  ///
  /// Returns the list of booleans corresponding to the [key].
  ///
  /// The key must exist in the map.
  /// Otherwise, a [ConfigExceptionKeyMissing] exception will be thrown.
  ///
  /// To allow the key to be missing, use the [booleansOptional] method.
  ///
  /// By default, lists containing no members are permitted. If [allowEmptyList]
  /// is set to false, a [ConfigExceptionValueEmptyList] is thrown if the
  /// list is empty.

  List<bool> booleans(String key, {bool allowEmptyList = true}) =>
      _listBoolean(key, allowEmptyList: allowEmptyList, optional: false)!;

  //----------------
  /// Extracts an optional list of booleans.
  ///
  /// Returns the list of booleans corresponding to the [key] if it
  /// exists, or null if it does not exist. Use the _booleans_ method if the
  /// key must always exist.
  ///
  /// See [booleans] for more details.
  ///
  /// Note: this will return `List<bool>?` once non-nullable Dart is available.

  List<bool>? booleansOptional(String key,
          {int? min, int? max, bool allowEmptyList = true}) =>
      _listBoolean(key, allowEmptyList: allowEmptyList, optional: true);

  //----------------
  /// Internal implementation for [booleans] and [booleansOptional].

  List<bool>? _listBoolean(String key,
      {required bool optional, required bool allowEmptyList}) {
    _used.add(key);

    final _value = _yamlMap[key];
    if (_value is YamlList) {
      final result = <bool>[];

      var index = 0;
      for (final element in _value) {
        if (element is bool) {
          result.add(element);
        } else {
          throw _valueException(
              'member is not true/false', '$key[$index]', element.toString());
        }

        index++;
      }

      if (result.isEmpty && !(allowEmptyList)) {
        throw _valueEmptyListException(key);
      }
      return result;
    } else if (_value == null) {
      if (optional) {
        return null;
      } else {
        throw _keyMissingException(key);
      }
    } else {
      throw _valueException('value is not a list', key, _value.toString());
    }
  }

  //----------------------------------------------------------------
  /// Extracts a list of integers.
  ///
  /// Returns the list of integers corresponding to the [key].
  ///
  /// The key must exist in the map.
  /// Otherwise, a [ConfigExceptionKeyMissing] exception will be thrown.
  ///
  /// To allow the key to be missing, use the [integersOptional] method.
  ///
  /// By default, lists containing no members are permitted. If [allowEmptyList]
  /// is set to false, a [ConfigExceptionValueEmptyList] is thrown if the
  /// list is empty.
  ///
  /// ### Range checking
  ///
  /// If either, or both, [min] and [max] are provided, range checking is
  /// performed on the every value in the list. If any value is smaller than
  /// _min_ or larger than _max_, a [ConfigExceptionValue] is thrown.

  List<int> integers(String key,
          {int? min, int? max, bool allowEmptyList = true}) =>
      _integerList(key,
          min: min, max: max, allowEmptyList: allowEmptyList, optional: false)!;

  //----------------
  /// Extracts an optional list of integers.
  ///
  /// Returns the list of integers corresponding to the [key] if it
  /// exists, or null if it does not exist. Use the _integers_ method if the
  /// key must always exist.
  ///
  /// See [integers] for more details.
  ///
  /// Note: this will return `List<int>?` once non-nullable Dart is available.

  List<int>? integersOptional(String key,
          {int? min, int? max, bool allowEmptyList = true}) =>
      _integerList(key,
          min: min, max: max, allowEmptyList: allowEmptyList, optional: true);

  //----------------
  /// Internal implementation for [integers] and [integersOptional].

  List<int>? _integerList(String key,
      {required bool optional,
      int? min,
      int? max,
      required bool allowEmptyList}) {
    _used.add(key);

    final _value = _yamlMap[key];
    if (_value is YamlList) {
      final result = <int>[];

      var index = 0;
      for (final element in _value) {
        final elemPath = '$key[$index]';

        if (element is int) {
          if (min != null && element < min) {
            throw _valueException(
                'out of range (minimum is $min)', elemPath, element.toString());
          }
          if (max != null && max < element) {
            throw _valueException(
                'out of range (maximum is $max)', elemPath, element.toString());
          }
          result.add(element);
        } else {
          throw _valueException(
              'member is not an integer', elemPath, element.toString());
        }

        index++;
      }

      if (result.isEmpty && !(allowEmptyList)) {
        throw _valueEmptyListException(key);
      }
      return result;
    } else if (_value == null) {
      if (optional) {
        return null;
      } else {
        throw _keyMissingException(key);
      }
    } else {
      throw _valueException('value is not a list', key, _value.toString());
    }
  }

  //----------------------------------------------------------------
  /// Extracts a list of strings.
  ///
  /// Returns the list of strings corresponding to the [key].
  ///
  /// The key must exist in the map.
  /// Otherwise, a [ConfigExceptionKeyMissing] exception will be thrown.
  ///
  /// To allow the key to be missing, use the [stringsOptional] method.
  ///
  /// By default, lists containing no members are permitted. If [allowEmptyList]
  /// is set to false, a [ConfigExceptionValueEmptyList] is thrown if the
  /// list is empty.
  ///
  /// The [keepWhitespace], [allowEmpty], [allowBlank] and [permitted]
  /// parameters behave the same as in [string], but are applied to each member
  /// of the list.

  List<String> strings(
    String key, {
    bool allowEmptyList = true,
    bool keepWhitespace = false,
    bool allowEmpty = false,
    bool allowBlank = false,
    Iterable<String>? permitted,
  }) =>
      _stringList(key,
          allowEmptyList: allowEmptyList,
          keepWhitespace: keepWhitespace,
          allowEmpty: allowEmpty,
          allowBlank: allowBlank,
          permitted: permitted,
          optional: false)!;

  //----------------
  /// Extracts an optional list of strings.
  ///
  /// Returns the list of strings corresponding to the [key] if it
  /// exists, or null if it does not exist. Use the _strings_ method if the
  /// key must always exist.
  ///
  /// See [strings] for more details.
  ///
  /// Note: this will return `List<String>?` once non-nullable Dart is available.

  List<String>? stringsOptional(String key,
          {bool allowEmptyList = true,
          bool keepWhitespace = false,
          bool allowEmpty = false,
          bool allowBlank = false,
          Iterable<String>? permitted}) =>
      _stringList(key,
          allowEmptyList: allowEmptyList,
          allowEmpty: allowEmpty,
          allowBlank: allowBlank,
          keepWhitespace: keepWhitespace,
          permitted: permitted,
          optional: true);

  //----------------
  /// Internal implementation for [strings] and [stringsOptional].

  List<String>? _stringList(String key,
      {required bool optional,
      required bool allowEmptyList,
      required bool keepWhitespace,
      required bool allowEmpty,
      required bool allowBlank,
      Iterable<String>? permitted}) {
    _used.add(key);

    if (permitted != null && keepWhitespace) {
      throw _keyException(
          'permitted values cannot be used with keepWhitespace', key);
    }

    final _value = _yamlMap[key];

    if (_value is YamlList) {
      final result = <String>[];

      var index = 0;
      for (final _rawValue in _value) {
        if (_rawValue is String) {
          final str = _checkedString('$key[$index]', _rawValue, permitted,
              keepWhitespace: keepWhitespace,
              allowEmpty: allowEmpty,
              allowBlank: allowBlank);
          result.add(str);
        } else {
          throw _valueException(
              'member is not a string', '$key[$index]', _rawValue.toString());
        }

        index++;
      }

      if (result.isEmpty && !allowEmptyList) {
        throw _valueEmptyListException(key);
      }

      return result;
    } else if (_value == null) {
      if (optional) {
        return null;
      } else {
        throw _keyMissingException(key);
      }
    } else {
      throw _valueException('value is not a list', key, _value.toString());
    }
  }

  //----------------------------------------------------------------
  /// Extracts a list of config maps.
  ///
  /// Returns the list of config maps corresponding to the [key].
  ///
  /// The key must exist in the map.
  /// Otherwise, a [ConfigExceptionKeyMissing] exception will be thrown.
  ///
  /// To allow the key to be missing, use the [mapsOptional] method.
  ///
  /// By default, lists containing no members are permitted. If [allowEmptyList]
  /// is set to false, a [ConfigExceptionValueEmptyList] is thrown if the
  /// list is empty.

  List<ConfigMap> maps(String key, {bool allowEmptyList = true}) =>
      _listMap(key, allowEmptyList: allowEmptyList, optional: false)!;

  //----------------
  /// Extracts an optional list of config maps.
  ///
  /// Returns the list of config maps corresponding to the [key] if it
  /// exists, or null if it does not exist. Use the _maps_ method if the
  /// key must always exist.
  ///
  /// See [maps] for more details.
  ///
  /// Note: this will return `List<bool>?` once non-nullable Dart is available.

  List<ConfigMap>? mapsOptional(String key, {bool allowEmptyList = true}) =>
      _listMap(key, allowEmptyList: allowEmptyList, optional: true);

  //----------------
  /// Internal implementation for [maps] and [mapsOptional].

  List<ConfigMap>? _listMap(String key,
      {required bool optional, required bool allowEmptyList}) {
    _used.add(key);

    final _value = _yamlMap[key];
    if (_value is YamlList) {
      final result = <ConfigMap>[];

      var index = 0;
      for (final element in _value) {
        final ek = '$key[$index]';

        if (element is YamlMap) {
          result.add(ConfigMap._fromYamlMap(
              (path.isEmpty) ? ek : '$path/$ek', element));
        } else {
          throw _valueException('member is not a map', ek, element.toString());
        }

        index++;
      }

      if (result.isEmpty && !allowEmptyList) {
        throw _valueEmptyListException(key);
      }

      return result;
    } else if (_value == null) {
      if (optional) {
        return null;
      } else {
        throw _keyMissingException(key);
      }
    } else {
      throw _valueException('value is not a list', key, _value.toString());
    }
  }

  //================================================================
  // Methods for dynamically inspecting a config map.

  //----------------------------------------------------------------
  /// Checks all the keys in the config map have been processed.
  ///
  /// Throws a [ConfigExceptionKeyUnexpected] if the config map contains keys
  /// which have not been referenced by one of the extraction methods
  /// (e.g. _string_, _stringOptional_, _integer_).
  ///
  /// Throws a [ConfigExceptionFormat] if an invalid key is found. This is a
  /// syntax error which is not detected by the _ConfigMap_ constructor, but
  /// is only detected when all the keys are examined.
  ///
  /// This method is used for checking a config only contains the expected keys
  /// and nothing else. If it throws an exception, either the config is invalid
  /// or the program is missing an extraction operation.

  void unusedKeysCheck() {
    keys(permitted: _used.toList(growable: false));
  }

  //----------------------------------------------------------------
  /// List all the keys in the config map.
  ///
  /// If a list of [permitted] keys is provided, a
  /// [ConfigExceptionKeyUnexpected] is thrown if there is a key that is not in
  /// that list. This can be used to check if the config has invalid/unexpected
  /// content, but it may be better to use [unusedKeysCheck] to avoid
  /// duplication and the associated risk of inconsistencies.
  ///
  /// Throws a [ConfigExceptionFormat] if an invalid key is found. This is a
  /// syntax error which is not detected by the _ConfigMap_ constructor, but
  /// is only detected when all the keys are examined.

  List<String> keys({List<String>? permitted}) {
    final found = <String>[];

    for (final key in _yamlMap.keys) {
      if (key is String) {
        if (permitted != null) {
          if (!permitted.contains(key)) {
            throw _keyUnexpectedException(key);
          }
        }

        assert(!found.contains(key), 'YAML parser allowed a duplicate key!');

        found.add(key);
      } else {
        throw ConfigExceptionFormat(
            'non-string key: ${path.isEmpty ? '' : '$path/'}$key');
      }
    }

    return found;
  }

  //----------------------------------------------------------------
  /// Identifies the type of a key's value.
  ///
  /// The special value of [ConfigType.unavailable] is returned if the key
  /// does not exist in the map.
  ///
  /// The special value of [ConfigType.unknownList] is returned if the value is
  /// an empty list. The type of the list cannot be automatically determined,
  /// since it has no members to examine.
  ///
  /// A [ConfigExceptionKey] is thrown if the value is invalid. One situation
  /// where this can occur is if a list contains more than one type of value.
  ///
  /// This is usually used with the [keys] method.

  ConfigType type(String key) {
    if (_yamlMap.containsKey(key)) {
      final yamlValue = _yamlMap[key];

      if (yamlValue is bool) {
        return ConfigType.boolean;
      } else if (yamlValue is String) {
        return ConfigType.string;
      } else if (yamlValue is int) {
        return ConfigType.integer;
      } else if (yamlValue is YamlMap) {
        return ConfigType.map;
      } else if (yamlValue is YamlList) {
        // List

        if (yamlValue.isEmpty) {
          return ConfigType.unknownList;
        } else {
          final firstValue = yamlValue.first;

          if (firstValue is bool) {
            for (final v in yamlValue) {
              if (v is! bool) {
                throw _keyException('mixed types in list', key);
              }
            }
            return ConfigType.booleans;
          } else if (firstValue is int) {
            for (final v in yamlValue) {
              if (v is! int) {
                throw _keyException('mixed types in list', key);
              }
            }
            return ConfigType.integers;
          } else if (firstValue is String) {
            for (final v in yamlValue) {
              if (v is! String) {
                throw _keyException('mixed types in list', key);
              }
            }
            return ConfigType.strings;
          } else if (firstValue is YamlMap) {
            for (final v in yamlValue) {
              if (v is! YamlMap) {
                throw _keyException('mixed types in list', key);
              }
            }
            return ConfigType.maps;
          } else {
            throw _keyException('unexpected type of list', key);
          }
        }
      } else {
        throw _keyException('unexpected type of value', key);
      }
    } else {
      return ConfigType.unavailable;
    }
  }
}
