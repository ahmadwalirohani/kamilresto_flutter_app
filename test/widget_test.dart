import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kamilresto_flutter_app/features/auth/providers/auth_providers.dart';
import 'package:kamilresto_flutter_app/main.dart';

void main() {
  testWidgets('shows login screen when no session exists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kamil Resto POS'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
