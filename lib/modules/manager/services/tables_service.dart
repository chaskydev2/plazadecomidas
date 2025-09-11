import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/table.dart';

class TablesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todas las mesas de un restaurante
  Stream<List<RestaurantTable>> getTables(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .orderBy('number')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RestaurantTable.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }))
            .toList());
  }

  // Agregar una nueva mesa
  Future<String> addTable(RestaurantTable table) async {
    try {
      print('Intentando agregar mesa: ${table.toJson()}');
      
      // Verificar si ya existe una mesa con el mismo número
      final existingTable = await _firestore
          .collection('restaurants')
          .doc(table.restaurantId)
          .collection('tables')
          .where('number', isEqualTo: table.number)
          .limit(1)
          .get();

      if (existingTable.docs.isNotEmpty) {
        throw Exception('Ya existe una mesa con el número ${table.number}');
      }

      // Crear la referencia al documento de la mesa
      final docRef = _firestore
          .collection('restaurants')
          .doc(table.restaurantId)
          .collection('tables')
          .doc();

      // Crear el objeto de la mesa con el ID generado
      final tableWithId = table.copyWith(id: docRef.id);
      
      // Guardar en Firestore
      await docRef.set(tableWithId.toJson());
      
      print('Mesa agregada exitosamente con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error al agregar mesa: $e');
      rethrow;
    }
  }

  // Actualizar el código QR de una mesa
  Future<void> updateTableQR(String restaurantId, String tableId, Map<String, dynamic> qrData) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .doc(tableId)
          .update({
            'qrCode': jsonEncode(qrData),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error al actualizar QR: $e');
      rethrow;
    }
  }

  // Eliminar una mesa
  Future<void> deleteTable(String restaurantId, String tableId) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .doc(tableId)
          .delete();
    } catch (e) {
      print('Error al eliminar mesa: $e');
      rethrow;
    }
  }

  // Cambiar el estado de ocupación de una mesa
  Future<void> updateTableStatus(String restaurantId, String tableId, bool isOccupied) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .doc(tableId)
          .update({
            'isOccupied': isOccupied,
            'lastOccupiedAt': isOccupied ? FieldValue.serverTimestamp() : null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error al actualizar estado de mesa: $e');
      rethrow;
    }
  }

  // Obtener una mesa por su ID
  Future<RestaurantTable?> getTableById(String restaurantId, String tableId) async {
    try {
      final doc = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .doc(tableId)
          .get();

      if (!doc.exists) return null;

      return RestaurantTable.fromJson({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error al obtener mesa por ID: $e');
      rethrow;
    }
  }
}