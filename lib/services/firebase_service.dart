import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para crear un usuario en Firestore
  Future<void> createUser(User user, String name) async {
    try {
      await _firestore.collection('usuarios').doc(user.uid).set({
        'nombre': name,
        'correo': user.email,
        'fotoPerfil': user.photoURL ?? '', // Si tiene foto de perfil
        'fechaCreacion': FieldValue.serverTimestamp(),
        'rol': 'cliente', // Por defecto el rol será cliente
      });
    } catch (e) {
      print('Error creando el usuario: $e');
    }
  }
}
