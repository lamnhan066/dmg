import 'dart:io';

/// no-doc
void runCodeSignApp(String signCertificate, String appPath, bool isVerbose) {
  _codesign(signCertificate, appPath, isDeep: true, isVerbose: isVerbose);
}

/// no-doc
void runCodeSignDmg(String dmg, String signCertificate, bool isVerbose) {
  _codesign(signCertificate, dmg, isDeep: false, isVerbose: isVerbose);
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
