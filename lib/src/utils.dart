import 'dart:io';

import 'package:dmg/generate_settings.dart';
import 'package:logging/logging.dart';

final log = Logger.root..level = Level.ALL;

/// Path separator
final separator = Platform.pathSeparator;

/// join path
String joinPaths(List<String> paths) {
  return paths.join(separator);
}

/// no-doc
String getParentAppPath(String path) {
  return (path.split(separator)..removeLast()).join(separator);
}

/// no-doc
String getAppName(String path) {
  final name = path.split(separator).last;
  return (name.split('.')..removeLast()).join('.');
}

/// Get path of .app file in the release path
String getAppPath(String releasePath) {
  final dir = Directory(releasePath);
  if (!dir.existsSync()) return '';

  for (final file in dir.listSync()) {
    if (file.path.endsWith('.app')) {
      return file.path;
    }
  }
  return '';
}

/// no-doc
String getSettingsPath(
    String appParentPath, String? settings, String? licensePath) {
  if (settings != null) return settings;

  final file = File(joinPaths([appParentPath, 'dmgbuild_settings.py']));
  file.writeAsStringSync(generateSettings(licensePath));
  return file.path;
}
