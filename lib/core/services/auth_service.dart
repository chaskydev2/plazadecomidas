import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/core/models/user_role.dart';
import 'package:kokorestaurant/main.dart';
import 'package:flutter/material.dart';
import 'package:kokorestaurant/modules/shared/screens/login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Crear cuenta de administrador inicial
  Future<void> createInitialAdmin() async {
    try {
      // Verificar si ya existe un administrador
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (adminQuery.docs.isEmpty) {
        // Crear usuario en Authentication
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: 'pepe@gmail.com',
          password: 'pepe4582',
        );

        // Crear documento en Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': 'pepe@gmail.com',
          'name': 'Administrador',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Error al crear administrador inicial: $e');
    }
  }

  // Iniciar sesión
  Future<User?> signIn(String email, String password, BuildContext context) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Verificar si el usuario existe en Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'role': 'client', // Rol por defecto
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      return userCredential.user;
    } catch (e) {
      throw e;
    }
  }

  // Registro e inicio de sesión con Google
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null; // Cancelado por el usuario
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);

      // Si es la primera vez, crea el usuario en Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName ?? '',
          'role': 'client',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      return userCredential.user;
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut(BuildContext context, {bool skipConfirmation = false}) async {
    try {
      if (!skipConfirmation) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
      await _auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyApp()),
          (route) => false,
        );
      }
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Cambiar contraseña
  Future<void> changePassword(User user, {
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Reautenticar al usuario
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Actualizar la contraseña
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Error al cambiar la contraseña: $e');
    }
  }

  // Obtener usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario actual: $e');
    }
  }

  // Registrar usuario
  Future<User?> register(String email, String password, String name, BuildContext context) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        // No se pudo crear el usuario en Auth
        return null;
      }
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'name': name,
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return user;
    } catch (e) {
      throw e;
    }
  }

  Future<UserRole> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return UserRole.unknown;
      }
      return UserRoleExtension.fromString(doc.data()?['role']);
    } catch (e) {
      return UserRole.unknown;
    }
  }

  /// Crea la cuenta de administrador inicial si no existe
  Future<void> createInitialAdminAccount() async {
    try {
      print('Iniciando creación de cuenta de administrador...');
      
      // Verificar si ya existe un administrador en Firestore
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (adminQuery.docs.isEmpty) {
        print('No se encontró un administrador en Firestore, creando uno nuevo...');
        
        // Crear usuario en Authentication
        UserCredential userCredential;
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: 'pepe@gmail.com',
            password: 'pepe4582',
          );
          print('Usuario creado en Authentication con éxito');
          
          // Obtener el UID del usuario
          final uid = userCredential.user!.uid;
          print('UID del usuario: $uid');
          
          // Crear el documento en Firestore
          await _firestore.collection('users').doc(uid).set({
            'name': 'Administrador',
            'email': 'pepe@gmail.com',
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          print('Documento de administrador creado en Firestore');
          print('Email: pepe@gmail.com');
          print('Contraseña: pepe4582');
          
          // Cerrar sesión inmediatamente después de crear la cuenta
          await _auth.signOut();
          print('Sesión cerrada después de crear la cuenta de administrador');
        } catch (e) {
          print('Error al crear usuario en Authentication: $e');
          
          // Si el usuario ya existe, solo verificamos que tenga el rol de admin en Firestore
          if (e.toString().contains('email-already-in-use')) {
            print('El correo ya está en uso, verificando rol en Firestore...');
            
            // Buscar el usuario por email
            final userQuery = await _firestore
                .collection('users')
                .where('email', isEqualTo: 'pepe@gmail.com')
                .get();
                
            if (userQuery.docs.isEmpty) {
              // El usuario existe en Authentication pero no en Firestore
              // Intentamos iniciar sesión para obtener el UID
              userCredential = await _auth.signInWithEmailAndPassword(
                email: 'pepe@gmail.com',
                password: 'pepe4582',
              );
              
              final uid = userCredential.user!.uid;
              
              // Crear el documento en Firestore
              await _firestore.collection('users').doc(uid).set({
                'name': 'Administrador',
                'email': 'pepe@gmail.com',
                'role': 'admin',
                'createdAt': FieldValue.serverTimestamp(),
              });
              
              print('Documento de administrador creado en Firestore para usuario existente');
              
              // Cerrar sesión
              await _auth.signOut();
              print('Sesión cerrada después de crear la cuenta de administrador');
            } else {
              print('El usuario ya existe en Firestore con rol: ${userQuery.docs.first.data()['role']}');
            }
          } else {
            rethrow; // Si es otro tipo de error, lo propagamos
          }
        }
      } else {
        print('Ya existe un administrador en el sistema');
      }
    } catch (e) {
      print('Error al crear la cuenta de administrador: $e');
    }
  }
} 