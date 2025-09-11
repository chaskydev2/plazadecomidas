import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/core/services/restaurant_service.dart';
import 'package:kokorestaurant/theme/app_theme.dart';
import 'package:kokorestaurant/modules/admin/screens/user_profile_screen.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RestaurantService _restaurantService = RestaurantService();

  @override
  void initState() {
    super.initState();
    _setupRestaurantListener();
  }

  void _setupRestaurantListener() {
    _firestore.collection('restaurants').snapshots().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          final deletedRestaurantId = change.doc.id;
          final managers =
              await _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'manager')
                  .where('restaurantId', isEqualTo: deletedRestaurantId)
                  .get();

          for (var manager in managers.docs) {
            await _firestore.collection('users').doc(manager.id).update({
              'role': 'client',
              'restaurantId': '',
            });
          }
        }
      }
    });
  }

  Future<void> _changeUserRole(
    String userId,
    String newRole, {
    String? restaurantId,
  }) async {
    try {
      // Obtener el usuario actual para verificar su rol anterior
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final currentRole = userData['role'];
      final currentRestaurantId = userData['restaurantId'];

      // Si el usuario era manager, actualizar el restaurante anterior
      if (currentRole == 'manager' &&
          currentRestaurantId != null &&
          currentRestaurantId.isNotEmpty) {
        await _firestore
            .collection('restaurants')
            .doc(currentRestaurantId)
            .update({'managerId': null});
      }

      // Actualizar el rol del usuario
      final updateData = {'role': newRole};
      if (newRole == 'manager' && restaurantId != null) {
        updateData['restaurantId'] = restaurantId;
        // Actualizar el restaurante con el nuevo manager
        await _firestore.collection('restaurants').doc(restaurantId).update({
          'managerId': userId,
        });
      } else if (newRole != 'manager') {
        updateData['restaurantId'] = '';
      }

      await _firestore.collection('users').doc(userId).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol actualizado a ${_formatRole(newRole)}'),
            backgroundColor: const Color(0xFFD91010),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el rol: $e'),
            backgroundColor: const Color(0xFFD91010),
          ),
        );
      }
    }
  }

  Future<void> _showRestaurantDialog(String userId) async {
    try {
      final restaurants = await _restaurantService.getRestaurants().first;

      if (restaurants.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay restaurantes disponibles'),
              backgroundColor: Color(0xFFD91010),
            ),
          );
        }
        return;
      }

      final selectedRestaurant = await showDialog<Restaurant>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'Seleccionar Restaurante',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.restaurant,
                        color: Color(0xFFD91010),
                      ),
                      title: Text(
                        restaurant.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        restaurant.location,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () => Navigator.pop(context, restaurant),
                    );
                  },
                ),
              ),
            ),
      );

      if (selectedRestaurant != null) {
        await _changeUserRole(
          userId,
          'manager',
          restaurantId: selectedRestaurant.id,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar restaurante: $e'),
            backgroundColor: const Color(0xFFD91010),
          ),
        );
      }
    }
  }

  Future<void> _showRoleDialog(String userId, String currentRole) async {
    final newRole = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text(
              'Cambiar Rol',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleOption('admin', 'Administrador', currentRole),
                _buildRoleOption('manager', 'Gerente', currentRole),
                _buildRoleOption('client', 'Cliente', currentRole),
              ],
            ),
          ),
    );

    if (newRole != null && newRole != currentRole) {
      if (newRole == 'manager') {
        await _showRestaurantDialog(userId);
      } else {
        await _changeUserRole(userId, newRole);
      }
    }
  }

  Widget _buildRoleOption(String role, String displayName, String currentRole) {
    final isSelected = role == currentRole;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? const Color(0xFFD91010) : Colors.white70,
      ),
      title: Text(
        displayName,
        style: TextStyle(
          color: isSelected ? const Color(0xFFD91010) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => Navigator.pop(context, role),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFD91010);
      case 'manager':
        return Colors.blue;
      case 'client':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Gerente';
      case 'client':
        return 'Cliente';
      default:
        return role;
    }
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return 'Fecha no disponible';
  }

  Widget _buildUserCard(
    BuildContext context, {
    required String userId,
    required String email,
    String? name,
    required String role,
    String? restaurantId,
    Timestamp? createdAt,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => UserProfileScreen(
                      userId: userId,
                      userData: {
                        'email': email,
                        'name': name,
                        'role': role,
                        'restaurantId': restaurantId,
                        'createdAt': createdAt,
                      },
                    ),
              ),
            ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.primary.withOpacity(0.13),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _getRoleColor(role), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _getRoleColor(role).withOpacity(0.13),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(role).withOpacity(0.85),
                  child: Text(
                    name != null && name.isNotEmpty
                        ? name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).withOpacity(0.13),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatRole(role),
                            style: TextStyle(
                              color: _getRoleColor(role),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.calendar_today,
                            size: 13,
                            color: Colors.black26,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDate(createdAt),
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 11,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.primary.withOpacity(0.09),
                borderRadius: BorderRadius.circular(12),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Color(0xFFD91010),
                    size: 22,
                  ),
                  onPressed: () => _showRoleDialog(userId, role),
                  tooltip: 'Editar rol',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar los usuarios',
                style: TextStyle(color: Colors.red[700]),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD91010)),
              ),
            );
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final String userId = user.id;
              final String email = userData['email'] ?? 'Sin correo';
              final String role = userData['role'] ?? 'client';
              final String? restaurantId = userData['restaurantId'];
              final String? name = userData['name'];
              final Timestamp? createdAt = userData['createdAt'] as Timestamp?;

              return _buildUserCard(
                context,
                userId: userId,
                email: email,
                name: name,
                role: role,
                restaurantId: restaurantId,
                createdAt: createdAt,
              );
            },
          );
        },
      ),
    );
  }
}
