import 'dart:io';

import 'package:args/args.dart';
import 'package:dmg/src/pubspec_config.dart';
import 'package:test/test.dart';

ArgResults _parseArgs(List<String> args) {
  return createDmgArgParser().parse(args);
}

void main() {
  group('pubspec config', () {
    late Directory tempDir;
    late Directory previousDir;

    setUp(() {
      previousDir = Directory.current;
      tempDir = Directory.systemTemp.createTempSync('dmg_pubspec_test_');
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = previousDir;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('reads values from dmg section', () {
      File('pubspec.yaml').writeAsStringSync('''
name: example
description: Example app
version: 1.0.0

dmg:
  flavor: production
  settings: ./settings.py
  license-path: ./license.txt
  sign-certificate: Example Certificate
  notary-profile: ExampleProfile
  build: false
  clean-build: false
  sign: false
  notarization: false
  verbose: true
''');

      final config = resolveDmgConfig(_parseArgs([]));

      expect(config.flavor, 'production');
      expect(config.settings, './settings.py');
      expect(config.licensePath, './license.txt');
      expect(config.signCertificate, 'Example Certificate');
      expect(config.notaryProfile, 'ExampleProfile');
      expect(config.build, isFalse);
      expect(config.cleanBuild, isFalse);
      expect(config.sign, isFalse);
      expect(config.notarization, isFalse);
      expect(config.verbose, isTrue);
    });

    test('applies dmg_flavor overrides', () {
      File('pubspec.yaml').writeAsStringSync('''
name: example
description: Example app
version: 1.0.0

dmg:
  flavor: production
  settings: ./settings.py
  sign: false
  notarization: false

dmg_production:
  settings: ./production_settings.py
  sign: true
''');

      final config = resolveDmgConfig(_parseArgs([]));

      expect(config.flavor, 'production');
      expect(config.settings, './production_settings.py');
      expect(config.sign, isTrue);
      expect(config.notarization, isFalse);
    });

    test('uses the cli flavor to select a matching dmg section', () {
      File('pubspec.yaml').writeAsStringSync('''
name: example
description: Example app
version: 1.0.0

dmg:
  settings: ./settings.py

dmg_dev:
  settings: ./settings.dev.py
''');

      final config = resolveDmgConfig(_parseArgs(['--flavor=dev']));

      expect(config.flavor, 'dev');
      expect(config.settings, './settings.dev.py');
    });

    test('lets CLI override pubspec config', () {
      File('pubspec.yaml').writeAsStringSync('''
name: example
description: Example app
version: 1.0.0

dmg:
  flavor: production
  sign: false
''');

      final config = resolveDmgConfig(_parseArgs(['--sign']));

      expect(config.flavor, 'production');
      expect(config.sign, isTrue);
    });
  });
}
