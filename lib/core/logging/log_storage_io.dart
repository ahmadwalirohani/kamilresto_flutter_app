import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Directory? _directory;
const _androidLogs = MethodChannel('kamilresto/public_logs');

Future<List<String>> listLogFiles() async {
  if (Platform.isAndroid) {
    return await _androidLogs.invokeListMethod<String>('list') ?? [];
  }
  if (_directory == null) await initializeLogStorage();
  final files = await _directory!
      .list()
      .where(
        (file) =>
            file is File &&
            RegExp(r'kamilresto-\d{4}-\d{2}-\d{2}\.log$').hasMatch(file.path),
      )
      .toList();
  return files.map((file) => file.uri.pathSegments.last).toList()
    ..sort((a, b) => b.compareTo(a));
}

Future<String> readLogFile(String name) async {
  if (!RegExp(r'^kamilresto-\d{4}-\d{2}-\d{2}\.log$').hasMatch(name))
    throw ArgumentError('Invalid log name');
  if (Platform.isAndroid)
    return await _androidLogs.invokeMethod<String>('read', {'name': name}) ??
        '';
  if (_directory == null) await initializeLogStorage();
  return File('${_directory!.path}/$name').readAsString();
}

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
