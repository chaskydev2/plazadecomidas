import 'package:flutter/material.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import '../../cliente/models/menu_item.dart' as client_models;
import '../services/menu_service.dart';
import 'menu_item_form_screen.dart';
import 'menu_item_detail_screen.dart';

class MenuManagementScreen extends StatefulWidget {
  final String restaurantId;

  const MenuManagementScreen({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final MenuService _menuService = MenuService();
  bool _isLoading = true;
  List<client_models.MenuItem> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _menuService.getMenuItems(widget.restaurantId).first;
      if (mounted) {
        setState(() {
          _menuItems = List<client_models.MenuItem>.from(items);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los platos: $e')),
        );
      }
    }
  }

  Future<void> _deleteMenuItem(client_models.MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quitar del menú'),
            content: const Text(
              '¿Estás seguro de que deseas quitar este producto del menú? Esta acción es común si el plato ya no está disponible o si deseas renovar la carta.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _menuService.deleteMenuItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plato eliminado correctamente'),
              backgroundColor: AppColors.primary,
            ),
          );
          await _loadMenuItems();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    }
  }

  void _navigateToAddItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MenuItemFormScreen(restaurantId: widget.restaurantId),
      ),
    ).then((_) => _loadMenuItems());
  }

  void _navigateToItemDetail(client_models.MenuItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MenuItemDetailScreen(item: item)),
    );
  }

  Future<void> _navigateToEditItem(client_models.MenuItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MenuItemFormScreen(
              restaurantId: widget.restaurantId,
              item: item,
            ),
      ),
    );
    if (mounted) {
      await _loadMenuItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildMenuItemsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddItem,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Plato',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMenuItemsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD91010)),
      );
    }

    if (_menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay platos en el menú',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _navigateToAddItem,
              child: const Text(
                'Agregar primer plato',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    item.imageUrl.isNotEmpty
                        ? Image.network(
                          item.imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  _buildDefaultIconBox(),
                        )
                        : _buildDefaultIconBox(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bs ${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEditItem(item);
                  } else if (value == 'delete') {
                    _deleteMenuItem(item);
                  }
                },
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.edit_outlined,
                            color: Colors.grey[700],
                            size: 22,
                          ),
                          title: Text(
                            'Editar',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.grey[700],
                            size: 22,
                          ),
                          title: Text(
                            'Eliminar',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultIconBox({double size = 70}) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[100],
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 30),
    );
  }
}
