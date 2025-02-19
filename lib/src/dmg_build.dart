import 'dart:io';

import 'package:dmg/src/utils.dart';

/// no-doc
void runDmgBuild(String settings, String app, String dmg, String volumeName,
    bool isVerbose) {
  final r = Process.runSync(
      'dmgbuild', ['-s', settings, '-D', 'app=$app', volumeName, dmg]);
  if (isVerbose) {
    log.info(r.stdout);
  }
}
