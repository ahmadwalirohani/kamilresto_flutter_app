import 'food.dart';

enum OrderStatus { draft, newOrder, preparing, ready, served, completed, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.draft:
        return 'Draft';
      case OrderStatus.newOrder:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.served:
        return 'Served';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.unitPrice,
    this.notes = '',
    this.image,
  });

  final String id;
  final String foodId;
  final String foodName;
  final int quantity;
  final double unitPrice;
  final String notes;
  final String? image;
  double get total => quantity * unitPrice;

  factory OrderItem.fromFood(Food food) {
    return OrderItem(
      id: food.id,
      foodId: food.id,
      foodName: food.name,
      quantity: 1,
      unitPrice: food.price,
      image: food.image,
    );
  }

  OrderItem copyWith({int? quantity, String? notes, String? image}) {
    return OrderItem(
      id: id,
      foodId: foodId,
      foodName: foodName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      notes: notes ?? this.notes,
      image: image ?? this.image,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: '${json['id']}',
      foodId: '${json['foodId'] ?? json['food_id']}',
      foodName: json['foodName'] as String? ?? json['food_name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num? ?? json['unit_price'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodId': foodId,
      'foodName': foodName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'notes': notes,
      'image': image,
    };
  }
}

class OrderTotals {
  const OrderTotals({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.serviceCharge,
  });

  final double subtotal;
  final double discount;
  final double tax;
  final double serviceCharge;
  double get total => subtotal - discount + tax + serviceCharge;
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.tableId,
    required this.tableName,
    required this.waiterId,
    required this.waiterName,
    required this.guestCount,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.discount = 0,
    this.notes = '',
  });

  final String id;
  final String orderNumber;
  final String tableId;
  final String tableName;
  final String waiterId;
  final String waiterName;
  final int guestCount;
  final List<OrderItem> items;
  final OrderStatus status;
  final String notes;
  final double discount;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get tax => subtotal * .05;
  double get serviceCharge => subtotal * .03;
  double get total => subtotal - discount + tax + serviceCharge;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    String? orderNumber,
    String? tableId,
    String? tableName,
    String? waiterId,
    String? waiterName,
    int? guestCount,
    List<OrderItem>? items,
    OrderStatus? status,
    String? notes,
    double? discount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      guestCount: guestCount ?? this.guestCount,
      items: items ?? this.items,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      discount: discount ?? this.discount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'tableId': tableId,
      'tableName': tableName,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'guestCount': guestCount,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'serviceCharge': serviceCharge,
      'total': total,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
