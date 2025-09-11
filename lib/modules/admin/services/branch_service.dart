import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:image_picker/image_picker.dart';

class BranchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Gestión de Ramas
  Future<List<Map<String, dynamic>>> getBranchesWithRestaurant(
    String restaurantId,
  ) async {
    // 1) Validación de entrada
    if (restaurantId.trim().isEmpty) {
      throw ArgumentError('El restaurantId está vacío.');
    }

    try {
      // 2) Consulta. OJO: en tu captura la colección es "branch"
      final query =
          await _firestore
              .collection('branch')
              .where('restaurantId', isEqualTo: restaurantId)
              .get();

      // 3) Sin resultados
      if (query.docs.isEmpty) {
        throw StateError(
          'No se encontraron sucursales para el restaurante $restaurantId.',
        );
      }

      // 4) Validación de estructura por documento
      const requiredKeys = ['nombre', 'direccion', 'restaurantId'];
      final result = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final data = doc.data();

        // En algunos docs podrías tener el typo "lant" en vez de "lat"
        // y "long" para la longitud. Aquí solo validamos mínimos.
        final missing = <String>[];
        for (final k in requiredKeys) {
          if (!data.containsKey(k) || data[k] == null) missing.add(k);
        }

        if (missing.isNotEmpty) {
          throw FormatException(
            'El documento ${doc.id} no tiene los campos requeridos: ${missing.join(", ")}.',
          );
        }

        result.add({
          'id': doc.id, // útil en UI
          ...data,
        });
      }

      return result;
    } on FirebaseException catch (e, st) {
      print('Firestore error (${e.code}): ${e.message}\n$st');
      throw Exception('Error de Firestore (${e.code}): ${e.message}');
    } on FormatException catch (e, st) {
      print('Formato inválido: $e\n$st');
      throw Exception(
        'Datos de sucursal con formato inválido. Detalle: ${e.message}',
      );
    } on StateError catch (e, st) {
      print('Estado inválido: $e\n$st');
      throw Exception(e.message);
    } catch (e, st) {
      print('Error inesperado en getBranchesWithRestaurant: $e\n$st');
      throw Exception('No se pudo cargar las sucursales. Detalle: $e');
    }
  }

  // Gestión de Ramas
  Future<List<Map<String, dynamic>>> getBranches() async {
    final snapshot = await _firestore.collection('branches').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
