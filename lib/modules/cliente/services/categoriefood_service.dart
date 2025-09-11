import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/modules/cliente/models/foodCategory.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';

class CategorieFoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener el historial de pedidos de un usuario (mejorado)
  Stream<List<FoodCategory>> getCategoryFood() {
    return _firestore.collection('categorie-food').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        try {
          return FoodCategory.fromMap(data, id: doc.id);
        } catch (e) {
          // Si hay error en los datos, retorna un FoodCategory vacío o lanza excepción
          return FoodCategory(
            id: doc.id,
            category: '',
            description: '',
            imageUrl: '',
          );
        }
      }).toList();
    });
  }
}
