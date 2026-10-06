import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';

import '../../auth/models/user.dart';
import '../models/food.dart';
import '../models/order.dart';
import '../models/restaurant_table.dart';

abstract class RestaurantRepository {
  Future<List<RestaurantTable>> getTables();
  Future<List<FoodCategory>> getFoodCategories();
  Future<List<Food>> getFoods();
  Future<List<Order>> getOrders();
  Future<Order> getOrderById(String id);
  Future<void> cancelOrder(String id, String reason);
  Future<void> markOrderReady(String id);
  Future<Order> updateOrder(Order order);
  Future<Order> createOrder({
    required RestaurantTable table,
    required User waiter,
    required int guestCount,
    required List<OrderItem> items,
    required String notes,
  });
}

bool _matchesOrderLookup(Order order, String lookup) {
  if (order.id == lookup || order.orderNumber == lookup) return true;
  final lookupNo = _orderNoFromTextValue(lookup);
  if (lookupNo == null) return false;
  return _orderNoFromTextValue(order.id) == lookupNo ||
      _orderNoFromTextValue(order.orderNumber) == lookupNo;
}

int? _orderNoFromTextValue(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

class MockRestaurantRepository implements RestaurantRepository {
  final List<Order> _orders = [];
  late List<RestaurantTable> _tables = _seedTables();

  @override
  Future<List<RestaurantTable>> getTables() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _tables;
  }

  @override
  Future<List<FoodCategory>> getFoodCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [
      FoodCategory(id: 'all', name: 'All'),
      FoodCategory(id: 'popular', name: 'Popular'),
      FoodCategory(id: 'breakfast', name: 'Breakfast'),
      FoodCategory(id: 'main', name: 'Main Course'),
      FoodCategory(id: 'pizza', name: 'Pizza'),
      FoodCategory(id: 'burger', name: 'Burger'),
      FoodCategory(id: 'drinks', name: 'Drinks'),
      FoodCategory(id: 'desserts', name: 'Desserts'),
    ];
  }

  @override
  Future<List<Food>> getFoods() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const [
      Food(
        id: 'f1',
        name: 'Kabuli Pulao',
        description: 'Lamb, rice, carrots, raisins',
        categoryId: 'main',
        price: 14.5,
        isPopular: true,
      ),
      Food(
        id: 'f2',
        name: 'Chicken Karahi',
        description: 'Tomato masala, fresh herbs',
        categoryId: 'main',
        price: 12.9,
        isPopular: true,
      ),
      Food(
        id: 'f3',
        name: 'Margherita Pizza',
        description: 'Mozzarella, basil, tomato',
        categoryId: 'pizza',
        price: 10.5,
      ),
      Food(
        id: 'f4',
        name: 'Beef Burger',
        description: 'House sauce, cheddar, pickles',
        categoryId: 'burger',
        price: 9.75,
        isPopular: true,
      ),
      Food(
        id: 'f5',
        name: 'Omelette Plate',
        description: 'Eggs, herbs, warm bread',
        categoryId: 'breakfast',
        price: 6.25,
      ),
      Food(
        id: 'f6',
        name: 'Fresh Orange Juice',
        description: 'Pressed to order',
        categoryId: 'drinks',
        price: 3.5,
      ),
      Food(
        id: 'f7',
        name: 'Green Tea',
        description: 'Cardamom and mint',
        categoryId: 'drinks',
        price: 1.75,
      ),
      Food(
        id: 'f8',
        name: 'Firni',
        description: 'Milk pudding, pistachio',
        categoryId: 'desserts',
        price: 4.25,
      ),
      Food(
        id: 'f9',
        name: 'Mantu',
        description: 'Steamed dumplings, yogurt sauce',
        categoryId: 'main',
        price: 11.4,
        isPopular: true,
      ),
      Food(
        id: 'f10',
        name: 'Chocolate Cake',
        description: 'Unavailable today',
        categoryId: 'desserts',
        price: 5.9,
        isAvailable: false,
      ),
    ];
  }

  @override
  Future<List<Order>> getOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (_orders.isEmpty) _orders.addAll(_seedOrders());
    return [..._orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Order> getOrderById(String id) async {
    final orders = await getOrders();
    return orders.firstWhere((order) => _matchesOrderLookup(order, id));
  }

  @override
  Future<void> cancelOrder(String id, String reason) async {}

  @override
  Future<void> markOrderReady(String id) async {}

  @override
  Future<Order> updateOrder(Order order) async => order;

  @override
  Future<Order> createOrder({
    required RestaurantTable table,
    required User waiter,
    required int guestCount,
    required List<OrderItem> items,
    required String notes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    final order = Order(
      id: 'o-${now.microsecondsSinceEpoch}',
      orderNumber: '#${1040 + _orders.length + 1}',
      tableId: table.id,
      tableName: table.name,
      waiterId: waiter.id,
      waiterName: waiter.name,
      guestCount: guestCount,
      items: items,
      status: OrderStatus.newOrder,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    _orders.insert(0, order);
    _tables = _tables
        .map(
          (item) => item.id == table.id
              ? item.copyWith(
                  status: TableStatus.occupied,
                  currentGuests: guestCount,
                  hasActiveOrder: true,
                )
              : item,
        )
        .toList();
    return order;
  }

  List<RestaurantTable> _seedTables() {
    return List.generate(12, (index) {
      final number = index + 1;
      final occupied = number == 2 || number == 8;
      final reserved = number == 5;
      return RestaurantTable(
        id: 't$number',
        name: 'Table ${number.toString().padLeft(2, '0')}',
        number: number,
        status: occupied
            ? TableStatus.occupied
            : reserved
            ? TableStatus.reserved
            : TableStatus.available,
        capacity: [2, 4, 4, 6, 6, 8][index % 6],
        currentGuests: occupied ? 2 + Random(number).nextInt(4) : 0,
        hasActiveOrder: occupied,
      );
    });
  }

  List<Order> _seedOrders() {
    final now = DateTime.now();
    return [
      _sampleOrder(
        'o1',
        '#1042',
        'Table 08',
        OrderStatus.preparing,
        now.subtract(const Duration(minutes: 18)),
      ),
      _sampleOrder(
        'o2',
        '#1041',
        'Table 02',
        OrderStatus.ready,
        now.subtract(const Duration(minutes: 31)),
      ),
      _sampleOrder(
        'o3',
        '#1040',
        'Table 11',
        OrderStatus.completed,
        now.subtract(const Duration(hours: 1, minutes: 12)),
      ),
    ];
  }

  Order _sampleOrder(
    String id,
    String number,
    String table,
    OrderStatus status,
    DateTime time,
  ) {
    const items = [
      OrderItem(
        id: 'f1',
        foodId: 'f1',
        foodName: 'Kabuli Pulao',
        quantity: 2,
        unitPrice: 14.5,
      ),
      OrderItem(
        id: 'f6',
        foodId: 'f6',
        foodName: 'Fresh Orange Juice',
        quantity: 4,
        unitPrice: 3.5,
        notes: 'No ice',
      ),
    ];
    return Order(
      id: id,
      orderNumber: number,
      tableId: table,
      tableName: table,
      waiterId: 'u-1',
      waiterName: 'Ahmad Zahir',
      guestCount: 4,
      items: items,
      status: status,
      createdAt: time,
      updatedAt: time,
    );
  }
}

class ApiRestaurantRepository implements RestaurantRepository {
  ApiRestaurantRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;
  final MockRestaurantRepository _fallback = MockRestaurantRepository();

  static const _tablesCacheKey = 'cached_restaurant_tables';
  static const _categoriesCacheKey = 'cached_food_categories';
  static const _foodsCacheKey = 'cached_foods';
  static const _resourcePath = '/Z2VuZXJhbA/cmVzb3VyY2Vz';
  static const _actionPath = '/Z2VuZXJhbA/YWN0aW9ucw';

  @override
  Future<List<RestaurantTable>> getTables() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_resourcePath/${_resourcePayload(resourceClass: 'SettingsResources', methodName: 'get_reservable_item_resource')}',
      );
      final tables =
          _extractList(response.data)
              //  .where((item) => '${item['type'] ?? ''}'.toLowerCase().contains('table'))
              .map(_tableFromReservableItem)
              .toList()
            ..sort((a, b) => a.number.compareTo(b.number));
      await _cacheTables(tables);
      return tables;
    } catch (error) {
      final cached = _restoreCachedTables();
      if (cached.isNotEmpty) return cached;
      throw ApiException(readableApiError(error));
    }
  }

  @override
  Future<List<FoodCategory>> getFoodCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_resourcePath/${_resourcePayload(resourceClass: 'InventoryResources', methodName: 'get_item_categories')}',
      );
      final categories = [
        const FoodCategory(id: 'all', name: 'All'),
        ..._extractList(response.data)
            .where((item) => _isActive(item['status']))
            .map(_categoryFromItemCategory),
      ];
      await _cacheCategories(categories);
      return categories;
    } catch (error) {
      final cached = _restoreCachedCategories();
      if (cached.isNotEmpty) return cached;
      throw ApiException(readableApiError(error));
    }
  }

  @override
  Future<List<Food>> getFoods() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_resourcePath/${_resourcePayload(resourceClass: 'InventoryResources', methodName: 'get_saleable_item_resource')}',
      );
      final foods =
          _extractList(response.data)
              .where(
                (item) =>
                    item['type'] == 'food' || item['type'] == 'extra-item',
              )
              .map(_foodFromItem)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      await _cacheFoods(foods);
      return foods;
    } catch (error) {
      final cached = _restoreCachedFoods();
      if (cached.isNotEmpty) return cached;
      throw ApiException(readableApiError(error));
    }
  }

  @override
  Future<List<Order>> getOrders() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_resourcePath/${_resourcePayload(resourceClass: 'POSResources', methodName: 'get_orders_of_counter')}',
    );
    return _extractList(response.data).map(_orderFromApi).toList();
  }

  @override
  Future<Order> getOrderById(String id) async {
    final orders = await getOrders();
    return orders.firstWhere(
      (order) => _matchesOrderLookup(order, id),
      orElse: () => throw const ApiException(
        'Order was not found on the server. Refresh orders and try again.',
      ),
    );
  }

  @override
  Future<void> cancelOrder(String id, String reason) async {
    final orderId = await _resolveOrderDatabaseId(id);
    try {
      await _dio.post<dynamic>(
        _actionPath,
        data: _actionPayload(
          actionClass: 'POSActions',
          methodName: 'cancel_order',
          validationClass: '',
          payload: {'order_id': orderId, 'reason': reason},
        ),
      );
    } catch (error) {
      throw ApiException(readableApiError(error));
    }
  }

  @override
  Future<void> markOrderReady(String id) async {
    final orderId = await _resolveOrderDatabaseId(id);
    try {
      await _dio.post<dynamic>(
        _actionPath,
        data: _actionPayload(
          actionClass: 'POSActions',
          methodName: 'submit_order_from_kot',
          validationClass: '',
          payload: {
            'order_id': orderId,
            'is_paid': false,
            'items': <Map<String, dynamic>>[],
            'profit_amount': 0,
          },
        ),
      );
    } catch (error) {
      throw ApiException(readableApiError(error));
    }
  }

  @override
  Future<Order> updateOrder(Order order) async {
    final orderId = await _resolveOrderDatabaseId(
      order.id,
      orderNumber: order.orderNumber,
    );
    try {
      await _dio.post<dynamic>(
        _actionPath,
        data: _actionPayload(
          actionClass: 'POSActions',
          methodName: 'edit_order',
          validationClass: 'CreateOrderRequest',
          payload: {
            'id': orderId,
            'order_id':
                int.tryParse(
                  order.orderNumber.replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                order.orderNumber,
            'r_items': [
              {'id': int.tryParse(order.tableId) ?? order.tableId, 'price': 0},
            ],
            'selected_items': order.items
                .map(_apiOrderItemFromOrderItem)
                .toList(),
            'count_of_person': order.guestCount,
            'is_walkin': true,
            'customer': 'Walk-in',
            'serve_date': order.createdAt.toIso8601String(),
            'remarks': order.notes,
            'is_pick_order': false,
            'phone': '',
            'address': '',
            'total_amount': order.items.fold<double>(
              0,
              (sum, item) => sum + item.total,
            ),
          },
        ),
      );
    } catch (error) {
      throw ApiException(readableApiError(error));
    }
    return order.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<Order> createOrder({
    required RestaurantTable table,
    required User waiter,
    required int guestCount,
    required List<OrderItem> items,
    required String notes,
  }) async {
    final now = DateTime.now();
    final orderNumber = await _nextOrderNumber();
    await _dio.post<dynamic>(
      _actionPath,
      data: _actionPayload(
        actionClass: 'POSActions',
        methodName: 'store_new_order',
        validationClass: 'CreateOrderRequest',
        payload: {
          'order_id': orderNumber,
          'r_items': [
            {'id': int.tryParse(table.id) ?? table.id, 'price': 0},
          ],
          'selected_items': items.map(_apiOrderItemFromOrderItem).toList(),
          'count_of_person': guestCount,
          'is_walkin': true,
          'customer': 'Walk-in',
          'serve_date': now.toIso8601String(),
          'remarks': notes,
          'is_pick_order': false,
          'phone': '',
          'address': '',
          'total_amount': items.fold<double>(
            0,
            (sum, item) => sum + item.total,
          ),
        },
      ),
    );

    return Order(
      id: 'api-$orderNumber',
      orderNumber: '#$orderNumber',
      tableId: table.id,
      tableName: table.name,
      waiterId: waiter.id,
      waiterName: waiter.name,
      guestCount: guestCount,
      items: items,
      status: OrderStatus.newOrder,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> _apiOrderItemFromOrderItem(OrderItem item) {
    return {
      'id': int.tryParse(item.foodId) ?? item.foodId,
      'quantity': item.quantity,
      'price': {'price': item.unitPrice, 'profit': 0, 'cost_price': 0},
      'ingredients': <Map<String, dynamic>>[],
    };
  }

  Future<int> _resolveOrderDatabaseId(String id, {String? orderNumber}) async {
    final directId = int.tryParse(id);
    if (directId != null && directId > 0) return directId;

    final requestedOrderNo = _orderNoFromText(orderNumber ?? id);
    final orders = await getOrders();
    for (final order in orders) {
      final databaseId = int.tryParse(order.id);
      if (databaseId == null) continue;
      if (order.id == id ||
          _orderNoFromText(order.orderNumber) == requestedOrderNo) {
        return databaseId;
      }
    }

    throw const ApiException(
      'Order was not found on the server. Refresh orders and try again.',
    );
  }

  int? _orderNoFromText(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Order _orderFromApi(Map<String, dynamic> item) {
    final details = item['details'] is List
        ? item['details'] as List
        : const [];
    final rItems = item['r_items'] is List ? item['r_items'] as List : const [];
    final table = rItems.whereType<Map>().isNotEmpty
        ? Map<String, dynamic>.from(rItems.whereType<Map>().first)
        : <String, dynamic>{};
    final reservationItem = table['r_item'] ?? table['reservable_item'];
    final reservable = reservationItem is Map
        ? Map<String, dynamic>.from(reservationItem)
        : <String, dynamic>{};
    final tableName = reservable['name'] as String? ?? 'Table';
    final serialNo = reservable['serial_no'] == null
        ? ''
        : '${reservable['serial_no']}'.trim();
    final createdAt =
        DateTime.tryParse('${item['created_at'] ?? ''}') ?? DateTime.now();
    final user = item['user'] is Map
        ? Map<String, dynamic>.from(item['user'] as Map)
        : <String, dynamic>{};
    return Order(
      id: '${item['id']}',
      orderNumber: '#${item['order_no'] ?? item['id']}',
      tableId: '${reservable['id'] ?? table['r_item_id'] ?? ''}',
      tableName: serialNo.isEmpty ? tableName : '$tableName · $serialNo',
      waiterId: '${user['id'] ?? item['created_user_id'] ?? ''}',
      waiterName: user['name'] as String? ?? 'Waiter',
      guestCount: int.tryParse('${item['count_of_person'] ?? 1}') ?? 1,
      items: details
          .whereType<Map>()
          .map((detail) => _orderItemFromApi(Map<String, dynamic>.from(detail)))
          .toList(),
      status: _orderStatusFromApi(item),
      notes: item['remarks'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: DateTime.tryParse('${item['updated_at'] ?? ''}') ?? createdAt,
    );
  }

  OrderItem _orderItemFromApi(Map<String, dynamic> detail) {
    final item = detail['item'] is Map
        ? Map<String, dynamic>.from(detail['item'] as Map)
        : <String, dynamic>{};
    final price = item['price'] is Map
        ? Map<String, dynamic>.from(item['price'] as Map)
        : <String, dynamic>{};
    return OrderItem(
      id: '${detail['id']}',
      foodId: '${detail['item_id'] ?? item['id'] ?? ''}',
      foodName: item['name'] as String? ?? 'Item',
      quantity: int.tryParse('${detail['quantity'] ?? 1}') ?? 1,
      unitPrice:
          double.tryParse('${detail['price'] ?? price['price'] ?? 0}') ?? 0,
      image: item['image'] as String?,
    );
  }

  OrderStatus _orderStatusFromApi(Map<String, dynamic> item) {
    if (_isActive(item['is_rejected'])) return OrderStatus.cancelled;
    final status = int.tryParse('${item['status'] ?? 0}') ?? 0;
    // API order status: 0 = pending, 2 = ready.
    if (status == 2) return OrderStatus.ready;
    return OrderStatus.newOrder;
  }

  Future<int> _nextOrderNumber() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_resourcePath/${_resourcePayload(resourceClass: 'SettingsResources', methodName: 'get_system_info')}',
      );
      final data = response.data?['data'];
      if (data is Map) {
        return int.tryParse('${data['order_no']}') ??
            DateTime.now().millisecondsSinceEpoch;
      }
    } catch (_) {
      // Saving the order should still proceed if numbering lookup is unavailable.
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  String _resourcePayload({
    required String resourceClass,
    required String methodName,
  }) {
    final payload = jsonEncode({
      'X2NsYXNz': base64Encode(utf8.encode(resourceClass)),
      'X21ldGhvZF9uYW1l': base64Encode(utf8.encode(methodName)),
    });
    return Uri.encodeComponent(base64Encode(utf8.encode(payload)));
  }

  Map<String, dynamic> _actionPayload({
    required String actionClass,
    required String methodName,
    required String validationClass,
    required Map<String, dynamic> payload,
  }) {
    return {
      'X2NsYXNz': base64Encode(utf8.encode(actionClass)),
      'X21ldGhvZF9uYW1l': base64Encode(utf8.encode(methodName)),
      'X3ZhbGlkYXRpb25fY2xhc3M': base64Encode(utf8.encode(validationClass)),
      ...payload,
    };
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic>? response) {
    final body = response ?? {};
    final rawItems = body['data'] is List ? body['data'] as List : const [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  FoodCategory _categoryFromItemCategory(Map<String, dynamic> item) {
    return FoodCategory(
      id: '${item['id'] ?? item['value']}',
      name: item['name'] as String? ?? item['label'] as String? ?? 'Category',
    );
  }

  Food _foodFromItem(Map<String, dynamic> item) {
    final category = item['category'] is Map
        ? Map<String, dynamic>.from(item['category'] as Map)
        : null;
    return Food(
      id: '${item['id']}',
      name: item['name'] as String? ?? 'Food item',
      description: item['code'] == null
          ? '${item['type'] ?? ''}'
          : 'Code ${item['code']}',
      categoryId: '${item['category_id'] ?? category?['id'] ?? ''}',
      price: _priceFromItem(item),
      image: item['image'] as String?,
      isAvailable: _isActive(item['status']),
      isPopular: false,
    );
  }

  double _priceFromItem(Map<String, dynamic> item) {
    final price = item['price'];
    if (price is Map) {
      final discounted =
          double.tryParse('${price['discounted_price'] ?? 0}') ?? 0;
      if (discounted > 0) return discounted;
      return double.tryParse('${price['price'] ?? 0}') ?? 0;
    }
    return double.tryParse('${item['sale_price'] ?? item['price'] ?? 0}') ?? 0;
  }

  bool _isActive(Object? value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = '$value'.toLowerCase();
    return text == '1' ||
        text == 'true' ||
        text == 'active' ||
        text == 'available';
  }

  RestaurantTable _tableFromReservableItem(Map<String, dynamic> item) {
    final serial = '${item['serial_no'] ?? item['id'] ?? ''}';
    final number =
        int.tryParse(serial.replaceAll(RegExp(r'[^0-9]'), '')) ??
        int.tryParse('${item['id']}') ??
        0;
    final status = _tableStatusFromReservableStatus('${item['status'] ?? ''}');
    return RestaurantTable(
      id: '${item['id']}',
      name: item['name'] as String? ?? 'Table $serial',
      number: number,
      status: status,
      capacity: int.tryParse('${item['capacity'] ?? ''}') ?? 4,
      currentGuests: status == TableStatus.available ? 0 : 1,
      hasActiveOrder: status != TableStatus.available,
    );
  }

  TableStatus _tableStatusFromReservableStatus(String value) {
    final status = value.toLowerCase();
    if (status.contains('reserved')) return TableStatus.reserved;
    if (status.contains('out')) return TableStatus.occupied;
    if (status.contains('available')) return TableStatus.available;
    return TableStatus.occupied;
  }

  Future<void> _cacheTables(List<RestaurantTable> tables) async {
    await _prefs.setString(
      _tablesCacheKey,
      jsonEncode(tables.map((table) => table.toJson()).toList()),
    );
  }

  Future<void> _cacheCategories(List<FoodCategory> categories) async {
    await _prefs.setString(
      _categoriesCacheKey,
      jsonEncode(categories.map((category) => category.toJson()).toList()),
    );
  }

  Future<void> _cacheFoods(List<Food> foods) async {
    await _prefs.setString(
      _foodsCacheKey,
      jsonEncode(foods.map((food) => food.toJson()).toList()),
    );
  }

  List<RestaurantTable> _restoreCachedTables() {
    final encoded = _prefs.getString(_tablesCacheKey);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => RestaurantTable.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<FoodCategory> _restoreCachedCategories() {
    final encoded = _prefs.getString(_categoriesCacheKey);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => FoodCategory.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<Food> _restoreCachedFoods() {
    final encoded = _prefs.getString(_foodsCacheKey);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Food.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
