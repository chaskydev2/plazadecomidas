// Ejemplo de arreglo de categorías de comida
// lib/core/models/category_food.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para la colección `categorie-food`.
class CategoryFood {
  /// ID del documento (Firestore).
  final String id;

  /// Nombre de la categoría (ej. "sopas").
  final String category;

  /// Descripción de la categoría.
  final String description;

  /// URL de imagen (puede ser cadena vacía).
  final String imageUrl;

  const CategoryFood({
    required this.id,
    required this.category,
    required this.description,
    required this.imageUrl,
  });

  /// Útil para formularios (valores por defecto).
  factory CategoryFood.empty() =>
      const CategoryFood(id: '', category: '', description: '', imageUrl: '');

  /// Copia inmutable con cambios puntuales.
  CategoryFood copyWith({
    String? id,
    String? category,
    String? description,
    String? imageUrl,
  }) {
    return CategoryFood(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Mapa listo para guardar en Firestore (no incluye el id).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  /// Crea la instancia desde un Map y un id.
  factory CategoryFood.fromMap(String id, Map<String, dynamic> map) {
    return CategoryFood(
      id: id,
      category: (map['category'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
    );
    // Nota: si agregas más campos en Firestore, mapea aquí.
  }

  /// JSON helpers (opcional).
  String toJson() => json.encode(toMap());

  factory CategoryFood.fromJson(String id, String source) =>
      CategoryFood.fromMap(id, json.decode(source) as Map<String, dynamic>);

  /// Crea el modelo desde un DocumentSnapshot tipado.
  factory CategoryFood.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CategoryFood.fromMap(doc.id, data);
  }

  /// Nombre de la colección.
  static const String collectionName = 'categorie-food';

  /// Referencia tipada a la colección usando withConverter.
  static CollectionReference<CategoryFood> col(FirebaseFirestore db) {
    return db
        .collection(collectionName)
        .withConverter<CategoryFood>(
          fromFirestore:
              (snap, _) => CategoryFood.fromMap(
                snap.id,
                snap.data() ?? <String, dynamic>{},
              ),
          toFirestore: (cat, _) => cat.toMap(),
        );
  }

  @override
  String toString() =>
      'CategoryFood(id: $id, category: $category, imageUrl: $imageUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryFood &&
        other.id == id &&
        other.category == category &&
        other.description == description &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      category.hashCode ^
      description.hashCode ^
      imageUrl.hashCode;
}
