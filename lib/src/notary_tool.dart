import 'dart:convert';
import 'dart:io';

import 'package:dmg/src/utils.dart';

/// no-doc
String runNotaryTool(String dmg, String notaryProfile, bool isVerbose) {
  log.info('Using notary profile: $notaryProfile');

  final result = Process.runSync('xcrun', [
    'notarytool',
    'submit',
    dmg,
    '--keychain-profile',
    notaryProfile,
  ]);

  final output = result.stdout as String;

  if (isVerbose) {
    log.info(output);
  }

  return output;
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

    log.info('Checking for the notary result...');
    Process.runSync('xcrun', [
      'notarytool',
      'log',
      noratyId,
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
