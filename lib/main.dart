import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await AppLogger.initialize();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.write(
          'flutter',
          'Flutter framework error',
          error: details.exception,
          stackTrace: details.stack,
          details: {
            'library': details.library,
            'context': details.context?.toDescription(),
            'diagnostics': details.toString(),
          },
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.write(
          'runtime',
          'Unhandled platform error',
          error: error,
          stackTrace: stack,
        );
        return true;
      };
      final preferences = await SharedPreferences.getInstance();
      runApp(
        ProviderScope(
          observers: [ErrorLogObserver()],
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const RestaurantPosApp(),
        ),
      );
    },
    (error, stack) {
      AppLogger.write(
        'runtime',
        'Uncaught asynchronous error',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

class RestaurantPosApp extends ConsumerWidget {
  const RestaurantPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
