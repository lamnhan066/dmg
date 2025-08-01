import 'dart:convert';
import 'dart:io';

import 'package:dmg/src/utils.dart';

/// Submit DMG for notarization with error handling
String? runNotaryTool(String dmg, String notaryProfile, bool isVerbose) {
  try {
    if (!File(dmg).existsSync()) {
      log.warning('DMG file does not exist: $dmg');
      return null;
    }

    log.info('Using notary profile: $notaryProfile');

    final result = Process.runSync('xcrun', [
      'notarytool',
      'submit',
      dmg,
      '--keychain-profile',
      notaryProfile,
    ]);

    if (result.exitCode != 0) {
      log.warning(
          'Notarization submission failed with exit code ${result.exitCode}');
      log.warning('Error: ${result.stderr}');
      return null;
    }

    final output = result.stdout as String;

    if (isVerbose) {
      log.info(output);
    }

    return output;
  } catch (e) {
    log.warning('Exception during notarization submission: $e');
    return null;
  }
}

/// Waits for and checks notary state
Future<bool> waitAndCheckNotaryState(
  String notaryOutput,
  String dmg,
  String notaryProfile,
  String notaryId,
  File logFile,
  bool isVerbose,
) async {
  bool success = false;
  do {
    await Future.delayed(const Duration(seconds: 30));

    log.info('Checking for the notary result...');
    Process.runSync('xcrun', [
      'notarytool',
      'log',
      notaryId,
      '--keychain-profile',
      notaryProfile,
      logFile.path,
    ]);

    if (!logFile.existsSync()) {
      log.info('Still in processing. Waiting...');
      continue;
    }

    final json = logFile.readAsStringSync();

    if (isVerbose) {
      log.info(json);
    }

    final decoded = jsonDecode(json);
    if (decoded['status'] == 'Accepted') {
      success = true;
      log.info('Notarized');
    } else {
      log.warning('Notarize error with message: ${decoded['statusSummary']}');
      log.warning('Look at ${logFile.path} for more details');
    }

    break;
  } while (true);

  return success;
}
