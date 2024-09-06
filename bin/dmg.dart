// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';
import 'package:dmg/dmg.dart';

void main(List<String> args) async {
  final releasePath =
      joinPaths(['.', 'build', 'macos', 'Build', 'Products', 'Release']);

  final parser = ArgParser()
    ..addOption(
      'sign-certificate',
      help:
          'The certificate that you are signed. Ex: `Developer ID Application: Your Company`',
    )
    ..addOption(
      'settings',
      help:
          'Path of the modified `settings.py` file. Use default setting if not provided',
    )
    ..addOption(
      'license-path',
      help: 'Path of the license file.',
    )
    ..addOption(
      'notary-profile',
      help:
          'Name of the notary profile that created by `xcrun notarytool store-credentials`.',
      defaultsTo: "NotaryProfile",
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help:
          'Name of the notary profile that created by `xcrun notarytool store-credentials`.',
      defaultsTo: false,
    );
  final param = parser.parse(args);

  final settings = param['settings'] as String?;
  final licensePath = param['license-path'] as String?;
  final signCertificate = param['sign-certificate'] as String;
  final notaryProfile = param['notary-profile'] as String;
  final isVerbose = param['verbose'] as bool;

  print('Cleaning build...');
  cleanBuild(isVerbose);
  print('Cleaned');

  print('Flutter release...');
  runFlutterRelease(isVerbose);
  print('Released');

  final appPath = getAppPath(releasePath);
  if (appPath == '') {
    print('Cannot get the app path from "$releasePath"');
    print('Exit');
    return;
  }

  final appParentPath = getParentAppPath(appPath);
  final appName = getAppName(appPath);
  final dmg = '$appParentPath$separator$appName.dmg';
  final settingsPath = getSettingsPath(appParentPath, settings, licensePath);

  print('Code signing for the APP...');
  runCodeSignApp(signCertificate, appPath, isVerbose);
  print('Signed');

  print('Building DMG...');
  runDmgBuild(settingsPath, appPath, dmg, appName, isVerbose);
  print('Built');

  print('Code signing for the DMG...');
  runCodeSignDmg(dmg, signCertificate, isVerbose);
  print('Signed');

  print('Notarizing...');
  final notaryOutput = runNotaryTool(dmg, isVerbose);

  final regex = RegExp(r'id: (\w+-\w+-\w+-\w+-\w+)');
  final match = regex.firstMatch(notaryOutput);
  if (match == null) {
    print('The `id` not found from notary output:');
    print(notaryOutput);
    return;
  }

  final noratyId = match.group(1);
  if (noratyId == null) {
    print('The matched `id` not found from notary output:');
    print(notaryOutput);
    return;
  }

  final dmgPath = (dmg.split(separator)..removeLast()).join(separator);
  final notaryLogPath = joinPaths([dmgPath, 'notary_log.json']);

  if (isVerbose) {
    print('Notary log path: $notaryLogPath');
  }

  final logFile = File(notaryLogPath);

  final success = await waitAndCheckNoratyState(
    notaryOutput,
    dmg,
    notaryProfile,
    noratyId,
    logFile,
    isVerbose,
  );

  if (success) {
    print('Stapling...');
    runStaple(dmg, isVerbose);
    print('Stapled');
    print('Everything is done. Output: $dmg');
  } else {
    print('Done with error.');
  }
}
