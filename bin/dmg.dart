import 'dart:io';

import 'package:dmg/dmg.dart';
import 'package:dmg/src/utils.dart';

void main(List<String> args) async {
  log.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.message}');
  });

  final exitCode = await execute(args);

  if (exitCode != 0) {
    exit(exitCode);
  }
}
