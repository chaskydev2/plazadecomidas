import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todas las categorías
  Stream<List<String>> getCategories(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc('menu_categories')
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null || data['categories'] == null) {
        return <String>[];
      }
      return List<String>.from(data['categories']);
    });
  }

  // Agregar una nueva categoría
  Future<void> addCategory(String restaurantId, String category) async {
    final docRef = _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc('menu_categories');

    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      List<String> categories = [];
      
      if (doc.exists && doc.data() != null && doc.data()!['categories'] != null) {
        categories = List<String>.from(doc.data()!['categories']);
      }

      // Evitar duplicados
      if (!categories.contains(category)) {
        categories.add(category);
        categories.sort();
        transaction.set(docRef, {'categories': categories}, SetOptions(merge: true));
      }
    });
  }

  // Eliminar una categoría
  Future<void> removeCategory(String restaurantId, String category) async {
    final docRef = _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc('menu_categories');

    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists && doc.data() != null && doc.data()!['categories'] != null) {
        List<String> categories = List<String>.from(doc.data()!['categories']);
        categories.remove(category);
        transaction.set(docRef, {'categories': categories}, SetOptions(merge: true));
      }
    });
  }
}
