// lib/modules/admin/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class UserService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getUsers({String? restaurantId}) async {
    try {
      Query<Map<String, dynamic>> q = _fs.collection('users');
      if (restaurantId != null && restaurantId.isNotEmpty) {
        q = q.where('restaurantId', isEqualTo: restaurantId);
      }
      final snap = await q.get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } on FirebaseException catch (e) {
      throw Exception('Firestore error (${e.code}): ${e.message}');
    }
  }

  /// Crea el usuario en Auth SIN cerrar tu sesión actual (app secundaria),
  /// y registra el doc en 'users/{uid}'.
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? restaurantId,
    String? branchId,
  }) async {
    FirebaseApp? tempApp;
    try {
      // App secundaria para no afectar la sesión del admin actual
      tempApp = await Firebase.initializeApp(
        name: 'temp_create_user',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;

      await _fs.collection('users').doc(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'restaurantId': restaurantId, // puede ser null
        'branchId': branchId, // puede ser null
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception('Auth error (${e.code}): ${e.message}');
    } on FirebaseException catch (e) {
      throw Exception('Firestore error (${e.code}): ${e.message}');
    } finally {
      // limpia la app temporal
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _fs.collection('users').doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Firestore error (${e.code}): ${e.message}');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await updateUser(userId, {'role': newRole});
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _fs.collection('users').doc(userId).delete();
      // Nota: borrar también de Auth requiere Admin SDK/Cloud Function.
    } on FirebaseException catch (e) {
      throw Exception('Firestore error (${e.code}): ${e.message}');
    }
  }

  /// Asigna (o re-asigna) una sucursal (branch) a un usuario.
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
