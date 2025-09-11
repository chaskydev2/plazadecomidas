import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import 'package:kokorestaurant/modules/manager/screens/manager_profile_screen.dart';

class ManagerSettingsScreen extends StatefulWidget {
  final String restaurantId;

  const ManagerSettingsScreen({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<ManagerSettingsScreen> createState() => _ManagerSettingsScreenState();
}

class _ManagerSettingsScreenState extends State<ManagerSettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _selectedLanguage = 'es';
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _tableNotifications = true;
  bool _orderNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _selectedLanguage = data['language'] ?? 'es';
            _isDarkMode = data['darkMode'] ?? false;
            _notificationsEnabled = data['notifications'] ?? true;
            _tableNotifications = data['tableNotifications'] ?? true;
            _orderNotifications = data['orderNotifications'] ?? true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFD91010),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notificaciones
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.notifications, color: Color(0xFFD91010)),
                title: const Text('Notificaciones'),
                subtitle: const Text('Configurar notificaciones del sistema'),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
              ),
            ),

            // Notificaciones de Mesas
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.table_bar, color: Color(0xFFD91010)),
                title: const Text('Notificaciones de Mesas'),
                subtitle: const Text('Recibir notificaciones sobre cambios en mesas'),
                trailing: Switch(
                  value: _tableNotifications,
                  onChanged: (value) {
                    setState(() => _tableNotifications = value);
                  },
                ),
              ),
            ),

            // Notificaciones de Pedidos
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.shopping_cart, color: Color(0xFFD91010)),
                title: const Text('Notificaciones de Pedidos'),
                subtitle: const Text('Recibir notificaciones sobre nuevos pedidos'),
                trailing: Switch(
                  value: _orderNotifications,
                  onChanged: (value) {
                    setState(() => _orderNotifications = value);
                  },
                ),
              ),
            ),

            // Perfil
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.person, color: Color(0xFFD91010)),
                title: const Text('Configuración de Perfil'),
                subtitle: const Text('Cambiar nombre y contraseña'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManagerProfileScreen(restaurantId: widget.restaurantId),
                    ),
                  );
                },
              ),
            ),

            // Idioma
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.language, color: Color(0xFFD91010)),
                title: const Text('Idioma'),
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: const [
                    DropdownMenuItem(
                      value: 'es',
                      child: Text('Español'),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('Inglés'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value!);
                  },
                ),
              ),
            ),

            // Modo Oscuro
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.dark_mode, color: Color(0xFFD91010)),
                title: const Text('Modo Oscuro'),
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() => _isDarkMode = value);
                  },
                ),
              ),
            ),

            // Acerca de
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFFD91010)),
                title: const Text('Acerca de'),
                subtitle: const Text('Información sobre la aplicación'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Acerca de KOKO Restaurant'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Versión 1.0.0'),
                          const SizedBox(height: 16),
                          const Text('Desarrollado por:'),
                          const Text('Tu Empresa'),
                          const SizedBox(height: 8),
                          const Text('Contacto:'),
                          Row(
                            children: [
                              const Icon(Icons.email, color: Color(0xFFD91010)),
                              const SizedBox(width: 8),
                              const Text('KookoRestaurant@gmail.com'),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Cerrar Sesión
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFD91010)),
                title: const Text('Cerrar Sesión'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}