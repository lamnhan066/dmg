import 'dart:convert';
import 'dart:io';

/// no-doc
String runNotaryTool(String dmg, String notaryProfile, bool isVerbose) {
  print('Using notary profile: $notaryProfile');

  final result = Process.runSync('xcrun', [
    'notarytool',
    'submit',
    dmg,
    '--keychain-profile',
    notaryProfile,
  ]);

  final output = result.stdout as String;

  if (isVerbose) {
    print(output);
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
