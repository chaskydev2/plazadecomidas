import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ClientOrder>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => ClientOrder.fromJson({
            'id': doc.id,
            ...doc.data(),
          })).toList();
    } catch (e) {
      rethrow;
    }
  }
} 