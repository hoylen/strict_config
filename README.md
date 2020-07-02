Package for extracting values from a config.

## Features

- Built-in validation to improve error checking:
    - Configuration items can be mandatory or optional.
    - Detects unexpected configuration items.
    - String values trimmed of leading and trailing whitespace by default.
    - Empty and blank string values are rejected by default.
    - Maximum and/or minimum ranges can be specified for integer values.
    - Permitted values can be specified to restrict string values.
    - Default values can be specified for boolean, integer and string values.
    - Empty lists can be prohibited.
    
- Configs can contain logging levels to make using the _logging_
  package easier.

- Does not use annotations to allow programs to be compiled with
  _dart2native_.
  
## Example

Example config:

```yaml
name: "Example"
description: "An example config"

server:
  host: "localhost"
  port: 8080
  tls: true
```

Program to read the example config:

```dart
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
    port = map.integer('port', min: 1, max: 65535, defaultValue: tls ? 443 : 80);
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
```

## Usage

Create a `ConfigMap` from the text representation of a config. The
text is usually from a config file.

Extract expected values from config maps using the extraction methods.
 
- For mandatory scalar values,  use `boolean`, `integer` and `string`.
- For optional scalar values, use `booleanOptional`, `integerOptional` and `stringOptional`.
- For values which are config maps, use `map` or `mapOptional`.
- For values which are lists use `booleans`, `integers`, `strings` and `maps`.
- If the list is optional, use `booleansOptional`, `integersOptional`, `stringsOptional` and `mapsOptional`.

Use `unusedKeysCheck` to check a config map for unexpected keys. 

See the
[API reference](https://pub.dev/documentation/strict_config/latest/)
for details.

## Configs

### Data model

A **config** is a _config map_ at the top-level.

A **config map** is an unordered collection of zero or more key-value
pairs.

The **keys** are case-sensitive strings.  Within the context of each
_config map_, the keys must be unique.

The **values** must be one of these types:

- boolean: true or false
- integers
- strings: optionally enclosed in double quotes
- config maps
- list of booleans
- list of integers
- list of strings
- list of config maps

### Syntax

A subset of YAML is used as the syntax of a _config_.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoylen/strict_config