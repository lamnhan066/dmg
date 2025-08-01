import 'dart:io';

import 'utils.dart';

/// Run Flutter release build with better error handling
bool runFlutterRelease(bool isVerbose, String releasePath) {
  try {
    log.info('Starting Flutter macOS release build...');

    final r = Process.runSync('flutter', [
      'build',
      'macos',
      '--release',
      '--obfuscate',
      '--split-debug-info=${joinPaths(['.', 'build', 'debug-macos-info'])}',
    ]);

    if (r.exitCode != 0) {
      log.warning('Flutter build failed with exit code ${r.exitCode}');
      log.warning('Error: ${r.stderr}');
      if (isVerbose) {
        log.info('Output: ${r.stdout}');
      }
      return false;
    }

    // Check if the app was actually built
    final appPath = getAppPath(releasePath);
    final success = appPath.isNotEmpty;

    if (!success || isVerbose) {
      log.info(r.stdout);
    }

    if (success) {
      log.info('Flutter build completed successfully');
    } else {
      log.warning('Flutter build completed but no .app file was found');
    }

    return success;
  } catch (e) {
    log.warning('Exception during Flutter build: $e');
    return false;
  }
}

/// Delete build of macos with error handling
bool runCleanBuild(bool isVerbose) {
  try {
    final build = Directory(joinPaths(['.', 'build', 'macos']));
    if (!build.existsSync()) {
      if (isVerbose) {
        log.info('Build directory does not exist, nothing to clean');
      }
      return true;
    }

    build.deleteSync(recursive: true);
    log.info('Build directory cleaned successfully');
    return true;
  } catch (e) {
    log.warning('Failed to clean build directory: $e');
    return false;
  }
}
