import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Subida universal: acepta File para móvil o bytes+fileName para web
  Future<String> uploadFileOrBytes({
    required String storagePath,
    File? file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    try {
      final ref = _storage.ref().child(storagePath);
      if (bytes != null) {
        await ref.putData(bytes);
      } else if (file != null) {
        await ref.putFile(file);
      } else {
        throw Exception('Debes proporcionar un archivo o bytes para subir.');
      }
      return await ref.getDownloadURL();
    } catch (e, stack) {
      if (e is FirebaseException) {
        print('FirebaseException details:');
        print('code: ${e.code}');
        print('message: ${e.message}');
        print('plugin: ${e.plugin}');
      }
      rethrow;
    }
  }

  // Subir imagen de restaurante
  Future<String> uploadRestaurantImage(
    File imageFile,
    String restaurantId,
  ) async {
    try {
      // Obtener la extensión del archivo
      String fileExtension = path.extension(imageFile.path);

      // Crear la referencia del archivo en Storage
      final ref = _storage.ref().child(
        'restaurants/$restaurantId/profile$fileExtension',
      );

      // Subir el archivo
      await ref.putFile(imageFile);

      // Obtener la URL de descarga
      String downloadURL = await ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      print('Error al subir imagen: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  // Eliminar imagen de restaurante
  Future<void> deleteRestaurantImage(String imageUrl) async {
    try {
      // Obtener la referencia del archivo desde la URL
      final ref = _storage.refFromURL(imageUrl);

      // Eliminar el archivo
      await ref.delete();
    } catch (e) {
      print('Error al eliminar imagen: $e');
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  // Subir logo de restaurante
  Future<String> uploadRestaurantLogo(
    File logoFile,
    String restaurantId,
  ) async {
    try {
      // Obtener la extensión del archivo
      String fileExtension = path.extension(logoFile.path);

      // Crear la referencia del archivo en Storage
      final ref = _storage.ref().child(
        'restaurants/$restaurantId/logo$fileExtension',
      );

      // Subir el archivo
      await ref.putFile(logoFile);

      // Obtener la URL de descarga
      String downloadURL = await ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      print('Error al subir logo: $e');
      throw Exception('Error al subir logo: $e');
    }
  }

  // Eliminar logo de restaurante
  Future<void> deleteRestaurantLogo(String logoUrl) async {
    try {
      // Obtener la referencia del archivo desde la URL
      final ref = _storage.refFromURL(logoUrl);

      // Eliminar el archivo
      await ref.delete();
    } catch (e) {
      print('Error al eliminar logo: $e');
      throw Exception('Error al eliminar logo: $e');
    }
  }
}
