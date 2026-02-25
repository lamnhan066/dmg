library dmg;

import 'dart:io';

import 'package:args/args.dart';
import 'package:dmg/src/code_sign.dart';
import 'package:dmg/src/dmg_build.dart';
import 'package:dmg/src/flutter_release.dart';
import 'package:dmg/src/notary_tool.dart';
import 'package:dmg/src/staple.dart';
import 'package:dmg/src/utils.dart';

Future<int> execute(List<String> args) async {
  try {
    final parser = ArgParser()
      ..addOption(
        'sign-certificate',
        help: 'The certificate that you are signed. Ex: `Developer ID Application: Your Company`',
      )
      ..addOption(
        'settings',
        help: 'Path of the modified `settings.py` file. Use default setting if not provided. '
            'Read more on https://dmgbuild.readthedocs.io/en/latest/settings.html',
      )
      ..addOption(
        'flavor',
        help: 'The flavor to build for, if your project has flavors configured.',
      )
      ..addOption(
        'license-path',
        help: 'Path of the license file',
      )
      ..addOption(
        'notary-profile',
        defaultsTo: 'NotaryProfile',
        help: 'Name of the notary profile that created by `xcrun notarytool store-credentials`',
      )
      ..addFlag(
        'build',
        help: 'Automatically run `flutter build macos --release --obfuscate --split-debug-info=debug-macos-info`.',
        defaultsTo: true,
      )
      ..addFlag(
        'clean-build',
        help: 'Clean the `build/macos` folder before running the `build` command. '
            'This flag will be ignored if the `build` flag is set to `--no-build`.',
        defaultsTo: true,
      )
      ..addFlag(
        'sign',
        help: 'Code sign the .app and .dmg files. Set to --no-sign to skip signing for test builds.',
        defaultsTo: true,
      )
      ..addFlag(
        'notarization',
        help: 'Submit for notarization and staple. Set to --no-notarization to skip notarization for test builds. '
            'This flag will be ignored if the `sign` flag is set to `--no-sign`.',
        defaultsTo: true,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Show verbose logs',
        defaultsTo: false,
      )
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show helps',
        defaultsTo: false,
      );

    final param = parser.parse(args);

    if (param['help'] ?? false) {
      log.info(parser.usage);
      return 0;
    }

    final releasePath = joinPaths([
      '.',
      'build',
      'macos',
      'Build',
      'Products',
      if (param['flavor'] != null) 'Release-${param['flavor']}' else 'Release',
    ]);

    final settings = param['settings'] as String?;
    final licensePath = param['license-path'] as String?;
    var signCertificate = param['sign-certificate'] as String?;
    var notaryProfile = param['notary-profile'] as String;
    final runBuild = param['build'] as bool;
    final cleanBuild = param['clean-build'] as bool;
    final runSign = param['sign'] as bool;
    final runNotarization = param['notarization'] as bool;
    final isVerbose = param['verbose'] as bool;

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
      log.warning('No valid Flutter project found. Are you in a Flutter project directory?');
      return 1;
    }

    // Check if macOS is supported
    if (!isMacOSSupported()) {
      log.warning('macOS platform is not enabled for this Flutter project.');
      log.info('Enable macOS support with: flutter config --enable-macos-desktop');
      log.info('Then run: flutter create --platforms=macos .');
      return 1;
    }

    // Validate system requirements
    if (!validateSystemRequirements(runSign)) {
      log.warning('System requirements not met. Please install missing dependencies.');
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
      if (!await runFlutterRelease(isVerbose, releasePath, param['flavor'] as String?)) {
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
      log.warning('Please run `flutter build macos --release` first or add a flag `--build` to the command.');
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
