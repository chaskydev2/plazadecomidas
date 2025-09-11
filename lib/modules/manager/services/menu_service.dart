import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../cliente/models/menu_item.dart' as client_models;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data' show Uint8List;
import 'package:path/path.dart' as path;
import 'dart:convert';

import 'package:http/http.dart' as http;

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Obtener todos los platos del menú de un restaurante
  Stream<List<client_models.MenuItem>> getMenuItems(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_items')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return client_models.MenuItem.fromJson({'id': doc.id, ...data});
          }).toList();
        });
  }

  // Subir imagen al Storage
  Future<String> _uploadImage(
    String restaurantId,
    String menuItemId,
    XFile imageFile,
  ) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final Reference ref = _storage.ref().child(
        'restaurants/$restaurantId/menu_items/$menuItemId/$fileName',
      );

      if (kIsWeb) {
        // Para web, usamos putData con los bytes de la imagen
        final bytes = await imageFile.readAsBytes();
        await ref.putData(bytes);
      } else {
        // Para móvil, usamos putFile
        await ref.putFile(File(imageFile.path));
      }

      // Obtener la URL de descarga
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      rethrow;
    }
  }

  // Eliminar imagen del Storage
  Future<void> _deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      print('Error al eliminar imagen: $e');
      // No relanzamos el error para no interrumpir el flujo principal
    }
  }

  // Agregar un nuevo plato al menú
  Future<void> addMenuItem(client_models.MenuItem item) async {
    try {
      print('Agregando nuevo plato al menú...');
      final docRefMenu = _firestore.collection('menu-item').doc();

      // Crear referencia del documento
      final docRef =
          _firestore
              .collection('restaurants')
              .doc(item.restaurantId)
              .collection('menu_items')
              .doc();

      // Crear el nuevo MenuItem con el ID generado
      final newItem = client_models.MenuItem(
        id: docRef.id,
        name: item.name,
        description: item.description,
        price: item.price,
        restaurantId: item.restaurantId,
        isAvailable: item.isAvailable,
        imageUrl: item.imageUrl,
        variations: item.variations,
        categories: item.categories,
      );

      // Guardar en firestore
      await docRef.set(newItem.toJson());

      // Crear el nuevo MenuItem con el ID generado
      final newItemGlobal = client_models.MenuItem(
        id: docRefMenu.id,
        name: item.name,
        description: item.description,
        price: item.price,
        restaurantId: item.restaurantId,
        isAvailable: item.isAvailable,
        imageUrl: item.imageUrl,
        variations: item.variations,
        categories: item.categories,
      );

      await docRefMenu.set(newItemGlobal.toJson());

      print('Plato guardado exitosamente');
    } catch (e) {
      print('Error en addMenuItem: ${e.toString()}');
      if (e is FirebaseException) {
        throw Exception('Error de Firebase: ${e.message}');
      }
      rethrow;
    }
  }

  // Actualizar un plato existente
  Future<void> updateMenuItem(client_models.MenuItem item) async {
    try {
      // Actualizar en Firestore
      await _firestore
          .collection('restaurants')
          .doc(item.restaurantId)
          .collection('menu_items')
          .doc(item.id)
          .update(item.toJson());
    } catch (e) {
      print('Error en updateMenuItem: ${e.toString()}');
      if (e is FirebaseException) {
        throw Exception('Error de Firebase: ${e.message}');
      }
      rethrow;
    }
  }

  // Subir una imagen al almacenamiento
  Future<String> uploadImage(
    String restaurantId,
    XFile imageFile, {
    Uint8List? webImage,
  }) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.name);
      String fullPath = 'menu_images/$restaurantId/$fileName$extension';

      // Subir la imagen
      if (kIsWeb) {
        // Para web
        final metadata = SettableMetadata(
          contentType: 'image/${extension.replaceAll('.', '')}',
        );
        final uploadTask = _storage
            .ref(fullPath)
            .putData(await imageFile.readAsBytes(), metadata);
        await uploadTask;
      } else {
        // Para móviles/escritorio
        final uploadTask = _storage.ref(fullPath).putFile(File(imageFile.path));
        await uploadTask;
      }

      // Obtener la URL de descarga
      String downloadUrl = await _storage.ref(fullPath).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir la imagen: $e');
      rethrow;
    }
  }

  // Eliminar un plato del menú
  Future<void> deleteMenuItem(client_models.MenuItem item) async {
    try {
      // Primero eliminamos la imagen si existe
      await _deleteImage(item.imageUrl);

      // Luego eliminamos el documento de Firestore
      await _firestore
          .collection('restaurants')
          .doc(item.restaurantId)
          .collection('menu_items')
          .doc(item.id)
          .delete();
      print('Plato eliminado exitosamente');
    } catch (e) {
      print('Error al eliminar el plato: ${e.toString()}');
      rethrow;
    }
  }

  // Cambiar la disponibilidad de un item
  Future<void> toggleItemAvailability(
    String menuItemId,
    bool isAvailable,
    String restaurantId,
  ) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu_items')
          .doc(menuItemId)
          .update({'isAvailable': isAvailable});
    } catch (e) {
      print('Error al cambiar la disponibilidad: ${e.toString()}');
      rethrow;
    }
  }

  /// Sube una imagen a un backend externo usando POST multipart/form-data
  /// [file] es la imagen (XFile), [folder] es la carpeta destino en el backend
  /// Retorna la URL de la imagen guardada si es exitoso
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
}
