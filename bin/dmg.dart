// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';
import 'package:dmg/dmg.dart';

void main(List<String> args) async {
  const releasePath = './build/macos/Build/Products/Release';

  final parser = ArgParser()
    ..addOption(
      'sign-certificate',
      help:
          'The certificate that you are signed. Ex: `Developer ID Application: Your Company`',
    )
    ..addOption(
      'setting',
      help:
          'Path of the modified `setting.py` file. Use default setting if not provided',
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
    );
  final param = parser.parse(args);

  final setting = param['setting'] as String?;
  final licensePath = param['license-path'] as String?;
  final signCertificate = param['sign-certificate'] as String;
  final notaryProfile = param['notary-profile'] as String;

  print('Cleaning build...');
  cleanBuild();
  print('Cleaned');

  print('Flutter release...');
  runFlutterRelease();
  print('Released');

  final appPath = getAppPath(releasePath);
  if (appPath == '') {
    print('Cannot get the app path from "build/macos/Build/Products/Release"');
    print('Exit');
    return;
  }

  final appParentPath = getParentAppPath(appPath);
  final appName = getAppName(appPath);
  final dmg = '$appParentPath/$appName.dmg';
  final settingPath = getSettingPath(appParentPath, setting, licensePath);

  print('Code signing for the APP...');
  runCodeSignApp(signCertificate, appPath);
  print('Signed');

  print('Building DMG...');
  runDmgBuild(settingPath, appPath, dmg, appName);
  print('Built');

  print('Code signing for the DMG...');
  runCodeSignDmg(dmg, signCertificate);
  print('Signed');

  print('Notarizing...');
  final notaryOutput = runNotaryTool(dmg);

  final regex = RegExp(r'id: (\w+-\w+-\w+-\w+-\w+)');
  final match = regex.firstMatch(notaryOutput);
  final noratyId = match!.group(1) as String;

  final dmgPath = (dmg.split('/')..removeLast()).join('/');
  final notaryLogPath = '$dmgPath/notary_log.json';
  final logFile = File(notaryLogPath);

  final success = await waitAndCheckNoratyState(
    notaryOutput,
    dmg,
    notaryProfile,
    noratyId,
    logFile,
  );

  if (success) {
    print('Stapling...');
    runStaple(dmg);
    print('Stapled');
  }

  if (success) {
    print('Done everything. Output: $dmg');
  } else {
    print('Done with error.');
  }
}