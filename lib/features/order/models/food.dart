class FoodCategory {
  const FoodCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(id: '${json['id']}', name: json['name'] as String? ?? '');
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.price,
    this.image,
    this.isAvailable = true,
    this.isPopular = false,
  });

  final String id;
  final String name;
  final String description;
  final String categoryId;
  final double price;
  final String? image;
  final bool isAvailable;
  final bool isPopular;

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: '${json['categoryId'] ?? json['category_id'] ?? ''}',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      image: json['image'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? json['is_available'] as bool? ?? true,
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'price': price,
      'image': image,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
    };
  }
}
