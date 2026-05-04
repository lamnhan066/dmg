import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

class DmgConfig {
  final String? flavor;
  final String? signCertificate;
  final String? settings;
  final String? licensePath;
  final String notaryProfile;
  final bool build;
  final bool cleanBuild;
  final bool sign;
  final bool notarization;
  final bool verbose;

  const DmgConfig({
    required this.flavor,
    required this.signCertificate,
    required this.settings,
    required this.licensePath,
    required this.notaryProfile,
    required this.build,
    required this.cleanBuild,
    required this.sign,
    required this.notarization,
    required this.verbose,
  });
}

ArgParser createDmgArgParser() {
  return ArgParser()
    ..addOption(
      'sign-certificate',
      help:
          'The certificate that you are signed. Ex: `Developer ID Application: Your Company`',
    )
    ..addOption(
      'settings',
      help:
          'Path of the modified `settings.py` file. Use default setting if not provided. '
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
      help:
          'Name of the notary profile that created by `xcrun notarytool store-credentials`',
    )
    ..addFlag(
      'build',
      help:
          'Automatically run `flutter build macos --release --obfuscate --split-debug-info=debug-macos-info`.',
      defaultsTo: true,
    )
    ..addFlag(
      'clean-build',
      help:
          'Clean the `build/macos` folder before running the `build` command. '
          'This flag will be ignored if the `build` flag is set to `--no-build`.',
      defaultsTo: true,
    )
    ..addFlag(
      'sign',
      help:
          'Code sign the .app and .dmg files. Set to --no-sign to skip signing for test builds.',
      defaultsTo: true,
    )
    ..addFlag(
      'notarization',
      help:
          'Submit for notarization and staple. Set to --no-notarization to skip notarization for test builds. '
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
}

DmgConfig resolveDmgConfig(ArgResults results) {
  final baseConfig = _loadDmgSection('dmg');
  final cliFlavor = _argString(results, 'flavor');
  final baseFlavor = _mapString(baseConfig, 'flavor');
  final selectedFlavor = cliFlavor ?? baseFlavor;
  final flavorConfig = selectedFlavor == null
      ? const <String, dynamic>{}
      : _loadDmgSection('dmg_$selectedFlavor');
  final mergedConfig = <String, dynamic>{
    ...baseConfig,
    ...flavorConfig,
  };

  return DmgConfig(
    flavor: cliFlavor ?? _mapString(mergedConfig, 'flavor'),
    signCertificate: _resolveString(results, mergedConfig, 'sign-certificate'),
    settings: _resolveString(results, mergedConfig, 'settings'),
    licensePath: _resolveString(results, mergedConfig, 'license-path'),
    notaryProfile: _resolveString(
          results,
          mergedConfig,
          'notary-profile',
          defaultValue: 'NotaryProfile',
        ) ??
        'NotaryProfile',
    build: _resolveBool(results, mergedConfig, 'build', defaultValue: true),
    cleanBuild:
        _resolveBool(results, mergedConfig, 'clean-build', defaultValue: true),
    sign: _resolveBool(results, mergedConfig, 'sign', defaultValue: true),
    notarization:
        _resolveBool(results, mergedConfig, 'notarization', defaultValue: true),
    verbose:
        _resolveBool(results, mergedConfig, 'verbose', defaultValue: false),
  );
}

String? _argString(ArgResults results, String name) {
  if (!results.wasParsed(name)) {
    return null;
  }

  final value = results[name];
  return value == null ? null : value as String;
}

String? _resolveString(
  ArgResults results,
  Map<String, dynamic> config,
  String name, {
  String? defaultValue,
}) {
  final cliValue = _argString(results, name);
  if (cliValue != null) {
    return cliValue;
  }

  final configValue = _mapValue(config, name);
  if (configValue == null) {
    return defaultValue;
  }

  if (configValue is! String) {
    throw FormatException(
      'Expected "$name" in pubspec.yaml to be a string, got ${configValue.runtimeType}.',
    );
  }

  return configValue;
}

bool _resolveBool(
  ArgResults results,
  Map<String, dynamic> config,
  String name, {
  required bool defaultValue,
}) {
  if (results.wasParsed(name)) {
    return results[name] as bool;
  }

  final configValue = _mapValue(config, name);
  if (configValue == null) {
    return defaultValue;
  }

  if (configValue is! bool) {
    throw FormatException(
      'Expected "$name" in pubspec.yaml to be a boolean, got ${configValue.runtimeType}.',
    );
  }

  return configValue;
}

Map<String, dynamic> _loadDmgSection(String sectionName) {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    return const <String, dynamic>{};
  }

  final yamlContent = loadYaml(file.readAsStringSync());
  if (yamlContent is! YamlMap) {
    throw FormatException('Expected pubspec.yaml to contain a YAML map.');
  }

  final section = yamlContent[sectionName];
  if (section == null) {
    return const <String, dynamic>{};
  }

  if (section is! YamlMap) {
    throw FormatException(
      'Expected "$sectionName" in pubspec.yaml to be a map.',
    );
  }

  return _normalizeMap(section);
}

Map<String, dynamic> _normalizeMap(YamlMap yamlMap) {
  final result = <String, dynamic>{};
  for (final entry in yamlMap.entries) {
    final key = entry.key.toString().replaceAll('_', '-');
    result[key] = _normalizeValue(entry.value);
  }

  return result;
}

dynamic _normalizeValue(dynamic value) {
  if (value is YamlMap) {
    return _normalizeMap(value);
  }

  if (value is YamlList) {
    return value.map(_normalizeValue).toList();
  }

  return value;
}

dynamic _mapValue(Map<String, dynamic> config, String name) {
  return config[name] ?? config[name.replaceAll('-', '_')];
}

String? _mapString(Map<String, dynamic> config, String name) {
  final value = _mapValue(config, name);
  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException(
      'Expected "$name" in pubspec.yaml to be a string, got ${value.runtimeType}.',
    );
  }

  return value;
}
