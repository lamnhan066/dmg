import 'dart:io';

import 'package:dmg/src/generate_settings.dart';
import 'package:logging/logging.dart';

final log = Logger.root..level = Level.ALL;

/// Path separator
final separator = Platform.pathSeparator;

/// Check if a command is available in the system PATH
bool isCommandAvailable(String command) {
  try {
    final result = Process.runSync('which', [command]);
    return result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty;
  } catch (e) {
    log.warning('Error checking command availability for "$command": $e');
    return false;
  }
}

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
  try {
    final dir = Directory(releasePath);
    if (!dir.existsSync()) {
      log.warning('Release path does not exist: $releasePath');
      return '';
    }

    for (final file in dir.listSync()) {
      if (file.path.endsWith('.app')) {
        return file.path;
      }
    }
    log.warning('No .app file found in: $releasePath');
    return '';
  } catch (e) {
    log.warning('Error reading directory "$releasePath": $e');
    return '';
  }
}

/// Generate or return path to dmgbuild settings file
String getSettingsPath(
    String appParentPath, String? settings, String? licensePath) {
  if (settings != null) {
    if (!File(settings).existsSync()) {
      log.warning('Custom settings file does not exist: $settings');
      log.info('Using default settings instead');
    } else {
      return settings;
    }
  }

  try {
    final file = File(joinPaths([appParentPath, 'dmgbuild_settings.py']));
    file.writeAsStringSync(generateSettings(licensePath));
    log.info('Generated default settings file: ${file.path}');
    return file.path;
  } catch (e) {
    log.warning('Error creating settings file: $e');
    throw Exception('Failed to create settings file: $e');
  }
}

/// Validate system requirements before starting
bool validateSystemRequirements(bool requiresSigning) {
  final requirements = [
    {'command': 'flutter', 'description': 'Flutter SDK', 'required': true},
    {
      'command': 'dmgbuild',
      'description': 'DMG build tool (install with: pip install dmgbuild)',
      'required': true
    },
    {
      'command': 'xcrun',
      'description': 'Xcode Command Line Tools',
      'required': requiresSigning
    },
    {
      'command': 'codesign',
      'description': 'Code signing tools',
      'required': requiresSigning
    },
    {
      'command': 'security',
      'description': 'Keychain access',
      'required': requiresSigning
    },
  ];

  bool allValid = true;
  for (final req in requirements) {
    final isRequired = req['required'] as bool;
    final command = req['command'] as String;
    if (isRequired && !isCommandAvailable(command)) {
      log.warning('Missing requirement: ${req['description']}');
      allValid = false;
    }
  }

  return allValid;
}

/// Check if the current directory is a valid Flutter project
bool isFlutterProject() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    return false;
  }

  try {
    final content = pubspecFile.readAsStringSync();
    return content.contains('flutter:') || content.contains('sdk: flutter');
  } catch (e) {
    log.warning('Error reading pubspec.yaml: $e');
    return false;
  }
}

/// Check if macOS platform is supported in the Flutter project
bool isMacOSSupported() {
  final macosDir = Directory(joinPaths(['macos']));
  return macosDir.existsSync();
}
