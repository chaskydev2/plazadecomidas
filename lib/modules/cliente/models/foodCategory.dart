class FoodCategory {
  final String id; // Código único del documento/categoría
  final String category;
  final String description;
  final String imageUrl;
  final bool isSelected;

  FoodCategory({
    required this.id,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.isSelected = false,
  });

  factory FoodCategory.fromMap(Map<String, dynamic> map, {String? id}) {
    return FoodCategory(
      id: id ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isSelected: map['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      // 'isSelected' no se guarda en Firestore, solo para UI local
    };
  }
}
