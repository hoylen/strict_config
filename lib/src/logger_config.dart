part of strict_config;

//################################################################
/// Configuration of logger levels.
///
/// Logger levels extracted from a config. Used to set up loggers from the
/// [logging](https://pub.dev/packages/logging) package, with levels
/// obtained from a config.
///
/// Using this class involves:
///
/// - Using the [LoggerConfig.LoggerConfig] constructor
///   (or the [optional] convenience method) to create
///   a _LoggerConfig_ from a _config map_; and
/// - Invoking the [applyLevels] method to use the levels in it.
///
/// ## Expected config
///
/// A config map needs to contain keys which are used as logger names and their
/// values are used as levels (either strings or integers).
///
/// For example,
/// ```
/// logger:
///   foo: FINER
///   foo.bar: FINE
///   baz: INFO
///   baz.special: 150
/// ```
///
/// ## Details
///
/// Since logs are usually optional, it is usually represented as an optional
/// config map. If the config map exists, use the [LoggerConfig.LoggerConfig]
/// constructor to extract the levels from it.
///
/// ```
/// final loggerMap = cfg.map('logger', optional: true);
/// if (loggerMap != null) {
///   final levels = LoggerConfig(loggerMap);
///   ...
/// }
/// ```
///
/// The [optional] convenience method incorporates the check
/// for an optional config map. So the above code can be reduced to:
///
/// ```
/// final levels = LoggerConfig.optional(cfg);
/// if (levels != null {
///   ...
/// }
/// ```
///
/// The levels can be set using the [applyLevels] method.
///
/// A more complete example:
///
/// ```dart
/// import 'package:logging/logging.dart';
/// ...
///
/// /// Pass in the top-level config map
/// void setupLogging(ConfigMap map) {
///   final levels = LoggerConfig.optional(map); // default key = 'logger'
///   if (levels != null) {
///     hierarchicalLoggingEnabled = true;
///     Logger.root.onRecord.listen((LogRecord r) {
///       final t = r.time.toUtc();
///       stdout.write('$t: ${r.loggerName}: ${r.level.name}: ${r.message}\n');
///     });
///
///     Logger.root.level = Level.OFF;
///     levels.applyLevels(); // setup levels specified in the config
///   }
/// }
/// ```

class LoggerConfig {
  //================================================================
  /// Constructs a collection of logger levels.
  ///
  /// Extracts logger names and levels from the config [map].
  ///
  /// If [caseInsensitive] is true, the level names (e.g. "INFO",
  /// "FINE", "ALL") are treated case insensitively. The default is false,
  /// which means they must appear all capitalized, otherwise they will be
  /// rejected.
  ///
  /// The named levels are the same as those defined by the _logging_ package:
  /// ALL, FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, SHOUT and OFF.
  ///
  /// Note: the logger names (the keys) are always case sensitive. Only the
  /// level names are affected by the _caseInsensitive_ parameter.

  LoggerConfig(ConfigMap map, {bool caseInsensitive = false}) {
    for (final k in map.keys()) {
      assert(!levels.containsKey(k), 'duplicate should never happen');

      // Get the value for the level

      final type = map.type(k);

      Level level;

      if (type == ConfigType.string) {
        // Named level

        final str = map.string(k);
        level = _predefinedLevels[caseInsensitive ? str.toUpperCase() : str];
        if (level == null) {
          throw ConfigExceptionValue(
              'level unknown ("$str")', map.path, k, str);
        }
      } else if (type == ConfigType.integer) {
        // Numeric level

        final num = map.integer(k);

        // Note: ALL is smaller than FINEST and OFF is larger than SHOUT, so
        // it is possible for custom levels to be more finer than the finest and
        // greater than shouting.

        if (num < Level.ALL.value && Level.OFF.value < num) {
          throw ConfigExceptionValue(
              'level out of range [${Level.ALL.value}-${Level.OFF.value}]',
              map.path,
              k,
              num.toString());
          // could have passed max and min to `integer`, but doing it this
          // way allows a customised error message to be produced.
        }

        level = Level('custom_$num', num);
      } else {
        // Neither a string nor an integer
        throw ConfigExceptionKey('level not a string or integer', map.path, k);
      }
      assert(level != null);

      // Store the level

      levels[k] = level;
    }
  }

  //================================================================
  // Static members

  /// Permitted names of the levels and the values they represent.

  static final _predefinedLevels = <String, Level>{
    'OFF': Level.OFF,
    'SHOUT': Level.SHOUT,
    'SEVERE': Level.SEVERE,
    'WARNING': Level.WARNING,
    'INFO': Level.INFO,
    'CONFIG': Level.CONFIG,
    'FINE': Level.FINE,
    'FINER': Level.FINER,
    'FINEST': Level.FINEST,
    'ALL': Level.ALL,
  };

  /// Recommended key for the config map containing the levels.
  ///
  /// The configuration of the loggers usually appear at the top-level of the
  /// config. This key is recommended, because it is the default used by the
  /// convenience method [optional] and it promotes consistency between
  /// differnt programs and configs.

  static const String recommendedKey = 'logger';

  //================================================================
  // Members

  /// Logger levels
  ///
  /// Map where the key is the logger name and the value is a [Level].

  final Map<String, Level> levels = {};

  //================================================================
  // Methods

  /// Sets the level for the named loggers.
  ///
  /// Goes through all the named loggers in [levels] and sets their level.
  ///
  /// The special key of "*" means to set the [Logger.root.level].

  void applyLevels() {
    for (final entry in levels.entries) {
      if (entry.key == '*') {
        Logger.root.level = entry.value;
      } else {
        Logger(entry.key).level = entry.value;
      }
    }
  }

  //================================================================
  // Static methods

  /// Convenience method to create a LoggerConfig from an optional config map.
  ///
  /// Checks the [parentMap] for a config map named [key]. If it exists, a
  /// LoggerConfig is created from it and returned. If it does not exist, null
  /// is returned.
  ///
  /// If [caseInsensitive] is true, the level names (e.g. "INFO",
  /// "FINE", "ALL") are treated case insensitively. The default is false,
  /// which means they must appear all capitalized, otherwise they will be
  /// rejected.
  ///
  /// The named levels are the same as those defined by the _logging_ package:
  /// ALL, FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, SHOUT and OFF.
  ///
  /// Note: the logger names (the keys) are always case sensitive. Only the
  /// level names are affected by the _caseInsensitive_ parameter.

  // ignore: prefer_constructors_over_static_methods
  static LoggerConfig optional(ConfigMap parentMap,
      {String key = recommendedKey, bool caseInsensitive = false}) {
    final childMap = parentMap.mapOptional(key);
    return childMap != null
        ? LoggerConfig(childMap, caseInsensitive: caseInsensitive)
        : null;
  }
}
