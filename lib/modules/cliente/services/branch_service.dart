import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:kokorestaurant/modules/admin/models/branch_model.dart';

class BranchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Gestión de Ramas

  Future<List<Branch>> getBrancheswithRestaurant(String restaurantId) async {
    final snapshot =
        await _firestore
            .collection('branches')
            .where('restaurantId', isEqualTo: restaurantId)
            .get();
    return snapshot.docs.map((doc) => Branch.fromMap(doc.data())).toList();
  }

  // Gestión de Ramas
  Future<List<Branch>> getBranches() async {
    final snapshot = await _firestore.collection('branches').get();
    return snapshot.docs.map((doc) => Branch.fromMap(doc.data())).toList();
  }
}
