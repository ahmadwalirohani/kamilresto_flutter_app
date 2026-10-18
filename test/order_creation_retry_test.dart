import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kamilresto_flutter_app/features/auth/models/user.dart';
import 'package:kamilresto_flutter_app/features/order/models/order.dart';
import 'package:kamilresto_flutter_app/features/order/models/restaurant_table.dart';
import 'package:kamilresto_flutter_app/features/order/repositories/restaurant_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('timeout retry reuses persisted creation key and returns server identity', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
    final keys = <String>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      if (request.method == 'GET') {
        handler.resolve(Response(requestOptions: request, statusCode: 200, data: {'data': {'order_no': 101}}));
        return;
      }
      keys.add(request.data['client_request_id'] as String);
      if (keys.length == 1) {
        handler.reject(DioException(requestOptions: request, type: DioExceptionType.receiveTimeout));
      } else {
        handler.resolve(Response(requestOptions: request, statusCode: 200, data: {'created_order_id': 42, 'created_order_no': 100}));
      }
    }));
    Future<Order> submit(ApiRestaurantRepository repository) => repository.createOrder(
      table: const RestaurantTable(id: '1', name: 'Table', number: 1, status: TableStatus.available, capacity: 4),
      waiter: const User(id: '5', name: 'Waiter', username: 'waiter', role: 'Waiter', token: ''),
      guestCount: 2,
      items: const [OrderItem(id: '2', foodId: '2', foodName: 'Bread', quantity: 2.5, unitPrice: 10)],
      notes: '',
    );
    await expectLater(submit(ApiRestaurantRepository(dio, prefs)), throwsA(isA<DioException>()));
    final order = await submit(ApiRestaurantRepository(dio, prefs));
    expect(keys[0], keys[1]);
    expect(order.id, '42');
    expect(order.orderNumber, '#100');
    expect(prefs.getString('pending_order_creation'), isNull);
  });
}
