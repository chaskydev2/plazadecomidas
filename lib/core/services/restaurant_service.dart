import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/core/services/storage_service.dart';
import 'dart:io';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'restaurants';
  final StorageService _storageService = StorageService();

  RestaurantService();

  // Crear un nuevo restaurante
  Future<Restaurant> createRestaurant({
    required String name,
    required String description,
    required String location,
    required List<String> openDays,
    required Map<String, String> openHours,
    required String googleMapsUrl,
    File? imageFile,
    File? logoFile,
  }) async {
    try {
      final now = DateTime.now();

      // Crear el documento en Firestore
      final docRef = await _firestore.collection(_collection).add({
        'name': name,
        'description': description,
        'location': location,
        'openDays': openDays,
        'openHours': openHours,
        'googleMapsUrl': googleMapsUrl,
        'managerId': null,
        'imageUrl': null,
        'logoUrl': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Subir la imagen principal y el logo
      String? imageUrl;
      String? logoUrl;

      if (imageFile != null) {
        imageUrl = await _storageService.uploadRestaurantImage(
          imageFile,
          docRef.id,
        );
      }

      if (logoFile != null) {
        logoUrl = await _storageService.uploadRestaurantLogo(
          logoFile,
          docRef.id,
        );
      }

      // Actualizar el documento con las URLs
      await docRef.update({
        'imageUrl': imageUrl,
        'logoUrl': logoUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Obtener el documento creado
      final doc = await docRef.get();

      // Crear y devolver el objeto Restaurant
      return Restaurant.fromFirestore(doc);
    } catch (e) {
      print('Error al crear restaurante: $e');
      throw Exception('Error al crear restaurante: $e');
    }
  }

  // Obtener todos los restaurantes
  Stream<List<Restaurant>> getRestaurants() {
    return _firestore.collection(_collection).orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
    });
  }

  // Obtener un restaurante por ID
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Restaurant.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error al obtener restaurante: $e');
      throw Exception('Error al obtener restaurante: $e');
    }
  }

  // Actualizar un restaurante
  Future<void> updateRestaurant(
    Restaurant restaurant, {
    File? newImageFile,
  }) async {
    try {
      // Si se proporciona una nueva imagen
      if (newImageFile != null) {
        // Si ya existe una imagen, eliminarla
        if (restaurant.imageUrl != null) {
          await _storageService.deleteRestaurantImage(restaurant.imageUrl!);
        }

        // Subir la nueva imagen
        final imageUrl = await _storageService.uploadRestaurantImage(
          newImageFile,
          restaurant.id,
        );

        // Actualizar el restaurante con la nueva URL de la imagen
        restaurant = restaurant.copyWith(
          imageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );
      }

      await _firestore
          .collection(_collection)
          .doc(restaurant.id)
          .update(restaurant.toFirestore());
    } catch (e) {
      print('Error al actualizar restaurante: $e');
      throw Exception('Error al actualizar restaurante: $e');
    }
  }

  // Eliminar un restaurante y todos sus datos relacionados
  Future<void> deleteRestaurant(String id) async {
    try {
      print('Iniciando eliminación del restaurante y datos relacionados...');
      // 1. Obtener el restaurante para conseguir el managerId y la URL de la imagen
      final restaurantDoc =
          await _firestore.collection(_collection).doc(id).get();
      if (!restaurantDoc.exists) {
        throw Exception('Restaurante no encontrado');
      }
      final restaurantData = restaurantDoc.data() as Map<String, dynamic>;
      final String? managerId = restaurantData['managerId'];
      // 2. (No eliminar imagen del storage)
      // 3. Eliminar todas las mesas del restaurante
      print('Eliminando mesas...');
      final tablesSnapshot =
          await _firestore
              .collection('tables')
              .where('restaurantId', isEqualTo: id)
              .get();

      for (var doc in tablesSnapshot.docs) {
        await doc.reference.delete();
      }
      print('${tablesSnapshot.docs.length} mesas eliminadas');

      // 4. Eliminar todos los platos del menú
      print('Eliminando platos del menú...');
      final menuItemsSnapshot =
          await _firestore
              .collection(_collection)
              .doc(id)
              .collection('menu_items')
              .get();

      for (var doc in menuItemsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('${menuItemsSnapshot.docs.length} platos eliminados');

      // 5. Si hay un manager asignado, actualizar su rol a 'client'
      if (managerId != null && managerId.isNotEmpty) {
        print('Actualizando rol del manager...');
        await _firestore.collection('users').doc(managerId).update({
          'role': 'client',
          'restaurantId': null,
        });
        print('Rol del manager actualizado a client');
      }

      // 6. Finalmente, eliminar el restaurante
      print('Eliminando restaurante...');
      await _firestore.collection(_collection).doc(id).delete();
      print('Restaurante eliminado exitosamente');
    } catch (e) {
      print('Error al eliminar restaurante y datos relacionados: $e');
      throw Exception('Error al eliminar restaurante y datos relacionados: $e');
    }
  }
}
