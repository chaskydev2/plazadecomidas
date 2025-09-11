import 'package:flutter/material.dart';
import 'package:kokorestaurant/modules/admin/services/admin_service.dart';
import 'package:kokorestaurant/modules/admin/services/branch_service.dart';

class EmployeesScreen extends StatefulWidget {
  final String restaurantId;
  const EmployeesScreen({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final AdminService _adminService = AdminService();
  final BranchService _branchService = BranchService();

  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _name = '';
  String _role = 'employee';
  String? _selectedUserId;
  String? _selectedSucursal; // <-- branchId seleccionado al crear

  bool _loading = false;
  String? _error;
  bool _showCreateDialog = false;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _sucursales = []; // {id, nombre, ...}

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadSucursales();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _adminService.getUsers(
        restaurantId: widget.restaurantId,
      );
      if (!mounted) return;
      setState(() {
        _users =
            users
                .where(
                  (u) => (u['role'] == 'employee' || u['role'] == 'manager'),
                )
                .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar usuarios: $e')));
    }
  }

  Future<void> _loadSucursales() async {
    try {
      final sucs = await _branchService.getBranchesWithRestaurant(
        widget.restaurantId,
      );
      if (!mounted) return;
      setState(() {
        _sucursales =
            sucs; // cada item trae al menos {id, nombre, direccion, restaurantId}
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar sucursales: $e')));
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSucursal == null) {
      setState(() => _error = 'Selecciona una sucursal.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _adminService.createUser(
        email: _email,
        password: _password,
        name: _name,
        role: _role,
        restaurantId: widget.restaurantId,
        branchId: _selectedSucursal,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empleado creado correctamente')),
      );

      _formKey.currentState!.reset();
      _email = '';
      _password = '';
      _name = '';
      _role = 'employee';
      _selectedSucursal = null;

      setState(() {
        _showCreateDialog = false;
      });

      await _loadUsers();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openCreateDialog() {
    setState(() {
      _showCreateDialog = true;
      _error = null;
      _email = '';
      _password = '';
      _name = '';
      _role = 'employee';
      _selectedSucursal = null;
    });

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Crear nuevo empleado'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        onChanged: (v) => setStateDialog(() => _name = v),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Ingrese un nombre'
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => setStateDialog(() => _email = v),
                        validator:
                            (v) =>
                                v == null || !v.contains('@')
                                    ? 'Correo inválido'
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                        obscureText: true,
                        onChanged: (v) => setStateDialog(() => _password = v),
                        validator:
                            (v) =>
                                v == null || v.length < 6
                                    ? 'Mínimo 6 caracteres'
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _role,
                        items: const [
                          DropdownMenuItem(
                            value: 'employee',
                            child: Text('Empleado'),
                          ),
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Manager'),
                          ),
                        ],
                        onChanged:
                            (v) => setStateDialog(() {
                              if (v != null) _role = v;
                            }),
                        decoration: const InputDecoration(labelText: 'Rol'),
                      ),
                      const SizedBox(height: 8),
                      // --- Selección de Sucursal (branch) ---
                      DropdownButtonFormField<String>(
                        value: _selectedSucursal,
                        items:
                            _sucursales
                                .map<DropdownMenuItem<String>>(
                                  (s) => DropdownMenuItem<String>(
                                    value: s['id'] as String,
                                    child: Text(
                                      (s['nombre'] ?? s['name'] ?? s['id'])
                                          .toString(),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setStateDialog(() => _selectedSucursal = v),
                        validator:
                            (v) => v == null ? 'Selecciona una sucursal' : null,
                        decoration: const InputDecoration(
                          labelText: 'Sucursal',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() => _showCreateDialog = false);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              await _createUser();
                              if (Navigator.of(ctx).canPop()) {
                                Navigator.of(ctx).pop();
                              }
                            }
                          },
                  child:
                      _loading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Crear empleado'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _adminService.updateUserRole(userId, newRole);
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar rol: $e')));
    }
  }

  Future<void> _assignSucursal(String userId, String sucursalId) async {
    try {
      await _adminService.assignUserToBranch(
        userId: userId,
        restaurantId: widget.restaurantId,
        branchId: sucursalId,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sucursal asignada')));
      }
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al asignar sucursal: $e')));
    }
  }

  void _showEditDialog(Map<String, dynamic> user) {
    String editName = user['name'] ?? '';
    String editRole = user['role'] ?? 'employee';
    String? editSucursal = user['branchId']; // <-- usamos branchId

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Editar empleado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: editName,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onChanged: (v) => editName = v,
                ),
                DropdownButtonFormField<String>(
                  value: editRole,
                  items: const [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text('Empleado'),
                    ),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  ],
                  onChanged: (v) => editRole = v ?? 'employee',
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                DropdownButtonFormField<String>(
                  value: editSucursal,
                  items:
                      _sucursales
                          .map<DropdownMenuItem<String>>(
                            (s) => DropdownMenuItem<String>(
                              value: s['id'] as String,
                              child: Text(
                                (s['nombre'] ?? s['name'] ?? s['id'])
                                    .toString(),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => editSucursal = v,
                  decoration: const InputDecoration(labelText: 'Sucursal'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _adminService.updateUser(user['id'], {
                      'name': editName,
                      'role': editRole,
                      'restaurantId': widget.restaurantId,
                      'branchId': editSucursal,
                    });
                    if (mounted) Navigator.of(ctx).pop();
                    await _loadUsers();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar: $e')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empleados')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lista de empleados',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo'),
                    onPressed: _openCreateDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._users.map(
                (user) => Card(
                  child: ListTile(
                    title: Text(user['name'] ?? ''),
                    subtitle: Text('${user['email']} • ${user['role']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDialog(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: const Text('Eliminar empleado'),
                                    content: const Text(
                                      '¿Seguro que deseas eliminar este empleado?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              await _deleteUser(user['id']);
                            }
                          },
                        ),
                      ],
                    ),
                    // Asignar sucursal rápido con un tap
                    onTap: () async {
                      final selected = await showDialog<String>(
                        context: context,
                        builder:
                            (ctx) => SimpleDialog(
                              title: const Text('Asignar sucursal'),
                              children:
                                  _sucursales
                                      .map(
                                        (s) => SimpleDialogOption(
                                          onPressed:
                                              () => Navigator.of(
                                                ctx,
                                              ).pop(s['id']),
                                          child: Text(
                                            (s['nombre'] ??
                                                    s['name'] ??
                                                    s['id'])
                                                .toString(),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                      );
                      if (selected != null) {
                        await _assignSucursal(user['id'], selected);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
