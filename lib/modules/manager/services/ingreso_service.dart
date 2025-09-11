import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/modules/manager/models/ingreso.dart';

class IngresoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referencia a la colección de ingresos de un restaurante
  CollectionReference _ingresosCollection(String restauranteId) {
    return _firestore
        .collection('restaurants')
        .doc(restauranteId)
        .collection('ingresos');
  }

  // Guardar un nuevo ingreso
  Future<void> guardarIngreso(Ingreso ingreso) async {
    try {
      final docRef = await _ingresosCollection(ingreso.restauranteId).add(ingreso.toJson());
      
      // Actualizar el ID del ingreso con el ID generado por Firestore
      await _ingresosCollection(ingreso.restauranteId)
          .doc(docRef.id)
          .update({'id': docRef.id});
    } catch (e) {
      throw Exception('Error al guardar el ingreso: $e');
    }
  }

  // Obtener ingresos por rango de fechas
  Stream<List<Ingreso>> obtenerIngresos(
    String restauranteId, {
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) {
    return _ingresosCollection(restauranteId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin))
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ingreso.desdeJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Obtener el total de ingresos en un rango de fechas
  Stream<double> obtenerTotalIngresos(
    String restauranteId, {
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async* {
    try {
      Query query = _ingresosCollection(restauranteId)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
      
      final querySnapshot = await query.get();
      
      double total = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['monto'] as num).toDouble();
      }
      
      yield total;
    } catch (e) {
      throw Exception('Error al calcular el total de ingresos: $e');
    }
  }

  // Eliminar un ingreso (solo para administradores)
  Future<void> eliminarIngreso(String restauranteId, String ingresoId) async {
    try {
      await _ingresosCollection(restauranteId).doc(ingresoId).delete();
    } catch (e) {
      throw Exception('Error al eliminar el ingreso: $e');
    }
  }
}
