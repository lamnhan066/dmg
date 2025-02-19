import 'dart:io';

/// no-doc
void runCodeSignApp(String signCertificate, String appPath, bool isVerbose) {
  _codesign(signCertificate, appPath, isDeep: true, isVerbose: isVerbose);
}

/// no-doc
void runCodeSignDmg(String dmg, String signCertificate, bool isVerbose) {
  _codesign(signCertificate, dmg, isDeep: false, isVerbose: isVerbose);
}

String getSignCertificate(String? signCertificate) {
  // Find the Developer ID certificate if not provided
  if (signCertificate == null || signCertificate.isEmpty) {
    final result = Process.runSync(
      'security',
      ['find-identity', '-v', '-p', 'codesigning'],
    );
    final identities = result.stdout as String;

    // Extract all Developer ID certificates
    final matches =
        RegExp(r'"Developer ID Application:.*?"').allMatches(identities);
    final certificates =
        matches.map((m) => m.group(0)?.replaceAll('"', '') ?? '').toList();

    if (certificates.isEmpty) {
      print('Error: No Developer ID certificate found.');
      exit(1);
    } else if (certificates.length == 1) {
      signCertificate = certificates.first;
    } else {
      print('Multiple Developer ID certificates found:');
      for (var i = 0; i < certificates.length; i++) {
        print('${i + 1}: ${certificates[i]}');
      }
      stdout.write('Select a certificate (1-${certificates.length}): ');
      final selection = int.tryParse(stdin.readLineSync() ?? '');
      if (selection == null ||
          selection < 1 ||
          selection > certificates.length) {
        print('Invalid selection.');
        exit(1);
      }
      signCertificate = certificates[selection - 1];
    }
  }

  return signCertificate;
}

/// no-doc
void _codesign(
  String signCertificate,
  String filePath, {
  bool isRuntime = true,
  bool isDeep = false,
  bool isVerbose = false,
}) {
  // Run the codesign command
  final r = Process.runSync(
    'codesign',
    [
      '--force',
      '--timestamp',
      '--strict',
      '-s',
      signCertificate,
      '--entitlements',
      'macos/Runner/Release.entitlements',
      filePath,
      if (isDeep) '--deep',
      if (isRuntime) '--options=runtime',
      if (isVerbose) '-vvv',
    ],
  );

  // Check the result
  if (r.exitCode == 0) {
    print('Code signing successful!');
  } else {
    print('Code signing failed: ${r.stderr}');
    exit(1);
  }

  if (isVerbose) {
    print(r.stdout);
  }
}
