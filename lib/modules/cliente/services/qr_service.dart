import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/modules/manager/models/table.dart';
import '../models/menu_item.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'dart:convert';

class QRService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RestaurantTable?> sendOrder(
    String restaurantId,
    String? userName,
  ) async {
    try {
      // Obtener el próximo número de orden
      final nextOrderNumber = await getNextOrderNumber(restaurantId);

      // Obtener timestamp actual
      final timestamp = FieldValue.serverTimestamp();

      // Crear la referencia del documento de la orden
      final orderRef =
          _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .collection('orders')
              .doc();

      // Datos de la orden (puedes agregar más campos según tu modelo)
      final orderData = {
        'orderNumber': nextOrderNumber,
        'userName': userName ?? 'Invitado',
        'createdAt': timestamp,
        'status': 'pending',
        'items': [], // aquí puedes incluir los ítems si los tienes
      };

      // Guardar la orden
      await orderRef.set(orderData);

      // Puedes retornar algo si lo deseas, o simplemente confirmar el éxito
      print('Orden enviada con ID: ${orderRef.id}');
      return null; // si no necesitas retornar una mesa, podrías cambiar a Future<void>
    } catch (e) {
      print('Error en : $e');
      rethrow;
    }
  }

  // Validar QR y obtener información de la mesa
  Future<RestaurantTable?> validateQR(String qrCode) async {
    try {
      // Decodificar el código QR para obtener el ID del restaurante y el número de mesa
      Map<String, dynamic> qrData;
      try {
        qrData = jsonDecode(qrCode);
      } catch (e) {
        throw Exception('Formato de código QR inválido');
      }

      // Verificar que el código QR tiene el formato esperado
      if (qrData['restaurantId'] == null || qrData['tableNumber'] == null) {
        throw Exception('Código QR no contiene la información necesaria');
      }

      final restaurantId = qrData['restaurantId'].toString();
      final tableNumber = int.tryParse(qrData['tableNumber'].toString()) ?? 0;

      if (tableNumber <= 0) {
        throw Exception('Número de mesa inválido en el código QR');
      }

      // Buscar la mesa en el restaurante específico
      final snapshot =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(restaurantId)
              .collection('tables')
              .where('number', isEqualTo: tableNumber)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        throw Exception(
          'No se encontró la mesa $tableNumber en el restaurante',
        );
      }

      final doc = snapshot.docs.first;
      final tableData = doc.data();

      // Verificar que el código QR de la mesa coincide
      if (tableData['qrCode'] != qrCode) {
        throw Exception('El código QR no coincide con ninguna mesa registrada');
      }

      // Crear y retornar el objeto de la mesa
      return RestaurantTable.fromJson({
        'id': doc.id,
        'restaurantId': restaurantId,
        ...tableData,
      });
    } catch (e) {
      print('Error al validar QR: $e');
      rethrow;
    }
  }

  // Obtener el menú del restaurante asociado a la mesa
  Future<List<MenuItem>> getMenuForTable(
    String tableId,
    String restaurantId,
  ) async {
    try {
      // Verificar que la mesa existe
      final table = await RestaurantTable.getById(restaurantId, tableId);
      if (table == null) {
        throw Exception('No se encontró la mesa especificada');
      }

      // Obtener el menú del restaurante
      final menuSnapshot =
          await _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .collection('menu_items')
              .where('isAvailable', isEqualTo: true)
              .get();

      return menuSnapshot.docs
          .map((doc) => MenuItem.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      print('Error al obtener el menú: $e');
      rethrow;
    }
  }

  // Crear una orden para una mesa
  Future<String> createOrderForTable(
    String tableId,
    String restaurantId, {
    String? userName,
  }) async {
    try {
      // Verificar que la mesa existe
      final table = await RestaurantTable.getById(restaurantId, tableId);
      if (table == null) {
        throw Exception('La mesa no existe');
      }

      // Crear la referencia del documento de la orden
      final orderRef =
          _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .collection('orders')
              .doc();

      return orderRef.id;
    } catch (e) {
      print('Error al crear la orden: $e');
      rethrow;
    }
  }

  Future<String> createOrderForSend(
    String restaurantId, {
    String? userName,
  }) async {
    try {
      // Crear la referencia del documento de la orden
      final orderRef =
          _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .collection('orders')
              .doc();

      return orderRef.id;
    } catch (e) {
      print('Error al crear la orden: $e');
      rethrow;
    }
  }

  // Obtener el próximo número de orden para un restaurante
  Future<int> getNextOrderNumber(String restaurantId) async {
    try {
      // Primero, obtener el último número de orden
      final lastOrder =
          await _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .collection('orders')
              .orderBy('orderNumber', descending: true)
              .limit(1)
              .get();

      // Si no hay órdenes, empezar desde 1
      if (lastOrder.docs.isEmpty) {
        return 1;
      }

      // Obtener el último número de orden y sumar 1
      final lastOrderNumber =
          lastOrder.docs.first.data()['orderNumber'] as int? ?? 0;
      return lastOrderNumber + 1;
    } catch (e) {
      print('Error al obtener el número de orden: $e');
      // Si hay un error, devolver 1
      return 1;
    }
  }

  // Obtener todas las mesas de un restaurante
  static Stream<List<RestaurantTable>> getTablesStream(String restaurantId) {
    return RestaurantTable.streamTables(restaurantId);
  }

  // Crear una nueva mesa
  static Future<RestaurantTable> createTable({
    required int number,
    required String restaurantId,
    required String qrCode,
  }) async {
    return await RestaurantTable.create(
      number: number,
      restaurantId: restaurantId,
      qrCode: qrCode,
    );
  }

  // Eliminar una mesa
  static Future<void> deleteTable(String restaurantId, String tableId) async {
    try {
      await RestaurantTable.delete(restaurantId, tableId);
    } catch (e) {
      print('Error al eliminar la mesa: $e');
      rethrow;
    }
  }

  // Desocupar una mesa
  Future<void> releaseTable(RestaurantTable table) async {
    try {
      // Verificar que la tabla existe y está ocupada
      final tableDoc =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(table.restaurantId)
              .collection('tables')
              .doc(table.id)
              .get();

      if (!tableDoc.exists) {
        throw Exception('La mesa no existe');
      }

      if (!table.isOccupied) {
        throw Exception('La mesa ya está desocupada');
      }

      // Actualizar el estado de la mesa
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(table.restaurantId)
          .collection('tables')
          .doc(table.id)
          .update({
            'isOccupied': false,
            'lastOccupiedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error al desocupar la mesa: $e');
      rethrow;
    }
  }
}
