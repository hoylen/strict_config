#!/usr/bin/env dart

///
/// Converts any strict_config config into JSON.
///
/// Example that demonstrates dynamic introspection of a config file.
/// This approach for processing a config file it is possible. But is not
/// recommended for processing normal config files, where you want to be strict
/// about its contents.
///
/// The syntax of a config is different from the JSON syntax, but the config
/// data model is a proper subset of the JSON data model. Features in JSON that
/// are not supported by configs:
///
/// - floating-point or decimal numbers are not supported
/// - nulls are not supported
/// - Duplicate member names are not prohibited in JSON objects
/// - JSON arrays can contain members of different types
/// - JSON arrays can contain other JSON arrays

import 'dart:convert';
import 'dart:io';

import 'package:strict_config/strict_config.dart';

//================================================================

const _indent = '  ';

//----------------------------------------------------------------

String configToJson(String text) {
  final cfg = ConfigMap(text);

  final buf = StringBuffer();
  mapToJson(cfg, buf);

  return buf.toString();
}

//----------------------------------------------------------------

void mapToJson(ConfigMap cfg, StringSink out, {int level = 1}) {
  out.write('\{\n');

  final keys = cfg.keys();

  if (keys.isNotEmpty) {
    var count = 0;
    for (final k in keys) {
      count++;

      out.write('${_indent * level}${encodeString(k)}: ');

      switch (cfg.type(k)) {
        case ConfigType.unavailable:
          assert(false, 'keys never returns an item that does not exist');
          break;

        case ConfigType.boolean:
          out.write(cfg.boolean(k) ? 'true' : 'false');
          break;

        case ConfigType.integer:
          out.write(cfg.integer(k));
          break;

        case ConfigType.string:
          out.write('${encodeString(cfg.string(k))}');
          break;

        case ConfigType.map:
          mapToJson(cfg.map(k), out, level: level + 1);
          break;

        case ConfigType.booleans:
          out.write('[ ');
          var first = true;
          for (final element in cfg.booleans(k)) {
            if (first) {
              first = false;
            } else {
              out.write(', ');
            }
            out.write(element ? 'true' : 'false');
          }
          out.write(' ]');

          break;
        case ConfigType.integers:
          out.write('[ ');
          var first = true;
          for (final element in cfg.integers(k)) {
            if (first) {
              first = false;
            } else {
              out.write(', ');
            }
            out.write(element);
          }
          out.write(' ]');
          break;

        case ConfigType.strings:
          out.write('[ ');
          var first = true;
          for (final element in cfg.strings(k)) {
            if (first) {
              first = false;
            } else {
              out.write(', ');
            }
            out.write(encodeString(element));
          }
          out.write(' ]');
          break;

        case ConfigType.maps:
          out.write('[');
          var first = true;
          for (final element in cfg.maps(k)) {
            if (first) {
              first = false;
              out.write('\n');
            } else {
              out.write(',\n');
            }
            mapToJson(element, out, level: level + 1);
          }
          out.write('\n]');
          break;

        case ConfigType.unknownList:
          out.write('[]\n');
          break;
      }

      // Output comma between members, but not after the last member.

      out.write(count < keys.length ? ',\n' : '\n');
    }
  }

  out.write(_indent * (level - 1));
  out.write('\}');
}

//----------------------------------------------------------------

String encodeString(String str) {
  final encoded = str
      .replaceAll('"', r'\"')
      .replaceAll(r'\', r'\\')
      .replaceAll(r'/', r'\/')
      .replaceAll('\b', r'\b')
      .replaceAll('\f', r'\f')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  // Could also replace non-printable ASCII characters with \u and 4 hex digits.

  return '"$encoded"';
}

//================================================================

class NotRepresentableAsConfig implements Exception {
  // Since not all features in JSON can be represented in strict_config configs,
  // this exception may be thrown during conversion.

  NotRepresentableAsConfig(this.message);

  final String message;

  @override
  String toString() => message;
}

//----------------------------------------------------------------

String jsonToConfig(String text) {
  final data = jsonDecode(text);

  if (data is Map) {
    final buf = StringBuffer();
    mapToConfig(data, buf);
    return buf.toString();
  } else {
    throw NotRepresentableAsConfig('not a JSON object');
  }
}

//----------------------------------------------------------------

void mapToConfig(Map<String, dynamic> m, StringSink out, {int level = 1}) {
  final keys = m.keys;

  var count = 0;
  for (final k in keys) {
    count++;

    out.write('${_indent * level}${encodeString(k)}: ');

    // Output comma between members, but not after the last member.

    out.write(count < keys.length ? ',\n' : '\n');

    throw UnimplementedError(); // TODO: finish implementing this
  }
}

//================================================================

void main(List<String> args) {
  final exeName = Platform.script.pathSegments.last.replaceAll('.dart', '');

  // Process command line

  String filename;
  var reverse = false;
  var help = false;

  if (args.isEmpty) {
    stderr.write('Usage error: missing filename (-h for help)\n');
    exit(2);
  } else if (args.length == 1) {
    if (args[0] == '-h' || args[0] == '--help') {
      help = true;
    } else {
      filename = args[0];
    }
  } else if (args.length == 2) {
    if (args[0] == '-h' ||
        args[0] == '--help' ||
        args[1] == '-h' ||
        args[1] == '--help') {
      help = true;
    }
    if (args[0] == '-r' || args[0] == '--reverse') {
      reverse = true;
      filename = args[1];
    } else {
      stderr.write('Usage error: unexpected argument (-h for help)\n');
      exit(2);
    }
  } else {
    stderr.write('Usage error: too many arguments (-h for help)\n');
    exit(2);
  }

  if (help) {
    stdout.write('''
Usage: $exeName [options] filename
Options:
  -r | --reverse  convert JSON to strict_config config
  -h | --help     show help
''');
    exit(0);
  }

  try {
    // Read in the source text

    final file = File(filename);
    if (!file.existsSync()) {
      stderr.write('$exeName: $filename: file does not exist\n');
      exit(1);
    }
    if (FileSystemEntity.typeSync(filename) != FileSystemEntityType.file) {
      stderr.write('$exeName: $filename: not a file\n');
      exit(1);
    }

    final source = file.readAsStringSync();

    // Convert it

    final converted = reverse ? jsonToConfig(source) : configToJson(source);

    // Output result

    stdout..write(converted)..write('\n');
    exit(0);
  } on FileSystemException catch (e) {
    stderr.write('$exeName: ${e.path}: ${e.message}\n');
    exit(1);
  } on ConfigException catch (e) {
    stderr.write('$exeName: $filename: $e\n');
    exit(1);
  } on NotRepresentableAsConfig catch (e) {
    stderr.write('$exeName: $filename: cannot convert: $e\n');
    exit(1);
  }
}
