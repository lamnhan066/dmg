import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'utils.dart';

/// Run Flutter release build with real-time logging to console
Future<bool> runFlutterRelease(
    bool isVerbose, String releasePath, String? flavor) async {
  try {
    log.info('Starting Flutter macOS release build...');

    final process = await Process.start(
      'flutter',
      [
        'build',
        'macos',
        '--release',
        if (flavor != null) '--flavor',
        if (flavor != null) flavor,
        '--obfuscate',
        '--split-debug-info=${joinPaths(['.', 'build', 'debug-macos-info'])}',
        if (isVerbose) '--verbose',
      ],
    );

    process.stdout.transform(utf8.decoder).forEach((line) {
      log.info(line);
    });

    process.stderr.transform(utf8.decoder).forEach((line) {
      log.warning(line);
    });

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      log.warning('Flutter build failed with exit code $exitCode');
      return false;
    }

    await Future.delayed(Duration(milliseconds: 500));

    final appPath = getAppPath(releasePath);
    final success = appPath.isNotEmpty;

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
