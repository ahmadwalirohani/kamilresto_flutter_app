import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'log_storage.dart';

class AppLogger {
  AppLogger._();

  static Future<void> _pending = Future<void>.value();
  static String? directoryPath;

  static Future<void> initialize() async {
    try {
      directoryPath = await initializeLogStorage();
      write(
        'startup',
        'Application started',
        details: {
          'platform': defaultTargetPlatform.name,
          'mode': kReleaseMode ? 'release' : 'debug',
          'logDirectory': directoryPath,
        },
      );
    } catch (error, stack) {
      debugPrint('Unable to initialize file logging: $error\n$stack');
    }
  }

  static void write(
    String source,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    final now = DateTime.now();
    final entry = jsonEncode({
      'timestamp': now.toIso8601String(),
      'utcOffsetMinutes': now.timeZoneOffset.inMinutes,
      'level': error == null ? 'info' : 'error',
      'source': source,
      'message': message,
      if (error != null) 'errorType': error.runtimeType.toString(),
      if (error != null) 'error': sanitize(error.toString()),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (details != null) 'details': sanitize(details),
    });
    final day =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    // Serialize writes so simultaneous failures cannot interleave entries.
    _pending = _pending.then((_) => appendLog(day, entry)).catchError((
      Object error,
      StackTrace stack,
    ) {
      debugPrint('Unable to write application log: $error');
    });
    if (kIsWeb) debugPrint(entry);
  }

  static Object? sanitize(Object? value) {
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(
          key.toString(),
          _sensitive(key.toString()) ? '[REDACTED]' : sanitize(value),
        ),
      );
    }
    if (value is Iterable) return value.map(sanitize).toList();
    if (value is String) {
      var text = value.replaceAll(
        RegExp(r'Bearer\s+\S+', caseSensitive: false),
        'Bearer [REDACTED]',
      );
      text = text.replaceAllMapped(
        RegExp(
          r'''((?:password|token|authorization|cookie|secret|api_key)["']?\s*[:=]\s*["']?)([^\s,"'&}\]]+)''',
          caseSensitive: false,
        ),
        (match) => '${match[1]}[REDACTED]',
      );
      return text.length > 32000
          ? '${text.substring(0, 32000)} [TRUNCATED]'
          : text;
    }
    if (value == null || value is num || value is bool) return value;
    return sanitize(value.toString());
  }

  static bool _sensitive(String key) => RegExp(
    r'password|token|authorization|cookie|secret|api.?key',
    caseSensitive: false,
  ).hasMatch(key);
}

class ErrorLogObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.write(
      'provider',
      'Provider failed',
      error: error,
      stackTrace: stackTrace,
      details: {'provider': provider.name ?? provider.runtimeType.toString()},
    );
  }
}
