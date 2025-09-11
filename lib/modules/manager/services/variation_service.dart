import 'package:cloud_firestore/cloud_firestore.dart';
import '../../cliente/models/menu_item.dart' as client_models;

class VariationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todas las plantillas de variantes
  Stream<List<client_models.Variation>> getVariationTemplates(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc('variation_templates')
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null || data['variations'] == null) {
        return <client_models.Variation>[];
      }
      return (data['variations'] as List)
          .map((v) => client_models.Variation.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    });
  }

  // Agregar una nueva plantilla de variante
  Future<void> addVariationTemplate(String restaurantId, client_models.Variation variation) async {
    final docRef = _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc('variation_templates');

    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      List<Map<String, dynamic>> variations = [];
      
      if (doc.exists && doc.data() != null && doc.data()!['variations'] != null) {
        variations = List<Map<String, dynamic>>.from(doc.data()!['variations']);
      }

      // Evitar duplicados
      if (!variations.any((v) => v['name'] == variation.name)) {
        variations.add(variation.toJson());
        transaction.set(docRef, {'variations': variations}, SetOptions(merge: true));
      }
    });
  }

  // Eliminar una plantilla de variante
  Future<void> removeVariationTemplate(String restaurantId, String variationName) async {
    final docRef = _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc('variation_templates');

    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists && doc.data() != null && doc.data()!['variations'] != null) {
        List<Map<String, dynamic>> variations = 
            List<Map<String, dynamic>>.from(doc.data()!['variations']);
        variations.removeWhere((v) => v['name'] == variationName);
        transaction.set(docRef, {'variations': variations}, SetOptions(merge: true));
      }
    });
  }
}
