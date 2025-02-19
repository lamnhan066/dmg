import 'dart:io';

import 'utils.dart';

/// Run Flutter release
bool runFlutterRelease(bool isVerbose, String releasePath) {
  final r = Process.runSync('flutter', [
    'build',
    'macos',
    '--release',
    '--obfuscate',
    '--split-debug-info=${joinPaths(['.', 'build', 'debug-macos-info'])}',
  ]);

  final appPath = getAppPath(releasePath);

  if (appPath == '' || isVerbose) {
    log.info(r.stdout);
  }

  return appPath.isNotEmpty;
}

/// Delete build of macos
void cleanBuild(bool isVerbose) {
  final build = Directory(joinPaths(['.', 'build', 'macos']));
  if (!build.existsSync()) return;

  build.deleteSync(recursive: true);
}
