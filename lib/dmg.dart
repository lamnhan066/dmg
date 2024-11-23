// ignore_for_file: avoid_print

library dmg;

import 'dart:convert';
import 'dart:io';

import 'package:dmg/generate_settings.dart';

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

/// no-doc
void _codesign(
  String signCertificate,
  String filePath, {
  bool isRuntime = true,
  bool isDeep = false,
  bool isVerbose = false,
}) {
  final r = Process.runSync('codesign', [
    '--sign',
    signCertificate,
    filePath,
    '--force',
    '--timestamp',
    if (isDeep) '--deep',
    if (isRuntime) '--options=runtime',
  ]);
  if (isVerbose) {
    print(r.stdout);
  }
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

/// Run Flutter release
void runFlutterRelease(bool isVerbose) {
  final r = Process.runSync('flutter', [
    'build',
    'macos',
    '--release',
    '--obfuscate',
    '--split-debug-info=${joinPaths(['.', 'build', 'debug-macos-info'])}',
  ]);
  if (isVerbose) {
    print(r.stdout);
  }
}

/// no-doc
void runCodeSignApp(String signCertificate, String appPath, bool isVerbose) {
  _codesign(signCertificate, appPath, isDeep: true, isVerbose: isVerbose);
}

/// no-doc
String getSettingsPath(
    String appParentPath, String? settings, String? licensePath) {
  if (settings != null) return settings;

  final file = File(joinPaths([appParentPath, 'dmgbuild_settings.py']));
  file.writeAsStringSync(generateSettings(licensePath));
  return file.path;
}

/// no-doc
void runDmgBuild(String settings, String app, String dmg, String volumeName,
    bool isVerbose) {
  final r = Process.runSync(
      'dmgbuild', ['-s', settings, '-D', 'app=$app', volumeName, dmg]);
  if (isVerbose) {
    print(r.stdout);
  }
}

/// no-doc
void runCodeSignDmg(String dmg, String signCertificate, bool isVerbose) {
  _codesign(signCertificate, dmg, isDeep: false, isVerbose: isVerbose);
}

/// no-doc
String runNotaryTool(String dmg, bool isVerbose) {
  final o = Process.runSync('xcrun', [
    'notarytool',
    'submit',
    dmg,
    '--keychain-profile',
    'NotaryProfile',
  ]).stdout;
  if (isVerbose) {
    print(o);
  }
  return o;
}

/// no-doc
Future<bool> waitAndCheckNoratyState(
  String notaryOutput,
  String dmg,
  String notaryProfile,
  String noratyId,
  File logFile,
  bool isVerbose,
) async {
  bool success = false;
  do {
    await Future.delayed(const Duration(seconds: 30));

    print('Checking for the notary result...');
    Process.runSync('xcrun', [
      'notarytool',
      'log',
      noratyId,
      '--keychain-profile',
      notaryProfile,
      logFile.path,
    ]);

    if (!logFile.existsSync()) {
      print('Still in processing. Waiting...');
      continue;
    }

    final json = logFile.readAsStringSync();

    if (isVerbose) {
      print(json);
    }

    final decoded = jsonDecode(json);
    if (decoded['status'] == 'Accepted') {
      success = true;
      print('Notarized');
    } else {
      print('Notarize error with message: ${decoded['statusSummary']}');
      print('Look at ${logFile.path} for more details');
    }

    break;
  } while (true);

  return success;
}

/// no-doc
void runStaple(String dmg, bool isVerbose) {
  final r = Process.runSync('xcrun', ['stapler', 'staple', dmg]);
  if (isVerbose) {
    print(r.stdout);
  }
}

/// Delete build of macos
void cleanBuild(bool isVerbose) {
  final build = Directory(joinPaths(['.', 'build', 'macos']));
  if (!build.existsSync()) return;

  build.deleteSync(recursive: true);
}
