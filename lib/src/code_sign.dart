import 'dart:io';

import 'package:dmg/src/utils.dart';

/// Code sign the app bundle
bool runCodeSignApp(String signCertificate, String appPath, bool isVerbose) {
  return _codesign(signCertificate, appPath,
      isDeep: true, isVerbose: isVerbose);
}

/// Code sign the DMG file
bool runCodeSignDmg(String dmg, String signCertificate, bool isVerbose) {
  return _codesign(signCertificate, dmg, isDeep: false, isVerbose: isVerbose);
}

/// Get signing certificate, with better error handling
String? getSignCertificate(String? signCertificate) {
  // Find the Developer ID certificate if not provided
  if (signCertificate == null || signCertificate.isEmpty) {
    try {
      final result = Process.runSync(
        'security',
        ['find-identity', '-v', '-p', 'codesigning'],
      );

      if (result.exitCode != 0) {
        log.warning('Failed to query keychain for certificates');
        return null;
      }

      final identities = result.stdout as String;

      // Extract all Developer ID certificates
      final matches =
          RegExp(r'"Developer ID Application:.*?"').allMatches(identities);
      final certificates =
          matches.map((m) => m.group(0)?.replaceAll('"', '') ?? '').toList();

      if (certificates.isEmpty) {
        log.warning('Error: No Developer ID certificate found.');
        return null;
      } else if (certificates.length == 1) {
        signCertificate = certificates.first;
        log.info('Auto-selected certificate: $signCertificate');
      } else {
        log.info('Multiple Developer ID certificates found:');
        for (var i = 0; i < certificates.length; i++) {
          log.info('${i + 1}: ${certificates[i]}');
        }
        stdout.write('Select a certificate (1-${certificates.length}): ');
        final input = stdin.readLineSync();
        final selection = int.tryParse(input ?? '');
        if (selection == null ||
            selection < 1 ||
            selection > certificates.length) {
          log.warning('Invalid selection: $input');
          return null;
        }
        signCertificate = certificates[selection - 1];
      }
    } catch (e) {
      log.warning('Error retrieving certificates: $e');
      return null;
    }
  }

  return signCertificate;
}

/// Code signing function with better error handling
bool _codesign(
  String signCertificate,
  String filePath, {
  bool isRuntime = true,
  bool isDeep = false,
  bool isVerbose = false,
  String entitlementsPath = 'macos/Runner/Release.entitlements',
}) {
  try {
    // Validate inputs
    if (signCertificate.isEmpty) {
      log.warning('No signing certificate provided');
      return false;
    }

    if (!File(filePath).existsSync() && !Directory(filePath).existsSync()) {
      log.warning('File/directory to sign does not exist: $filePath');
      return false;
    }

    if (!File(entitlementsPath).existsSync()) {
      log.warning('Entitlements file does not exist: $entitlementsPath');
      return false;
    }

    final args = [
      '--force',
      '--timestamp',
      '--options',
      if (isRuntime) 'runtime' else 'none',
      '-s',
      signCertificate,
      if (isDeep) '--deep',
      '--entitlements',
      entitlementsPath,
      if (isVerbose) '-vvv',
      filePath,
    ];

    log.info('Running `codesign` with arguments: ${args.join(' ')}');

    // Run the codesign command
    final r = Process.runSync('codesign', args);

    // Check the result
    if (r.exitCode == 0) {
      log.info('Code signing successful!');
      if (isVerbose) {
        log.info(r.stdout);
      }
      return true;
    } else {
      log.warning('Code signing failed with exit code ${r.exitCode}');
      log.warning('Error: ${r.stderr}');
      if (isVerbose) {
        log.info('Output: ${r.stdout}');
      }
      return false;
    }
  } catch (e) {
    log.warning('Exception during code signing: $e');
    return false;
  }
}
