// lib/modules/admin/services/branch_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BranchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getBranchesWithRestaurant(
    String restaurantId,
  ) async {
    if (restaurantId.trim().isEmpty) {
      throw ArgumentError('El restaurantId está vacío.');
    }
    try {
      final query =
          await _firestore
              .collection('branch')
              .where('restaurantId', isEqualTo: restaurantId)
              .get();

      if (query.docs.isEmpty) {
        throw StateError(
          'No se encontraron sucursales para el restaurante $restaurantId.',
        );
      }

      const requiredKeys = ['nombre', 'direccion', 'restaurantId'];
      final result = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final data = doc.data();
        final missing = <String>[];
        for (final k in requiredKeys) {
          if (!data.containsKey(k) || data[k] == null) missing.add(k);
        }
        if (missing.isNotEmpty) {
          throw FormatException(
            'El documento ${doc.id} no tiene los campos requeridos: ${missing.join(", ")}.',
          );
        }
        result.add({'id': doc.id, ...data});
      }
      return result;
    } on FirebaseException catch (e) {
      throw Exception('Error de Firestore (${e.code}): ${e.message}');
    }
  }

  /// Todas las sucursales (colección correcta: 'branch')
  Future<List<Map<String, dynamic>>> getBranches() async {
    final snap = await _firestore.collection('branch').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
