import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/modules/cliente/models/user_profile.dart';

class UserService {
  /// Obtiene toda la información del usuario como Map<String, dynamic>
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('Usuario no encontrado');
      }
      final data = doc.data();
      if (data == null) {
        throw Exception('Datos del usuario inválidos');
      }
      return {'id': doc.id, ...data};
    } catch (e) {
      rethrow;
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('Usuario no encontrado');
      }
      final data = doc.data();
      if (data == null) {
        throw Exception('Datos del usuario inválidos');
      }
      return UserProfile.fromJson({'id': doc.id, ...data});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      rethrow;
    }
  }
}
