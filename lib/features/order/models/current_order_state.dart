import 'food.dart';
import 'order.dart';
import 'restaurant_table.dart';

class CurrentOrderState {
  const CurrentOrderState({
    this.selectedTable,
    this.guestCount = 2,
    this.selectedCategoryId = 'all',
    this.searchQuery = '',
    this.items = const [],
    this.generalNotes = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  final RestaurantTable? selectedTable;
  final int guestCount;
  final String selectedCategoryId;
  final String searchQuery;
  final List<OrderItem> items;
  final String generalNotes;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discount => 0;
  double get tax => subtotal * .05;
  double get serviceCharge => subtotal * .03;
  double get total => subtotal - discount + tax + serviceCharge;

  CurrentOrderState copyWith({
    RestaurantTable? selectedTable,
    int? guestCount,
    String? selectedCategoryId,
    String? searchQuery,
    List<OrderItem>? items,
    String? generalNotes,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return CurrentOrderState(
      selectedTable: selectedTable ?? this.selectedTable,
      guestCount: guestCount ?? this.guestCount,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      items: items ?? this.items,
      generalNotes: generalNotes ?? this.generalNotes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
    );
  }

  CurrentOrderState withoutTable() {
    return CurrentOrderState(
      guestCount: guestCount,
      selectedCategoryId: selectedCategoryId,
      searchQuery: searchQuery,
      items: items,
      generalNotes: generalNotes,
      isSubmitting: isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  List<Food> filterFoods(List<Food> foods) {
    final query = searchQuery.trim().toLowerCase();
    return foods.where((food) {
      final categoryMatch = selectedCategoryId == 'all' ||
          (selectedCategoryId == 'popular' && food.isPopular) ||
          food.categoryId == selectedCategoryId;
      final searchMatch = query.isEmpty ||
          food.name.toLowerCase().contains(query) ||
          food.description.toLowerCase().contains(query);
      return categoryMatch && searchMatch;
    }).toList();
  }
}
