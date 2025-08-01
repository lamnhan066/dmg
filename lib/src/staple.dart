import 'dart:io';

import 'package:dmg/src/utils.dart';

/// Staple the notarized DMG with error handling
bool runStaple(String dmg, bool isVerbose) {
  try {
    if (!File(dmg).existsSync()) {
      log.warning('DMG file does not exist: $dmg');
      return false;
    }

    final r = Process.runSync('xcrun', ['stapler', 'staple', dmg]);

    if (r.exitCode == 0) {
      if (isVerbose) {
        log.info(r.stdout);
      }
      log.info('Stapling successful');
      return true;
    } else {
      log.warning('Stapling failed with exit code ${r.exitCode}');
      log.warning('Error: ${r.stderr}');
      if (isVerbose) {
        log.info('Output: ${r.stdout}');
      }
      return false;
    }
  } catch (e) {
    log.warning('Exception during stapling: $e');
    return false;
  }
}
