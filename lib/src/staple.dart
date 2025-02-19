import 'dart:io';

/// no-doc
void runStaple(String dmg, bool isVerbose) {
  final r = Process.runSync('xcrun', ['stapler', 'staple', dmg]);
  if (isVerbose) {
    print(r.stdout);
  }
}
