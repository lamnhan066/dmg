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
