import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Directory? _directory;
const _androidLogs = MethodChannel('kamilresto/public_logs');

Future<String?> initializeLogStorage() async {
  if (Platform.isAndroid) {
    return await _androidLogs.invokeMethod<String>('initialize');
  }
  final documents = await getApplicationDocumentsDirectory();
  _directory = await Directory(
    '${documents.path}/KamilResto/logs',
  ).create(recursive: true);
  return _directory!.path;
}

Future<void> appendLog(String day, String entry) async {
  if (Platform.isAndroid) {
    await _androidLogs.invokeMethod<void>('append', {
      'day': day,
      'entry': entry,
    });
    return;
  }
  final directory = _directory;
  if (directory == null) return;
  await File(
    '${directory.path}/kamilresto-$day.log',
  ).writeAsString('$entry\n', mode: FileMode.append, flush: true);
}
