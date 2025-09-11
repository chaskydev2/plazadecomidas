import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:image_picker/image_picker.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Gestión de Categorías
  Future<List<Map<String, dynamic>>> getCategorieFood() async {
    final snapshot = await _firestore.collection('categorie-food').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
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
}
