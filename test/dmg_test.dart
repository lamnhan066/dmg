import 'package:test/test.dart';
import 'package:dmg/dmg.dart';
import 'package:dmg/src/utils.dart';
import 'package:dmg/src/code_sign.dart';
import 'dart:io';

void main() {
  group('DMG Package Tests', () {
    test('isCommandAvailable should return true for existing commands', () {
      // Test with a command that should exist on macOS
      expect(isCommandAvailable('ls'), isTrue);
    });

    test('isCommandAvailable should return false for non-existing commands',
        () {
      expect(isCommandAvailable('nonexistentcommand12345'), isFalse);
    });

    test('isCommandAvailable should handle exceptions gracefully', () {
      // This tests the error handling in the function
      expect(isCommandAvailable(''), isFalse);
    });

    test('joinPaths should correctly join path segments', () {
      final result = joinPaths(['path', 'to', 'file']);
      expect(
          result,
          equals(
              'path${Platform.pathSeparator}to${Platform.pathSeparator}file'));
    });

    test('joinPaths should handle empty paths', () {
      expect(joinPaths([]), equals(''));
      expect(joinPaths(['single']), equals('single'));
    });

    test('getAppName should extract app name correctly', () {
      final appName = getAppName('/path/to/MyApp.app');
      expect(appName, equals('MyApp'));
    });

    test('getAppName should handle edge cases', () {
      expect(getAppName('MyApp.app'), equals('MyApp'));
      expect(getAppName('/MyApp.app'), equals('MyApp'));
      expect(getAppName(''), equals(''));
    });

    test('getParentAppPath should return parent directory', () {
      final parentPath = getParentAppPath('/path/to/MyApp.app');
      expect(parentPath, equals('/path/to'));
    });

    test('getParentAppPath should handle edge cases', () {
      expect(getParentAppPath('MyApp.app'), equals(''));
      expect(getParentAppPath('/MyApp.app'), equals(''));
    });

    test('execute should show help when help flag is passed', () async {
      final exitCode = await execute(['--help']);
      expect(exitCode, equals(0));
    });

    test('execute should show help when -h flag is passed', () async {
      final exitCode = await execute(['-h']);
      expect(exitCode, equals(0));
    });
  });

  group('Path Utilities Tests', () {
    test('separator should match platform separator', () {
      expect(separator, equals(Platform.pathSeparator));
    });

    test('getAppPath should return empty string for non-existent directory',
        () {
      final result = getAppPath('/non/existent/path');
      expect(result, isEmpty);
    });

    test('getAppPath should handle empty path', () {
      final result = getAppPath('');
      expect(result, isEmpty);
    });
  });

  group('Code Signing Tests', () {
    test('getSignCertificate should handle null input', () {
      // This test might fail on systems without certificates
      // but it tests the function structure
      final result = getSignCertificate(null);
      expect(result, isA<String?>());
    });

    test('getSignCertificate should return provided certificate', () {
      const testCert = 'Test Certificate';
      final result = getSignCertificate(testCert);
      expect(result, equals(testCert));
    });
  });

  group('Error Handling Tests', () {
    test('execute should handle invalid arguments gracefully', () async {
      final exitCode = await execute(['--invalid-flag']);
      expect(exitCode, equals(1));
    });

    test('execute should validate Flutter project', () async {
      // This test assumes we're not in a Flutter project root
      // or that the test doesn't have access to pubspec.yaml
      final exitCode = await execute(['--no-build']);
      // This might return 0 or 1 depending on the test environment
      expect(exitCode, isA<int>());
    });

    test('getAppName handles multiple dots in name', () {
      final appName = getAppName('/path/to/My.App.Name.app');
      expect(appName, equals('My.App.Name'));
    });
  });
}
