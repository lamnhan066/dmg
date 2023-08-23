// ignore_for_file: avoid_print

library dmg;

import 'dart:convert';
import 'dart:io';

import 'package:dmg/generate_setting.dart';

/// no-doc
String getSettingPath(String? setting, String? licensePath) {
  if (setting != null) return setting;

  final file = File('./.build_dmg_setting.py');
  file.writeAsStringSync(generateSetting(licensePath));
  return file.path;
}

/// no-doc
void runDmgBuild(String setting, String app, String dmg, String volumeName) {
  Process.runSync(
      'dmgbuild', ['-s', setting, '-D', 'app=$app', volumeName, dmg]);
}

/// no-doc
void runCodeSign(String dmg, String signCertificate) {
  Process.runSync('codesign',
      ['--sign', signCertificate, dmg, '--options=runtime', '--force']);
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

    Process.runSync('xcrun', [
      'notarytool',
      'log',
      noratyId,
      '--keychain-profile',
      notaryProfile,
      logFile.path,
    ]);

    if (!logFile.existsSync()) {
      continue;
    }

    final json = logFile.readAsStringSync();
    final decoded = jsonDecode(json);
    if (decoded['status'] == 'Accepted') {
      success = true;
      print('Notarized.');
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
