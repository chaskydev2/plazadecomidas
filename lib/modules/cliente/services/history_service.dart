import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/modules/admin/models/branch_model.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ClientOrder>> getUserOrderHistory(String userId) {
    final Map<String, Map<String, dynamic>?> restaurantCache = {};
    final Map<String, Map<String, dynamic>?> branchCache = {};

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('order_history')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          return Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();

              final String restaurantId =
                  (data['restaurantId'] ?? '') as String;
              final String idSucursal = (data['idSucursal'] ?? '') as String;

              // --- Restaurante (cache) ---
              Map<String, dynamic>? restaurantData =
                  restaurantCache[restaurantId];
              if (restaurantData == null && restaurantId.isNotEmpty) {
                final rs =
                    await _firestore
                        .collection('restaurants')
                        .doc(restaurantId)
                        .get();
                restaurantData = rs.data();
                restaurantCache[restaurantId] = restaurantData;
              }

              // --- Branch (cache) -> colección raíz 'branch' ---
              Map<String, dynamic>? branchData = branchCache[idSucursal];
              if (branchData == null && idSucursal.isNotEmpty) {
                final bs =
                    await _firestore.collection('branch').doc(idSucursal).get();
                branchData = bs.data();
                branchCache[idSucursal] = branchData;
              }

              // Mapear a Branch? (si existe)
              Branch? branch;
              if (branchData != null) {
                branch = Branch.fromMap(branchData, id: idSucursal);
              }

              // Construimos el JSON que consume tu fromJson
              return ClientOrder.fromJson({
                ...data,
                'id': doc.id,
                'restaurantName': restaurantData?['name'],
                'restaurantAddress':
                    restaurantData?['location'] ?? restaurantData?['address'],

                // alias útiles para UI rápida
                'sucursalName': branch?.nombre,
                'sucursalAddress': branch?.direccion,
              });
            }).toList(),
          );
        });
  }

  // Agregar un pedido al historial
  Future<void> addToOrderHistory(String userId, ClientOrder order) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('order_history')
          .doc(order.id)
          .set(order.toJson());

      // Suscribirse a cambios en el pedido del restaurante
      _syncOrderStatus(userId, order);
    } catch (e) {
      throw Exception('Error al guardar en el historial: $e');
    }
  }

  // Sincronizar el estado del pedido con el del restaurante
  void _syncOrderStatus(String userId, ClientOrder order) {
    _firestore
        .collection('restaurants')
        .doc(order.restaurantId)
        .collection('orders')
        .doc(order.id)
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.exists) {
            final newStatus = OrderStatus.values.firstWhere(
              (e) => e.toString() == 'OrderStatus.${snapshot['status']}',
              orElse: () => OrderStatus.pending,
            );

            // Actualizar solo el estado en el historial del usuario
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('order_history')
                .doc(order.id)
                .update({
                  'status': newStatus.toString().split('.').last,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
          }
        });
  }
}
