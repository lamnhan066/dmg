library dmg;

import 'dart:io';

import 'package:dmg/src/code_sign.dart';
import 'package:dmg/src/dmg_build.dart';
import 'package:dmg/src/flutter_release.dart';
import 'package:dmg/src/notary_tool.dart';
import 'package:dmg/src/pubspec_config.dart';
import 'package:dmg/src/staple.dart';
import 'package:dmg/src/utils.dart';

Future<int> execute(List<String> args) async {
  try {
    final parser = createDmgArgParser();

    final param = parser.parse(args);

    if (param['help'] ?? false) {
      log.info(parser.usage);
      return 0;
    }

    final config = resolveDmgConfig(param);

    final releasePath = joinPaths([
      '.',
      'build',
      'macos',
      'Build',
      'Products',
      if (config.flavor != null) 'Release-${config.flavor}' else 'Release',
    ]);

    final settings = config.settings;
    final licensePath = config.licensePath;
    var signCertificate = config.signCertificate;
    var notaryProfile = config.notaryProfile;
    final runBuild = config.build;
    final cleanBuild = config.cleanBuild;
    final runSign = config.sign;
    final runNotarization = config.notarization;
    final isVerbose = config.verbose;

    // Validate inputs
    if (licensePath != null && !File(licensePath).existsSync()) {
      log.warning('License file does not exist: $licensePath');
      return 1;
    }

    if (settings != null && !File(settings).existsSync()) {
      log.warning('Settings file does not exist: $settings');
      return 1;
    }

    // Validate we're in a Flutter project
    if (!isFlutterProject()) {
      log.warning(
          'No valid Flutter project found. Are you in a Flutter project directory?');
      return 1;
    }

    // Check if macOS is supported
    if (!isMacOSSupported()) {
      log.warning('macOS platform is not enabled for this Flutter project.');
      log.info(
          'Enable macOS support with: flutter config --enable-macos-desktop');
      log.info('Then run: flutter create --platforms=macos .');
      return 1;
    }

    // Validate system requirements
    if (!validateSystemRequirements(runSign)) {
      log.warning(
          'System requirements not met. Please install missing dependencies.');
      return 1;
    }

    if (runBuild) {
      if (cleanBuild) {
        log.info('Cleaning build...');
        if (!runCleanBuild(isVerbose)) {
          log.warning('Failed to clean build directory');
          // Continue anyway, as this is not a critical failure
        }
        log.info('Cleaned');
      }

      log.info('Flutter release...');
      if (!await runFlutterRelease(isVerbose, releasePath, config.flavor)) {
        log.warning(
            'Error: `flutter build macos --release` failed. Please check your project settings and logs for further details.');
        log.warning('Exit');
        return 1;
      }
      log.info('Released');
    }

    final appPath = getAppPath(releasePath);
    if (appPath == '') {
      log.warning('Cannot get the app path from "$releasePath"');
      log.warning(
          'Please run `flutter build macos --release` first or add a flag `--build` to the command.');
      log.warning('Exit');
      return 1;
    }

    final appParentPath = getParentAppPath(appPath);
    final appName = getAppName(appPath);
    final dmg = '$appParentPath$separator$appName.dmg';
    final settingsPath = getSettingsPath(appParentPath, settings, licensePath);

    if (!isCommandAvailable('dmgbuild')) {
      log.warning('`dmgbuild` not found. Install via `pip3 install dmgbuild`.');
      return 1;
    }

    if (runSign) {
      final certificate = getSignCertificate(signCertificate);
      if (certificate == null) {
        log.warning('Failed to get signing certificate');
        return 1;
      }
      signCertificate = certificate;

      log.info('Using signing identity: $signCertificate');

      log.info('Code signing for the APP...');
      if (!runCodeSignApp(signCertificate, appPath, isVerbose)) {
        log.warning('Failed to code sign the app');
        return 1;
      }
      log.info('Signed');
    } else {
      log.info('Skipping code signing (--no-sign)');
    }

    log.info('Building DMG...');
    if (!runDmgBuild(settingsPath, appPath, dmg, appName, isVerbose)) {
      log.warning('Failed to build DMG');
      return 1;
    }
    log.info('Built');

    if (runSign) {
      log.info('Code signing for the DMG...');
      if (!runCodeSignDmg(dmg, signCertificate!, isVerbose)) {
        log.warning('Failed to code sign the DMG');
        return 1;
      }
      log.info('Signed');
    } else {
      log.info('Skipping DMG code signing (--no-sign)');
    }

    if (runSign && runNotarization) {
      log.info('Notarizing...');
      final notaryOutput = runNotaryTool(dmg, notaryProfile, isVerbose);
      if (notaryOutput == null) {
        log.warning('Failed to submit for notarization');
        return 1;
      }

      final regex = RegExp(r'id: (\w+-\w+-\w+-\w+-\w+)');
      final match = regex.firstMatch(notaryOutput);
      if (match == null) {
        log.warning('The `id` not found from notary output:');
        log.warning(notaryOutput);
        return 1;
      }

      final notaryId = match.group(1);
      if (notaryId == null) {
        log.warning('The matched `id` not found from notary output:');
        log.warning(notaryOutput);
        return 1;
      }

      final dmgPath = (dmg.split(separator)..removeLast()).join(separator);
      final notaryLogPath = joinPaths([dmgPath, 'notary_log.json']);

      if (isVerbose) {
        log.info('Notary log path: $notaryLogPath');
      }

      final logFile = File(notaryLogPath);

      final success = await waitAndCheckNotaryState(
        notaryOutput,
        dmg,
        notaryProfile,
        notaryId,
        logFile,
        isVerbose,
      );

      if (success) {
        log.info('Stapling...');
        if (!runStaple(dmg, isVerbose)) {
          log.warning('Failed to staple the DMG');
          return 1;
        }
        log.info('Stapled');
        log.info('Everything is done. Output: $dmg');
      } else {
        log.warning('Done with error.');
        return 1;
      }
    } else {
      if (!runSign) {
        log.info('Skipping notarization (requires signing)');
      } else {
        log.info('Skipping notarization (--no-notarization)');
      }
      log.info('DMG created successfully. Output: $dmg');
    }

    return 0;
  } catch (e, stackTrace) {
    log.warning('Unexpected error occurred: $e');
    if (args.contains('--verbose') || args.contains('-v')) {
      log.warning('Stack trace: $stackTrace');
    }
    return 1;
  }
}
