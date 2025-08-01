import 'dart:io';

import 'package:dmg/src/utils.dart';

/// Build DMG with error handling
bool runDmgBuild(String settings, String app, String dmg, String volumeName,
    bool isVerbose) {
  try {
    // Validate inputs
    if (!File(settings).existsSync()) {
      log.warning('Settings file does not exist: $settings');
      return false;
    }

    if (!Directory(app).existsSync()) {
      log.warning('App bundle does not exist: $app');
      return false;
    }

    final r = Process.runSync(
        'dmgbuild', ['-s', settings, '-D', 'app=$app', volumeName, dmg]);

    if (r.exitCode == 0) {
      if (isVerbose) {
        log.info(r.stdout);
      }
      log.info('DMG build successful');
      return true;
    } else {
      log.warning('DMG build failed with exit code ${r.exitCode}');
      log.warning('Error: ${r.stderr}');
      if (isVerbose) {
        log.info('Output: ${r.stdout}');
      }
      return false;
    }
  } catch (e) {
    log.warning('Exception during DMG build: $e');
    return false;
  }
}
