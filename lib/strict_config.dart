/// Library for extracting values from a config.
///
/// Use the [ConfigMap] class to parse config text and extract values from it.
///
/// The [LoggerConfig] class extracts logger levels from a _ConfigMap_, and use
/// them to setup loggers with the _logging_ package. This allows loggers to be
/// controlled through a config, instead of with hard-coded levels.

library strict_config;

import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

part 'src/exceptions.dart';
part 'src/logger_config.dart';
part 'src/config_map.dart';
