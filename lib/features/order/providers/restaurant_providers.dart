import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/current_order_state.dart';
import '../models/food.dart';
import '../models/order.dart';
import '../models/restaurant_table.dart';
import '../repositories/restaurant_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  if (!AppConfig.useMockRepositories) {
    return ApiRestaurantRepository(
      ref.watch(dioProvider),
      ref.watch(sharedPreferencesProvider),
    );
  }
  return MockRestaurantRepository();
});

final tablesProvider = FutureProvider<List<RestaurantTable>>((ref) {
  return ref.watch(restaurantRepositoryProvider).getTables();
});

final categoriesProvider = FutureProvider<List<FoodCategory>>((ref) {
  return ref.watch(restaurantRepositoryProvider).getFoodCategories();
});

final foodsProvider = FutureProvider<List<Food>>((ref) {
  return ref.watch(restaurantRepositoryProvider).getFoods();
});

class CurrentOrderController extends StateNotifier<CurrentOrderState> {
  CurrentOrderController(this._ref) : super(const CurrentOrderState());

  final Ref _ref;

  void selectTable(RestaurantTable table) {
    state = state.copyWith(selectedTable: table, guestCount: table.currentGuests > 0 ? table.currentGuests : state.guestCount, clearMessages: true);
  }

  void setGuestCount(int count) {
    state = state.copyWith(guestCount: count.clamp(1, 24), clearMessages: true);
  }

  void setCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId, clearMessages: true);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, clearMessages: true);
  }

  void addFood(Food food) {
    if (!food.isAvailable) return;
    final existingIndex = state.items.indexWhere((item) => item.foodId == food.id);
    final items = [...state.items];
    if (existingIndex == -1) {
      items.add(OrderItem.fromFood(food));
    } else {
      final existing = items[existingIndex];
      items[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
    }
    state = state.copyWith(items: items, clearMessages: true);
  }

  void changeQuantity(String foodId, int delta) {
    final items = state.items
        .map((item) => item.foodId == foodId ? item.copyWith(quantity: item.quantity + delta) : item)
        .where((item) => item.quantity > 0)
        .toList();
    state = state.copyWith(items: items, clearMessages: true);
  }

  void removeItem(String foodId) {
    state = state.copyWith(items: state.items.where((item) => item.foodId != foodId).toList(), clearMessages: true);
  }

  void updateItemNotes(String foodId, String notes) {
    final items = state.items.map((item) => item.foodId == foodId ? item.copyWith(notes: notes) : item).toList();
    state = state.copyWith(items: items, clearMessages: true);
  }

  void setGeneralNotes(String notes) {
    state = state.copyWith(generalNotes: notes, clearMessages: true);
  }

  void clearOrder() {
    state = const CurrentOrderState();
  }

  Future<Order?> submitOrder() async {
    final table = state.selectedTable;
    final user = _ref.read(authControllerProvider).user;
    if (table == null) {
      state = state.copyWith(errorMessage: 'Select a table before sending the order.');
      return null;
    }
    if (state.items.isEmpty) {
      state = state.copyWith(errorMessage: 'Add at least one menu item.');
      return null;
    }
    if (state.guestCount < 1) {
      state = state.copyWith(errorMessage: 'Guest count must be at least 1.');
      return null;
    }
    if (user == null) {
      state = state.copyWith(errorMessage: 'Your session expired. Please sign in again.');
      return null;
    }
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      final order = await _ref.read(restaurantRepositoryProvider).createOrder(
            table: table,
            waiter: user,
            guestCount: state.guestCount,
            items: state.items,
            notes: state.generalNotes,
          );
      _ref.invalidate(tablesProvider);
      _ref.invalidate(ordersProvider);
      state = const CurrentOrderState().copyWith(successMessage: 'Order ${order.orderNumber} sent to kitchen.');
      return order;
    } catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: readableApiError(error));
      return null;
    }
  }
}

final currentOrderProvider = StateNotifierProvider<CurrentOrderController, CurrentOrderState>((ref) {
  return CurrentOrderController(ref);
});

final filteredFoodsProvider = Provider<List<Food>>((ref) {
  final foods = ref.watch(foodsProvider).value ?? const <Food>[];
  return ref.watch(currentOrderProvider).filterFoods(foods);
});

final ordersProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(restaurantRepositoryProvider).getOrders();
});

final orderByIdProvider = FutureProvider.autoDispose.family<Order, String>((ref, id) {
  final timer = Timer(const Duration(seconds: 15), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(restaurantRepositoryProvider).getOrderById(id);
});

final orderStatusFilterProvider = StateProvider<OrderStatus?>((ref) => null);
final orderSearchProvider = StateProvider<String>((ref) => '');

final filteredOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final status = ref.watch(orderStatusFilterProvider);
  final search = ref.watch(orderSearchProvider).trim().toLowerCase();
  return ref.watch(ordersProvider).whenData((orders) {
    return orders.where((order) {
      final statusMatch = status == null || order.status == status;
      final searchMatch = search.isEmpty ||
          order.orderNumber.toLowerCase().contains(search) ||
          order.tableName.toLowerCase().contains(search);
      return statusMatch && searchMatch;
    }).toList();
  });
});
