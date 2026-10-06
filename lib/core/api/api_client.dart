import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_config.dart';
import '../logging/app_logger.dart';

final apiTokenProvider = StateProvider<String?>((ref) => null);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['logStartedAt'] = DateTime.now();
        final token = ref.read(apiTokenProvider);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final started = error.requestOptions.extra['logStartedAt'];
        AppLogger.write(
          'api',
          'API request failed',
          error: error,
          stackTrace: error.stackTrace,
          details: {
            'method': error.requestOptions.method,
            'url': error.requestOptions.uri.toString(),
            'query': error.requestOptions.queryParameters,
            'requestHeaders': error.requestOptions.headers,
            'requestBody': error.requestOptions.data,
            'statusCode': error.response?.statusCode,
            'responseHeaders': error.response?.headers.map,
            'responseBody': error.response?.data,
            'dioType': error.type.name,
            'cause': error.error?.toString(),
            'elapsedMs': started is DateTime
                ? DateTime.now().difference(started).inMilliseconds
                : null,
          },
        );
        if (error.response?.statusCode == 401) {
          ref.read(apiTokenProvider.notifier).state = null;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

String readableApiError(Object error) {
  if (error is! DioException) {
    AppLogger.write(
      'application',
      'Handled application error',
      error: error,
      stackTrace: StackTrace.current,
    );
  }
  if (error is ApiException) return error.message;
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    if (status == 422 &&
        data is Map<String, dynamic> &&
        data['errors'] is Map) {
      final errors = data['errors'] as Map;
      for (final messages in errors.values) {
        if (messages is List) {
          for (final message in messages) {
            if (message is String) return message;
          }
        }
      }
      return 'Please check the login details and try again.';
    }
    if (status == 401) return 'Your session expired. Please sign in again.';
    if (status == 403) return 'You do not have permission for this action.';
    if (status == 404) return 'The requested record was not found.';
    if (status == 500) return 'The server had a problem. Please try again.';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The connection timed out. Check the network and retry.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Network unavailable. Check the connection and retry.';
    }
  }
  return 'Something went wrong. Please try again.';
}

String detailedApiError(Object error, [StackTrace? stackTrace]) {
  String appendStack(String value) {
    if (stackTrace == null) return value;
    return '$value\n\nstackTrace:\n$stackTrace';
  }

  if (error is ApiException) {
    return appendStack('ApiException: ${error.message}');
  }
  if (error is DioException) {
    final buffer = StringBuffer()
      ..writeln('DioException')
      ..writeln('type: ${error.type}')
      ..writeln('message: ${error.message}')
      ..writeln('method: ${error.requestOptions.method}')
      ..writeln('url: ${error.requestOptions.uri}');
    final statusCode = error.response?.statusCode;
    if (statusCode != null) buffer.writeln('statusCode: $statusCode');
    final statusMessage = error.response?.statusMessage;
    if (statusMessage != null && statusMessage.isNotEmpty) {
      buffer.writeln('statusMessage: $statusMessage');
    }
    final responseData = error.response?.data;
    if (responseData != null) buffer.writeln('response: $responseData');
    final dioStackTrace = error.stackTrace;
    buffer.writeln('dioStackTrace: $dioStackTrace');
    return appendStack(buffer.toString().trim());
  }
  return appendStack('${error.runtimeType}: $error');
}
