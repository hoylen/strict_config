#!/usr/bin/env dart
//
// Simple example from the README.

import 'dart:io';
import 'package:strict_config/strict_config.dart';

class ExampleConfig {
  ExampleConfig(ConfigMap map) {
    name = map.string('name');
    desc = map.stringOptional('description', keepWhitespace: true);
    server = ServerConfig(map.map('server'));
    map.unusedKeysCheck();
  }

  String name;
  String desc;
  ServerConfig server;
}

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
