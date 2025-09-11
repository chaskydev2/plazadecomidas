import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class ManagerAssignmentScreen extends StatefulWidget {
  const ManagerAssignmentScreen({Key? key}) : super(key: key);

  @override
  _ManagerAssignmentScreenState createState() => _ManagerAssignmentScreenState();
}

class _ManagerAssignmentScreenState extends State<ManagerAssignmentScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _potentialManagers = [];
  List<Map<String, dynamic>> _availableRestaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final managers = await _adminService.getPotentialManagers();
      final restaurants = await _adminService.getAvailableRestaurants();
      setState(() {
        _potentialManagers = managers;
        _availableRestaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Future<void> _assignManager(String userId, String restaurantId) async {
    try {
      await _adminService.assignManagerToRestaurant(userId, restaurantId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manager asignado correctamente')),
      );
      _loadData(); // Recargar datos
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar manager: $e')),
      );
    }
  }

  void _showAssignmentDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar ${user['name']} como Manager'),
        content: _availableRestaurants.isEmpty
            ? const Text('No hay restaurantes disponibles para asignar')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Seleccione un restaurante:'),
                  const SizedBox(height: 16),
                  ..._availableRestaurants.map((restaurant) => ListTile(
                        title: Text(restaurant['name']),
                        subtitle: Text(restaurant['location']),
                        onTap: () {
                          Navigator.pop(context);
                          _assignManager(user['id'], restaurant['id']);
                        },
                      )),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignación de Managers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _potentialManagers.isEmpty
              ? const Center(
                  child: Text('No hay usuarios disponibles para asignar como managers'),
                )
              : ListView.builder(
                  itemCount: _potentialManagers.length,
                  itemBuilder: (context, index) {
                    final user = _potentialManagers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user['name'][0].toUpperCase()),
                        ),
                        title: Text(user['name']),
                        subtitle: Text(user['email']),
                        trailing: ElevatedButton(
                          onPressed: _availableRestaurants.isEmpty
                              ? null
                              : () => _showAssignmentDialog(user),
                          child: const Text('Asignar'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 