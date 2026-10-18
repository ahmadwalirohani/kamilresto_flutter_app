import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kamilresto_flutter_app/core/widgets/device_gate.dart';

void main() {
  testWidgets('admin dialog opens above router without navigator assertion', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('kamilresto/device');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => {
      'device': 'Test tablet', 'mac': 'android:123', 'pid': '123', 'ip': '192.168.1.10',
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('App')))]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      builder: (_, child) => DeviceGate(child: child!),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Register With Admin'));
    await tester.tap(find.text('Register With Admin'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Administrator Verification'), findsOneWidget);
    expect(find.text('Admin Username'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Administrator Verification'), findsNothing);
    await tester.tap(find.text('Register With Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Administrator Verification'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });
}
