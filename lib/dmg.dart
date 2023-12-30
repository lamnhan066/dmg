// ignore_for_file: avoid_print

library dmg;

import 'dart:convert';
import 'dart:io';

import 'package:dmg/generate_setting.dart';

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
}) {
  Process.runSync('codesign', [
    '--sign',
    signCertificate,
    filePath,
    '--force',
    '--timestamp',
    if (isDeep) '--deep',
    if (isRuntime) '--options=runtime',
  ]);
}

/// Get path of .app file in the release path
String getAppPath(String releasePath) {
  final dir = Directory(releasePath);
  for (final file in dir.listSync()) {
    if (file.path.endsWith('.app')) {
      return file.path;
    }
  }
  return '';
}

/// Run Flutter release
void runFlutterRelease() {
  Process.runSync('flutter', [
    'build',
    'macos',
    '--release',
    '--obfuscate',
    '--split-debug-info=${joinPaths(['.', 'build', 'debug-macos-info'])}',
  ]);
}

/// no-doc
void runCodeSignApp(String signCertificate, String appPath) {
  _codesign(signCertificate, appPath, isDeep: true);
}

/// no-doc
String getSettingsPath(
    String appParentPath, String? setting, String? licensePath) {
  if (setting != null) return setting;

  final file = File(joinPaths([appParentPath, 'dmgbuild_settings.py']));
  file.writeAsStringSync(generateSettings(licensePath));
  return file.path;
}

/// no-doc
void runDmgBuild(String setting, String app, String dmg, String volumeName) {
  Process.runSync(
      'dmgbuild', ['-s', setting, '-D', 'app=$app', volumeName, dmg]);
}

/// no-doc
void runCodeSignDmg(String dmg, String signCertificate) {
  _codesign(signCertificate, dmg, isDeep: false);
}

/// no-doc
String runNotaryTool(String dmg) {
  return Process.runSync('xcrun', [
    'notarytool',
    'submit',
    dmg,
    '--keychain-profile',
    'NotaryProfile',
  ]).stdout;
}

/// no-doc
Future<bool> waitAndCheckNoratyState(
  String notaryOutput,
  String dmg,
  String notaryProfile,
  String noratyId,
  File logFile,
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
void runStaple(String dmg) {
  Process.runSync('xcrun', ['stapler', 'staple', dmg]);
}

/// Delete build of macos
void cleanBuild() {
  final build = Directory(joinPaths(['.', 'build', 'macos']));
  if (!build.existsSync()) return;

  build.deleteSync(recursive: true);
}
