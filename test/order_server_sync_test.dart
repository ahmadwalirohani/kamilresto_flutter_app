import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kamilresto_flutter_app/features/order/repositories/restaurant_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'exact ID wins over colliding order number and save reads server items',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
      var saved = false;
      var reads = 0;
      Map<String, dynamic> order(int id, int number, String food) => {
        'id': id,
        'order_no': number,
        'status': 0,
        'is_rejected': 0,
        'created_at': '2026-10-10T05:00:00.000000Z',
        'details': [
          {
            'id': 10,
            'item_id': 2,
            'quantity': saved ? '3.00' : '1.00',
            'price': 50,
            'item': {'id': 2, 'name': food},
          },
        ],
        'r_items': [
          {
            'r_item_id': 1,
            'r_item': {'id': 1, 'name': 'Table', 'serial_no': 'T1'},
          },
        ],
      };
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            if (request.method == 'POST') {
              saved = true;
              handler.resolve(
                Response(
                  requestOptions: request,
                  statusCode: 200,
                  data: {'success': true},
                ),
              );
            } else {
              reads++;
              expect(request.queryParameters['_fresh'], isNotNull);
              expect(request.headers['Cache-Control'], contains('no-cache'));
              handler.resolve(
                Response(
                  requestOptions: request,
                  statusCode: 200,
                  data: {
                    'data': [
                      order(7, 1, 'Wrong order'),
                      order(1, 99, saved ? 'Updated soup' : 'Soup'),
                    ],
                  },
                ),
              );
            }
          },
        ),
      );
      final repository = ApiRestaurantRepository(dio, preferences);
      final initial = await repository.getOrderById('1');
      expect(initial.id, '1');
      expect(initial.createdAt.isUtc, isFalse);
      expect(initial.createdAt.toUtc(), DateTime.utc(2026, 10, 10, 5));
      expect(initial.items.single.foodName, 'Soup');
      final updated = await repository.updateOrder(initial.copyWith(
        items: [initial.items.single.copyWith(quantity: 3)],
      ));
      expect(updated.items.single.foodName, 'Updated soup');
      expect(updated.items.single.quantity, 3);
      expect(reads, 2);
      expect((await repository.getOrderById('1')).items.single.quantity, 3);
    },
  );
}
