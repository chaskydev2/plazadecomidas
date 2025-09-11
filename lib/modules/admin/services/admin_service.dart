import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:image_picker/image_picker.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Gestión de usuarios
  Future<List<Map<String, dynamic>>> getUsers({
    required String restaurantId,
  }) async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      // Obtener el usuario actual
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final currentRole = userData['role'];
      final currentRestaurantId = userData['restaurantId'];

      // Si el usuario era manager y está cambiando a otro rol
      if (currentRole == 'manager' &&
          newRole != 'manager' &&
          currentRestaurantId != null) {
        // Actualizar el restaurante para quitar el managerId
        await _firestore
            .collection('restaurants')
            .doc(currentRestaurantId)
            .update({'managerId': null});
      }

      // Actualizar el rol del usuario
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'restaurantId': newRole == 'manager' ? currentRestaurantId : null,
      });
    } catch (e) {
      print('Error al actualizar rol de usuario: $e');
      throw Exception('Error al actualizar rol de usuario: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    required String restaurantId,
    String? branchId,
  }) async {
    try {
      // Crear usuario en Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Crear0 documento en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).update(userData);
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  // Gestión de restaurantes
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    final snapshot = await _firestore.collection('restaurants').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> createRestaurant(Map<String, dynamic> restaurantData) async {
    await _firestore.collection('restaurants').add(restaurantData);
  }

  Future<void> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> restaurantData,
  ) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .update(restaurantData);
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    await _firestore.collection('restaurants').doc(restaurantId).delete();
  }

  // Asignación de managers
  Future<void> assignManagerToRestaurant(
    String userId,
    String restaurantId,
  ) async {
    // Primero actualizamos el rol del usuario a manager
    await _firestore.collection('users').doc(userId).update({
      'role': 'manager',
      'restaurantId': restaurantId,
    });

    // Luego actualizamos el restaurante con el ID del manager
    await _firestore.collection('restaurants').doc(restaurantId).update({
      'managerId': userId,
    });
  }

  // Obtener lista de restaurantes disponibles (sin manager asignado)
  Future<List<Map<String, dynamic>>> getAvailableRestaurants() async {
    try {
      // Obtener todos los restaurantes
      final snapshot = await _firestore.collection('restaurants').get();

      // Filtrar los restaurantes que no tienen manager o tienen managerId null
      final restaurants =
          snapshot.docs
              .where((doc) {
                final data = doc.data();
                return !data.containsKey('managerId') ||
                    data['managerId'] == null;
              })
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              })
              .toList();

      return restaurants;
    } catch (e) {
      print('Error al obtener restaurantes disponibles: $e');
      throw Exception('Error al obtener restaurantes disponibles: $e');
    }
  }

  // Obtener lista de usuarios que pueden ser managers
  Future<List<Map<String, dynamic>>> getPotentialManagers() async {
    final snapshot =
        await _firestore
            .collection('users')
            .where('role', whereIn: ['client', 'unknown'])
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Obtener el restaurante asignado a un manager
  Future<Map<String, dynamic>?> getManagerRestaurant(String managerId) async {
    final snapshot =
        await _firestore
            .collection('restaurants')
            .where('managerId', isEqualTo: managerId)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    }
    return null;
  }

  // Estadísticas
  Future<Map<String, dynamic>> getStatistics() async {
    final usersCount = await _firestore.collection('users').count().get();
    final restaurantsCount =
        await _firestore.collection('restaurants').count().get();
    final ordersCount = await _firestore.collection('orders').count().get();

    return {
      'usersCount': usersCount.count,
      'restaurantsCount': restaurantsCount.count,
      'ordersCount': ordersCount.count,
    };
  }

  // Monitoreo y Estadísticas
  Future<Map<String, dynamic>> getGlobalStatistics() async {
    try {
      // Implementar lógica para obtener estadísticas globales
      return {};
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRestaurantPerformance(
    String restaurantId,
  ) async {
    try {
      // Implementar lógica para obtener rendimiento del restaurante
      return [];
    } catch (e) {
      throw Exception('Error al obtener rendimiento: $e');
    }
  }

  // Historial de Actividades
  Future<List<Map<String, dynamic>>> getUserActivityLog(String userId) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('activity_logs')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Error al obtener historial de actividades: $e');
    }
  }

  Future<String?> uploadImageToApi(
    XFile file,
    String folder, {
    Uint8List? webBytes,
  }) async {
    final uri = Uri.parse(
      'https://apiplazacomida.chaskydev.com/api/v1/images/save',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['folder'] = folder;

    if (kIsWeb) {
      // En Web no hay path real, así que enviamos bytes
      final bytes = webBytes ?? await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name, // conserva el nombre subido
        ),
      );
    } else {
      // En móvil/escritorio podemos usar el path del archivo
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map &&
          data['url'] != null &&
          data['url'].toString().isNotEmpty) {
        return data['url'];
      }
      throw Exception('Respuesta JSON sin URL válida: ${response.body}');
    } else {
      throw Exception(
        'Error al subir imagen al API: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> assignUserToBranch({
    required String userId,
    required String restaurantId,
    required String branchId,
  }) async {
    await updateUser(userId, {
      'restaurantId': restaurantId,
      'branchId': branchId,
    });
  }
}
