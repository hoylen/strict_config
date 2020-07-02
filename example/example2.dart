#!/usr/bin/env dart

///
/// Larger example.
///
/// This program supports a superset of the simple example. Therefore, simple
/// configs will work with it. But some larger configs will not work with the
/// simple example.
///
/// This example demonstrates additional extractors and the use of logging.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:strict_config/strict_config.dart';

final appLogger = Logger('app');
final cfgLogger = Logger('app.config');

//----------------------------------------------------------------

class ExampleConfig2 {
  ExampleConfig2(String configFilename) {
    try {
      // Read text from the file

      final configText = File(configFilename).readAsStringSync();

      // Parse and extract values from it

      final config = ConfigMap(configText);
      _extractValues(config);
    } on ConfigException catch (e) {
      stderr.write('Config error: $configFilename: $e\n');
      exit(1);
    } on FileSystemException catch (e) {
      stderr.write('Error: ${e.path}: ${e.message}\n');
      exit(1);
    }
  }

  //----------------

  String name;
  String desc; // optional
  ServerConfig server;

  int maxRetries;
  bool debug;
  AccountConfig account; // optional
  List<String> paths;

  //----------------

  void _extractValues(ConfigMap map) {
    name = map.string('name');
    desc = map.stringOptional('description', keepWhitespace: true);
    server = ServerConfig(map.map('server'));

    // The "debug" and "max-retries" does not have to be provided in the
    // config, since the _defaultValue_ makes them always have a value.

    debug = map.boolean('debug', defaultValue: false);
    maxRetries = map.integer('max-retries', min: 1, max: 16, defaultValue: 3);

    // Optional items (will support non-null Dart in a future release)

    paths = map.stringsOptional('paths');

    // Nest configuration items using config maps as values

    final _accountMap = map.mapOptional('account');
    if (_accountMap != null) {
      account = AccountConfig(_accountMap);
    }

    // Extract logger levels and use them to setup logging

    _setupLogging(map);

    map.unusedKeysCheck(); // throws exception if extra keys exist in config
  }

  //----------------

  void _setupLogging(ConfigMap map) {
    final levels = LoggerConfig.optional(map); // default key = 'logger'
    if (levels != null) {
      hierarchicalLoggingEnabled = true;
      Logger.root.onRecord.listen((LogRecord r) {
        final t = r.time.toUtc();
        stdout.write('$t: ${r.loggerName}: ${r.level.name}: ${r.message}\n');
      });

      Logger.root.level = Level.OFF;
      levels.applyLevels(); // setup levels specified in the config
    }
  }
}

//----------------------------------------------------------------

class ServerConfig {
  ServerConfig(ConfigMap map) {
    host = map.string('host');
    tls = map.boolean('tls', defaultValue: true);
    port =
        map.integer('port', min: 1, max: 65535, defaultValue: tls ? 443 : 80);
    map.unusedKeysCheck();
  }

  String host;
  bool tls;
  int port;
}

//----------------------------------------------------------------
/// Account config.

class AccountConfig {
  AccountConfig(ConfigMap map) {
    // Mandatory

    username = map.string('username');

    // Optional password
    //
    // Whitespaces are signification, so keep them in the value. Allow blank
    // values (made up entirely of whitespace) and empty values (zero length
    // string) -- not very secure!

    password = map.stringOptional('password',
        keepWhitespace: true, allowBlank: true, allowEmpty: true);

    // Only the permitted values are allowed. A default can also be provided,
    // as long as it is one of the permitted values.

    security = map.string('two-factor',
        permitted: ['none', 'challenge-response', 'token'],
        defaultValue: 'none');

    map.unusedKeysCheck();
  }

  String username;
  String password; // optional, blank allowed, whitespace not trimmed away
  String security;
}

//================================================================

void main(List<String> args) {
  const _defaultConfigFileName = 'example2.conf';
  final configFilename = args.isNotEmpty ? args.first : _defaultConfigFileName;

  final config = ExampleConfig2(configFilename);

  // Since logging is supported, use the logger to output the values.
  // Try changing the logger level of the "app.config" logger to control which
  // log entries are outputted.

  cfgLogger.config('config file: "$configFilename"');
  cfgLogger.fine('name="${config.name}"');
  cfgLogger.finer('description="${config.desc}"');
  cfgLogger.finest('server: ${config.server.tls ? 'https' : 'http'}//'
      '${config.server.host}:${config.server.port}');
  if (config.maxRetries != null) {
    cfgLogger.info('max-retries=${config.maxRetries}');
  }
  if (config.account != null) {
    // Optional account is available
    final acc = config.account;
    final p =
        acc.password != null ? 'password is provided' : 'prompt for password';
    cfgLogger.finest('account: ${acc.username} [${acc.security}] $p');
    if (acc.password != null && acc.password.length < 10) {
      cfgLogger.warning('password is insecure: it is too short');
    }
    if (acc.password != null && acc.password.isEmpty) {
      cfgLogger.severe('password is very insecure: it is the empty string');
    }
  }
  cfgLogger.finest('paths: ${config.paths}');

  appLogger.info('done');
  stderr.write('OK\n');

  exit(0);
}
