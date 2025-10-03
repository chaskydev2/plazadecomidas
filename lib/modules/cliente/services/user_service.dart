// lib/modules/cliente/services/user_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:kokorestaurant/modules/cliente/models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// -------------------------
  /// Lectura de datos de usuario
  /// -------------------------
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) throw Exception('Usuario no encontrado');
      final data = doc.data();
      if (data == null) throw Exception('Datos del usuario inválidos');
      return {'id': doc.id, ...data};
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) throw Exception('Usuario no encontrado');
      final data = doc.data();
      if (data == null) throw Exception('Datos del usuario inválidos');
      return UserProfile.fromJson({'id': doc.id, ...data});
    } catch (e) {
      rethrow;
    }
  }

  /// -------------------------
  /// Escritura de perfil
  /// -------------------------
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// -----------------------------------------------
  /// Subir imagen a tu API (que guarda en AWS S3) y
  /// devolver la URL pública resultante
  /// -----------------------------------------------
  Future<String> uploadAvatarToApi(
    XFile file, {
    required String folder, // e.g. 'users/<uid>'
    Uint8List? webBytes,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('https://apiplazacomida.chaskydev.com/api/v1/images/save');

    final request = http.MultipartRequest('POST', uri)
      ..fields['folder'] = folder;

    if (headers != null && headers.isNotEmpty) {
      request.headers.addAll(headers);
    }

    if (kIsWeb) {
      final bytes = webBytes ?? await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw Exception('Error al subir imagen: ${resp.statusCode} ${resp.body}');
    }

    final body = json.decode(resp.body);
    final url = (body is Map) ? body['url']?.toString() : null;
    if (url == null || url.isEmpty) {
      throw Exception('Respuesta JSON sin URL válida: ${resp.body}');
    }
    return url;
  }

  /// ---------------------------------------------------------
  /// Helper: Sube y guarda el avatar en Firestore (photoUrl)
  /// ---------------------------------------------------------
  Future<String> saveAvatar(
    String userId,
    XFile file, {
    Uint8List? webBytes,
    Map<String, String>? headers,
  }) async {
    // 1) Subir a carpeta users/<uid> en tu backend (S3)
    final folder = 'users/$userId';
    final url = await uploadAvatarToApi(
      file,
      folder: folder,
      webBytes: webBytes,
      headers: headers,
    );

    // 2) Guardar URL en Firestore
    await _firestore.collection('users').doc(userId).update({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return url;
  }

  /// (Opcional) Quitar foto de perfil
  Future<void> removeAvatar(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'photoUrl': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
