#!/usr/bin/env dart

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:strict_config/strict_config.dart';

final _logApp = Logger('app');
final _logConfig = Logger('app.config');
final _logRsrc = Logger('app.resource');
final _logHeaders = Logger('app.resource.headers');
final _logCert = Logger('app.resource.cert');

//----------------------------------------------------------------

class ExampleConfig2 {
  /// Extract from a config map.

  ExampleConfig2(ConfigMap m) {
    name = m.string('name');
    desc = m.stringOptional('description', keepWhitespace: true);
    server = ServerConfig(m.map('server'));

    // Using `defaultValue`
    //
    // The "min-days" and "debug" keys do not have to be provided in the
    // config, but with _defaultValue_ they will always have a value
    // in this program. Note use of range checking for "max-retries".

    minDaysToExpiry =
        m.integer('min-days-to-expiry', min: 0, max: 365, defaultValue: 30);
    ignoreBadCert = m.boolean('ignore-bad-certificate', defaultValue: false);

    // List of strings
    //
    // The "paths" key is optional in the config, but if it is present the
    // value cannot be an empty list.

    pathSegments = m.stringsOptional('path-segments', allowEmptyList: false);

    // Config map.
    //
    // The account config map is optional, so it may return null.
    // If it is present, extract values from it into an `AccountConfig` object.

    final _accountMap = m.mapOptional('account');
    if (_accountMap != null) {
      account = AccountConfig(_accountMap);
    }

    // List of config maps.
    //
    // If these comments were not here, convenience methods like this can make
    // the extraction code very compact (like the first few lines of this
    // method).

    headers = HeaderConfig.mapsOptional('headers', m);

    // Extract logger levels and use them to setup logging

    _setupLogging(m);

    // Extra error checking: throws an exception if the config map contains
    // keys that have not been processed. This can be helpful for debugging
    // mis-typed keys and other errors. But in some situations, you might want
    // to skip this check to allow the config to contain other keys that the
    // program ignores.

    m.unusedKeysCheck();
  }

  /// Extract from a file.

  factory ExampleConfig2.fromFile(String configFilename) {
      // Read text from the file

      final configText = File(configFilename).readAsStringSync();

      // Parse and extract values from it

      final config = ConfigMap(configText);
      return ExampleConfig2(config);
  }

  //----------------

  late String name;
  String? desc; // optional, so it maybe null
  late ServerConfig server;

  late int minDaysToExpiry;
  late bool ignoreBadCert;
  List<String>? pathSegments; // optional
  AccountConfig? account; // optional
  late List<HeaderConfig> headers; // optional, empty list if not present


  //----------------
  // Extract logger levels from the config map and setup logging.

  void _setupLogging(ConfigMap m) {
    final levels = LoggerConfig.optional(m); // default key = 'logger'
    if (levels != null) {
      // The "logger" key exists in the config map: setup logging

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
  factory ServerConfig(ConfigMap m) {
    final _host = m.string('host');
    final _tls = m.boolean('tls', defaultValue: true);
    final _port = m.integer('port', min: 1, max: 65535, defaultValue: _tls ? 443 : 80);
    m.unusedKeysCheck();

    return ServerConfig._init(_host, _tls, _port);
  }

  ServerConfig._init(this.host, this.tls, this.port);

  String host;
  bool tls;
  int port;
}

//----------------------------------------------------------------
/// Account config.

class AccountConfig {
  /// Constructor
  ///
  /// Extracts values from a config map.
  ///
  /// Will be invoked with a config map extracted another (the top-level) config
  /// map.

  AccountConfig(ConfigMap m) {
    // Mandatory username: never null
    //
    // The "username" key must appear in the config.
    //
    // Whitespaces are tidied up and empty strings (zero length) are rejected
    // by throwing an exception.

    username = m.string('username');

    // Optional password: may be null
    //
    // The "password" key may or may not be in the config. If it is not present,
    // the value is null.
    //
    // Whitespaces are significant, so keep them in the value. Allow blank
    // strings (made up entirely of whitespace) and empty strings (zero length).

    password = m.stringOptional('password',
        keepWhitespace: true, allowBlank: true, allowEmpty: true);

    // Authentication scheme: optional in config, but program always has a value
    //
    // If the key is not in the config, the provided `defaultValue` is returned.
    // Since there is always a value returned, this is uses `string` method
    // instead of the `stringOptional` method. The key is optional in the
    // config, but the extracted value is never null.
    //
    // If the key is in the config, the value must be one of the `permitted`
    // values. Otherwise an exception is thrown.

    scheme = m.string('auth-scheme',
        permitted: ['Basic', 'Digest'], defaultValue: 'Basic');

    // Check for any unexpected keys in the config.
    //
    // The config map keeps track of the keys passed to the extraction methods,
    // so it knows "username", "password" and "two-factor" are expected keys.
    // Any other keys in the config map will cause an exception to be thrown.
    //
    // This can be useful for users. For example, if they have mistyped the name
    // of a key, they will know it is an error instead of wondering why the
    // value in the config is not being used.

    m.unusedKeysCheck();
  }

  late String username;
  String? password; // optional: could be null
  String? scheme; // optional, but will always have a value
}

//----------------------------------------------------------------
/// Header config.

class HeaderConfig {
  HeaderConfig(ConfigMap m) {
    name = m.string('name');
    value = m.stringOptional('value', allowEmpty: true);

    m.unusedKeysCheck();
  }

  late String name;
  String? value; // optional

  @override
  String toString() => '$name: $value';

  /// Convenience method for extracting an optional list of HeaderConfigs.
  ///
  /// Always returns a list. If the configs are not present, the empty list
  /// is returned.

  static List<HeaderConfig> mapsOptional(String name, ConfigMap parentMap) {
    // Since allowEmptyList defaults to true, this could return null or
    // an empty list as two distinct values. But this method will treat them
    // both to mean the same thing: no headers.
    //
    // To make the code that uses the headers simpler, this method always
    // returns a list. An alternative design is to return null.

    final childList = parentMap.mapsOptional(name);

    if (childList != null) {
      // List of values or a list that is empty
      return childList.map((e) => HeaderConfig(e)).toList();
    } else {
      return []; // treat a missing key the same as an empty list
    }
  }
}

//================================================================

// The future is null on success, or a string on error.

Future<String?> checkResource(ExampleConfig2 config) async {
  final uri = Uri(
      scheme: config.server.tls ? 'https' : 'http',
      host: config.server.host,
      port: config.server.port,
      pathSegments: config.pathSegments);
  _logRsrc.info('URI: $uri');

  // Set up HttpClient

  final client = HttpClient();

  if (config.ignoreBadCert) {
    client.badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);
  }

  final account = config.account;
  if (account != null) {
    client.authenticate = (Uri url, String scheme, String realm) async {
      if (scheme == account.scheme) {
        late HttpClientCredentials cred;

        if (scheme == 'Basic') {
          cred = HttpClientBasicCredentials(
              account.username, account.password ?? '');
        } else if (scheme == 'Digest') {
          cred = HttpClientDigestCredentials(
              account.username, account.password ?? '');
        }

        client.addCredentials(url, realm, cred);
        return true;
      } else {
        _logRsrc.severe('authentication scheme not supported: $scheme');
        return false; // scheme not supported
      }
    };
  }

  try {
    // Open request

    final req = await client.getUrl(uri);
    for (final h in config.headers) {
      req.headers.add(h.name, h.value ?? '');
    }

    // Get response

    final resp = await req.close();
    try {
      final cert = resp.certificate;
      if (cert != null) {
        // TLS server certificate

        _logCert.fine('Server cert subject: ${cert.subject}');
        _logCert.finest('Server cert issuer: ${cert.issuer}');
        _logCert.finer('Server cert start validity: ${cert.startValidity}');
        _logCert.finer('Server cert end validity: ${cert.endValidity}');

        // Produce alert if will expire soon (or has already expired)

        final daysToExpiry = cert.endValidity
            .difference(DateTime.now())
            .inDays;
        if (daysToExpiry <= 0) {
          return 'certificate expired';
        }
        if (daysToExpiry < config.minDaysToExpiry) {
          return 'certificate expires in $daysToExpiry days';
        }
      }

      resp.headers.forEach((name, values) {
        for (final value in values) {
          _logHeaders.fine('$name: $value');
        }
      });

      // HTTP status

      _logRsrc.fine('HTTP status = ${resp.statusCode}');
      if (HttpStatus.ok <= resp.statusCode && resp.statusCode < 300) {
        return null; // success
      } else {
        return 'status=${resp.statusCode}';
      }
    } finally {
      await resp.drain(); // without this the program does not exit
    }
  } on HandshakeException catch (e) {
    _logRsrc.fine('HandshakeException: $e');
    return 'TLS handshake failed';
  } finally {
    client.close(); // without this the program does not exit
  }
}

//================================================================

Future<void> main(List<String> args) async {
  // Simple command line processing

  final prog = Platform.script.pathSegments.last.replaceAll('.dart', '');

  if (args.contains('-h') || args.contains('--help')) {
    stdout.write('Usage: $prog [-h|--help] [-v|--verbose] configFile\n');
    exit(0);
  }
  final remainingArgs = List<String>.from(args);
  final verbose = remainingArgs.remove('-v') || remainingArgs.remove('--verbose');

  if (remainingArgs.isEmpty) {
    stderr.write('Usage error: missing config file\n');
    exit(2);
  } else if (1 < remainingArgs.length) {
    stderr.write('Usage error: too many arguments ("-h" for help)\n');
    exit(2);
  }
  final configFilename = remainingArgs.first;

  // Load the config

  ExampleConfig2 config;
  try {
   config = ExampleConfig2.fromFile(configFilename);
   logConfig(configFilename, config);
  } on ConfigException catch (e) {
    stderr.write('Config error: $configFilename: $e\n');
    exit(1);
  } on FileSystemException catch (e) {
    stderr.write('Error: ${e.path}: ${e.message}\n');
    exit(1);
  }

  // Use the config

  _logApp.finer('begin');

  final errorMessage = await checkResource(config);

  _logApp.fine('result: $errorMessage');
  _logApp.finer('end');

  if (errorMessage == null) {
    stdout.write('${config.name}: ok\n');
    exitCode = 0;
  } else {
    stdout.write('${config.name}: $errorMessage\n');
    exitCode = 1;
  }

  if (verbose) {
    stdout.write('${config.desc}\n');
  }
}

/// Use a logger to output the config values.
///
/// Try changing the logger level of the "app.config" logger to control which
/// log entries are outputted.

void logConfig(String configFilename, ExampleConfig2 config) {

  _logConfig.config('config file: "$configFilename"');

  _logConfig.fine('name="${config.name}"');
  _logConfig.finer('description="${config.desc}"');

  _logConfig.finest('server host: ${config.server.host}');
  _logConfig.finest('server port: ${config.server.port}');
  _logConfig.finest('server TLS: ${config.server.tls}');

  _logConfig.info('minimum days to expiry: ${config.minDaysToExpiry}');

  if (config.pathSegments != null) {
    _logConfig.finest('path segments: ${config.pathSegments}');
  } else {
    _logConfig.finest('path segments: none');
  }

  final acc = config.account;
  if (acc != null) {
    // Optional account is available
    final p =
    acc.password != null ? 'password is provided' : 'prompt for password';
    _logConfig.finest('account: ${acc.username} [${acc.scheme}] $p');
    if (acc.password != null && acc.password!.length < 10) {
      _logConfig.warning('password is insecure: it is too short');
    }
    if (acc.password != null && acc.password!.isEmpty) {
      _logConfig.severe('password is very insecure: it is the empty string');
    }
  }

  _logConfig.finest('headers: ${config.headers}');
}