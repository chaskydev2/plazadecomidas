class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String restaurantId;
  final bool isAvailable;
  final String imageUrl;
  final List<Variation> variations;
  final List<String> categories;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.restaurantId,
    required this.isAvailable,
    required this.imageUrl,
    this.variations = const [],
    this.categories = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      restaurantId: json['restaurantId'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      imageUrl: json['imageUrl'] ?? '',
      variations:
          (json['variations'] as List<dynamic>?)
              ?.map((v) => Variation.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      categories: List<String>.from(json['categories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'restaurantId': restaurantId,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'variations': variations.map((v) => v.toJson()).toList(),
      'categories': categories,
    };
  }

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    String? restaurantId,
    bool? isAvailable,
    String? imageUrl,
    List<Variation>? variations,
    List<String>? categories,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      restaurantId: restaurantId ?? this.restaurantId,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      variations: variations ?? this.variations,
      categories: categories ?? this.categories,
    );
  }
}

class Variation {
  final String name;
  final double price;
  final bool isDefault;

  Variation({required this.name, required this.price, this.isDefault = false});

  factory Variation.fromJson(Map<String, dynamic> json) {
    return Variation(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'price': price, 'isDefault': isDefault};
  }

  Variation copyWith({String? name, double? price, bool? isDefault}) {
    return Variation(
      name: name ?? this.name,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
