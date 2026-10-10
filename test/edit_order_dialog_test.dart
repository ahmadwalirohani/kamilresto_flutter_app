import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamilresto_flutter_app/core/api/api_client.dart';
import 'package:kamilresto_flutter_app/features/order/models/food.dart';
import 'package:kamilresto_flutter_app/features/order/models/order.dart';
import 'package:kamilresto_flutter_app/features/order/providers/restaurant_providers.dart';
import 'package:kamilresto_flutter_app/features/order/repositories/restaurant_repository.dart';
import 'package:kamilresto_flutter_app/features/orders/presentation/edit_order_dialog.dart';

class _Repository extends MockRestaurantRepository {
  Order? saved;
  late Order initial;
  int detailRequests = 0;
  Completer<Order> response = Completer<Order>();

  @override
  Future<Order> getOrderById(String id) async {
    detailRequests++;
    return saved ?? initial;
  }

  @override
  Future<Order> updateOrder(Order order) {
    saved = order;
    return response.future;
  }
}

void main() {
  testWidgets('adds, removes and saves items; failed save retains changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    const food = Food(
      id: '2',
      name: 'Soup',
      description: '',
      categoryId: '1',
      price: 50,
    );
    final order = Order(
      id: '1',
      orderNumber: '#10',
      tableId: '1',
      tableName: 'Table 1',
      waiterId: '1',
      waiterName: 'Waiter',
      guestCount: 2,
      items: const [
        OrderItem(
          id: '10',
          foodId: '1',
          foodName: 'Rice',
          quantity: 1,
          unitPrice: 100,
        ),
      ],
      status: OrderStatus.newOrder,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    repository.initial = order;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restaurantRepositoryProvider.overrideWithValue(repository),
          foodsProvider.overrideWith((ref) async => [food]),
          categoriesProvider.overrideWith(
            (ref) async => [
              const FoodCategory(id: '1', name: 'Soups'),
              const FoodCategory(id: '2', name: 'Drinks'),
            ],
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<Order>(
                  context: context,
                  builder: (_) => EditOrderDialog(order: order),
                ),
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(tester.element(find.text('Edit')));
    final details = container.listen(orderByIdProvider('#10'), (_, _) {});
    addTearDown(details.close);
    expect((await container.read(orderByIdProvider('#10').future)).items.single.foodName, 'Rice');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lunch_dining_outlined), findsNWidgets(2));
    await tester.tap(find.text('Drinks'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add Soup'), findsNothing);
    await tester.tap(find.text('Soups'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Soup'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add Soup'));
    await tester.pump();
    await tester.tap(find.byTooltip('Remove item').first);
    await tester.pumpAndSettle();
    expect(find.text('Remove Rice from this order?'), findsOneWidget);
    await tester.tap(find.text('Keep Item'));
    await tester.pumpAndSettle();
    expect(find.text('Rice'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove item').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(find.text('Rice'), findsNothing);
    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    expect(find.text('Saving...'), findsOneWidget);
    expect(repository.saved!.items.single.foodId, '2');
    expect(repository.saved!.items.single.quantity, 2);
    repository.response.completeError(const ApiException('Server unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Server unavailable'), findsOneWidget);
    expect(find.byType(EditOrderDialog), findsOneWidget);
    repository.response = Completer<Order>();
    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    repository.response.complete(repository.saved!);
    await tester.pumpAndSettle();
    expect(find.byType(EditOrderDialog), findsNothing);
    final refreshed = await container.read(orderByIdProvider('#10').future);
    expect(refreshed.items.single.foodName, 'Soup');
    expect(refreshed.items.single.quantity, 2);
    expect(repository.detailRequests, 2);
  });
}
