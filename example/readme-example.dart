#!/usr/bin/env dart
// Example from the README.

import 'dart:io';
import 'package:strict_config/strict_config.dart';

class ExampleConfig {
  ExampleConfig(ConfigMap m) {
    name = m.string('name');
    desc = m.stringOptional('description', keepWhitespace: true);
    server = ServerConfig(m.map('server'));
    m.unusedKeysCheck();
  }

  late String name;
  String? desc; // optional
  late ServerConfig server;
}

class ServerConfig {
  factory ServerConfig(ConfigMap m) {
    final _host = m.string('host');
    final _tls = m.boolean('tls', defaultValue: true);
    final _port =
        m.integer('port', min: 1, max: 65535, defaultValue: _tls ? 443 : 80);
    m.unusedKeysCheck();

    return ServerConfig._init(_host, _tls, _port);
  }

  ServerConfig._init(this.host, this.tls, this.port);

  String host;
  bool tls;
  int port;
}

void main(List<String> args) {
  final filename = args.isNotEmpty ? args.first : 'example.conf';

  try {
    final text = File(filename).readAsStringSync();

    final config = ExampleConfig(ConfigMap(text));

    print('Name: ${config.name}');
    if (config.desc != null) {
      print('Description: ${config.desc}');
    }
    print('Host: ${config.server.host}');
    print('TLS: ${config.server.tls}');
    print('Port: ${config.server.port}');

    exit(0);
  } on ConfigException catch (e) {
    stderr.write('Error: $filename: $e\n');
    exit(1);
  } on FileSystemException catch (e) {
    stderr.write('Error: ${e.path}: ${e.message}\n');
    exit(1);
  }
}
