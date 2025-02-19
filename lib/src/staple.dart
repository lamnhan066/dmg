import 'dart:io';

import 'package:dmg/src/utils.dart';

/// no-doc
void runStaple(String dmg, bool isVerbose) {
  final r = Process.runSync('xcrun', ['stapler', 'staple', dmg]);
  if (isVerbose) {
    log.info(r.stdout);
  }
}
