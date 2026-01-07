// Script temporal para arreglar el usuario admin en Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🔧 Iniciando corrección del usuario admin...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // Buscar el usuario admin por email
    print('📧 Buscando usuario con email: pepe@gmail.com');

    final userQuery =
        await firestore
            .collection('users')
            .where('email', isEqualTo: 'pepe@gmail.com')
            .get();

    if (userQuery.docs.isEmpty) {
      print('❌ No se encontró el usuario admin en Firestore');
      print('🔄 Intentando autenticar para obtener UID...');

      try {
        final userCredential = await auth.signInWithEmailAndPassword(
          email: 'pepe@gmail.com',
          password: 'pepe4582',
        );

        final uid = userCredential.user!.uid;
        print('✅ Usuario autenticado. UID: $uid');

        // Crear/actualizar el documento con TODOS los campos necesarios
        await firestore.collection('users').doc(uid).set({
          'email': 'pepe@gmail.com',
          'name': 'Administrador',
          'role': 'admin',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'lastLogin': DateTime.now(),
          'active': true,
          'notifications': true,
        }, SetOptions(merge: true));

        print('✅ Documento de admin actualizado correctamente');

        // Cerrar sesión
        await auth.signOut();
        print('🔓 Sesión cerrada');
      } catch (e) {
        print('❌ Error al autenticar: $e');
      }
    } else {
      final doc = userQuery.docs.first;
      print('✅ Usuario encontrado. UID: ${doc.id}');
      print('📄 Datos actuales: ${doc.data()}');

      // Actualizar con todos los campos necesarios
      await firestore.collection('users').doc(doc.id).update({
        'email': 'pepe@gmail.com',
        'name': 'Administrador',
        'role': 'admin',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'lastLogin': DateTime.now(),
        'active': true,
        'notifications': true,
      });

      print('✅ Documento actualizado correctamente');
    }

    print('\n✨ Proceso completado exitosamente');
    print('💡 Ahora puedes hacer login con:');
    print('   Email: pepe@gmail.com');
    print('   Password: pepe4582');
  } catch (e) {
    print('❌ Error: $e');
  }
}
