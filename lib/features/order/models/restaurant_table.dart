enum TableStatus { available, occupied, reserved, ordering }

extension TableStatusLabel on TableStatus {
  String get label {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.ordering:
        return 'Ordering';
    }
  }
}

class RestaurantTable {
  const RestaurantTable({
    required this.id,
    required this.name,
    required this.number,
    required this.status,
    required this.capacity,
    this.currentGuests = 0,
    this.hasActiveOrder = false,
  });

  final String id;
  final String name;
  final int number;
  final TableStatus status;
  final int capacity;
  final int currentGuests;
  final bool hasActiveOrder;

  RestaurantTable copyWith({
    TableStatus? status,
    int? currentGuests,
    bool? hasActiveOrder,
  }) {
    return RestaurantTable(
      id: id,
      name: name,
      number: number,
      status: status ?? this.status,
      capacity: capacity,
      currentGuests: currentGuests ?? this.currentGuests,
      hasActiveOrder: hasActiveOrder ?? this.hasActiveOrder,
    );
  }

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: '${json['id']}',
      name: json['name'] as String? ?? 'Table ${json['number']}',
      number: json['number'] as int? ?? int.tryParse('${json['number']}') ?? 0,
      status: TableStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => TableStatus.available,
      ),
      capacity: json['capacity'] as int? ?? 4,
      currentGuests: json['currentGuests'] as int? ?? 0,
      hasActiveOrder: json['hasActiveOrder'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'status': status.name,
      'capacity': capacity,
      'currentGuests': currentGuests,
      'hasActiveOrder': hasActiveOrder,
    };
  }
}
