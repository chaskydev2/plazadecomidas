// MODIFICACIÓN VISUAL DEL MENU ORIGINAL PARA QUE SE PAREZCA A LA VERSIÓN SIMPLE Y ESTÉTICA

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/modules/manager/models/table.dart';
import '../models/menu_item.dart';
import '../services/qr_service.dart';
import 'pedidos_screen.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String qrCode;

  const RestaurantMenuScreen({super.key, required this.qrCode});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final QRService _qrService = QRService();
  RestaurantTable? _table;
  String? _restaurantName;
  Restaurant? _restaurant;
  bool _isLoading = true;
  List<MenuItem>? _menuItems;
  List<MenuItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      setState(() => _isLoading = true);
      final table = await _qrService.validateQR(widget.qrCode);
      if (table == null)
        throw Exception('Código QR inválido o mesa no encontrada');
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(table.restaurantId)
          .collection('tables')
          .doc(table.id)
          .update({'isOccupied': true});
      setState(() => _table = table.copyWith(isOccupied: true));

      // Obtener el documento del restaurante y guardarlo como objeto Restaurant
      final doc =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(table.restaurantId)
              .get();
      if (doc.exists) {
        setState(() {
          _restaurantName = doc.data()?['name'] ?? 'Restaurante';
          _restaurant = Restaurant.fromFirestore(doc);
        });
      }

      await _loadMenuItems();
    } catch (e) {
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMenuItems() async {
    if (_table == null) return;
    final items = await _qrService.getMenuForTable(
      _table!.id,
      _table!.restaurantId,
    );
    setState(() => _menuItems = items);
  }

  Future<void> _loadRestaurantName() async {
    if (_table == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(_table!.restaurantId)
            .get();
    setState(() => _restaurantName = doc.data()?['name'] ?? 'Restaurante');
  }

  void _addToCart(MenuItem item) async {
    setState(() => _cartItems.add(item));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.fastfood, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Se añadió ${item.name} al pedido',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReleaseTableDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Desocupar mesa'),
            content: const Text(
              '¿Estás seguro de que deseas desocupar la mesa?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Desocupar'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        await _qrService.releaseTable(_table!);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al desocupar la mesa: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Colors.grey,
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: _showReleaseTableDialog,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.logout, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _restaurantName ?? 'Restaurante',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Platos del Local',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return InkWell(
      onTap: () => _addToCart(item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.price.toStringAsFixed(2)} Bs.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  if (_menuItems == null)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_menuItems!.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('No hay productos disponibles.'),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildMenuItemCard(_menuItems![index]),
                        childCount: _menuItems!.length,
                      ),
                    ),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _cartItems.isEmpty || _restaurant == null
                ? null
                : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PedidosScreen(
                            pedidos: _cartItems,
                            onUpdate:
                                (nuevos) => setState(() => _cartItems = nuevos),
                            qrCode: widget.qrCode,
                            restaurantId: _table!.restaurantId,
                            userId: 'user_temp',
                            restaurant: _restaurant!,
                          ),
                    ),
                  );
                },
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        label: Text(
          _cartItems.isEmpty ? 'Pedido' : 'Pedido (${_cartItems.length})',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
