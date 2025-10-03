// MODIFICADO PARA COINCIDIR CON LA UI DE LA IMAGEN
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/restaurant_service.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'pedidos_screen.dart';

class RestaurantMenuSimpleScreen extends StatefulWidget {
  final Restaurant restaurant;
  final String userId;
  final String restaurantId;

  const RestaurantMenuSimpleScreen({
    Key? key,
    required this.restaurant,
    required this.userId,
    required this.restaurantId,
  }) : super(key: key);

  @override
  _RestaurantMenuSimpleScreenState createState() =>
      _RestaurantMenuSimpleScreenState();
}

class _RestaurantMenuSimpleScreenState
    extends State<RestaurantMenuSimpleScreen> {
  late Future<List<MenuItem>> _menuItemsFuture;
  final RestaurantService _restaurantService = RestaurantService();
  bool _isAdding = false;
  int selectedIndex = 0;
  List<MenuItem> _cartItems = [];

  /// Rutas candidatas para Home. Ajusta si tu home se llama distinto.
  static const List<String> homeRouteCandidates = ['/home', '/'];

  @override
  void initState() {
    super.initState();
    _menuItemsFuture =
        _restaurantService.getMenuRestourant(widget.restaurant.id);
  }

  void onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _addToCart(MenuItem item) async {
    if (_isAdding) return;

    setState(() {
      _isAdding = true;
      _cartItems.add(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFEF5350),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.fastfood, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡${item.name} añadido al pedido!',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isAdding = false);
  }

  /// Navega SIEMPRE a Home, sin importar el navigator.
  Future<void> _goHome() async {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final localNav = Navigator.of(context);

    // 1) Intentar en ROOT con '/home' y luego '/'
    for (final routeName in homeRouteCandidates) {
      try {
        debugPrint('[MenuSimple] goHome -> ROOT pushNamedAndRemoveUntil($routeName)');
        await rootNav.pushNamedAndRemoveUntil(routeName, (route) => false);
        return;
      } catch (e) {
        debugPrint('[MenuSimple] ROOT no tiene $routeName: $e');
      }
    }

    // 2) Intentar en LOCAL con '/home' y luego '/'
    for (final routeName in homeRouteCandidates) {
      try {
        debugPrint('[MenuSimple] goHome -> LOCAL pushNamedAndRemoveUntil($routeName)');
        await localNav.pushNamedAndRemoveUntil(routeName, (route) => false);
        return;
      } catch (e) {
        debugPrint('[MenuSimple] LOCAL no tiene $routeName: $e');
      }
    }

    // 3) Fallback: volver al primer route del ROOT (evita pantalla negra)
    debugPrint('[MenuSimple] Fallback -> ROOT popUntil(isFirst)');
    rootNav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint('[MenuSimple] onWillPop -> goHome');
        await _goHome();
        return false; // manejamos nosotros el back
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildRestaurantHeader()),
            SliverToBoxAdapter(child: _buildPlatosDelLocalHeader()),
            FutureBuilder<List<MenuItem>>(
              future: _menuItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: \${snapshot.error}')),
                  );
                }
                final menuItems = snapshot.data ?? [];
                if (menuItems.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No hay items en el menú.')),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => GestureDetector(
                      onDoubleTap: () => _addToCart(menuItems[index]),
                      child: _buildMenuItemCard(menuItems[index]),
                    ),
                    childCount: menuItems.length,
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _cartItems.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PedidosScreen(
                        pedidos: _cartItems,
                        onUpdate: (nuevosPedidos) {
                          setState(() {
                            _cartItems = nuevosPedidos;
                          });
                        },
                        qrCode: '', // No QR en esta versión
                        restaurantId: widget.restaurantId,
                        userId: widget.userId,
                        restaurant: widget.restaurant,
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          label: Text(
            _cartItems.isEmpty ? 'Pedido' : "Pedido (${_cartItems.length})",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 26,
          color: isSelected ? AppColors.primary : AppColors.boton,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.boton,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 3,
          width: isSelected ? 26 : 0,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantHeader() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: widget.restaurant.imageUrl != null &&
                  widget.restaurant.imageUrl!.isNotEmpty
              ? Image.network(
                  widget.restaurant.imageUrl!,
                  width: double.infinity,
                  height: 210,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.grey,
                        size: 60,
                      ),
                    );
                  },
                )
              : Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.grey,
                    size: 60,
                  ),
                ),
        ),
        // Botón de regreso -> SIEMPRE manda a Home
        Positioned(
          top: 40,
          left: 16,
          child: GestureDetector(
            onTap: () async {
              debugPrint('[MenuSimple] Back tap -> goHome');
              await _goHome();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
        // Card de información
        Positioned(
          top: 120,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary, width: 1.2),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: widget.restaurant.logoUrl != null &&
                              widget.restaurant.logoUrl!.isNotEmpty
                          ? Image.network(
                              widget.restaurant.logoUrl!,
                              width: 62,
                              height: 62,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildDefaultIconBox(),
                            )
                          : _buildDefaultIconBox(),
                    ),
                    if (widget.restaurant.isEspecial == true)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Especial',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.restaurant.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.restaurant.rating}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on, color: Colors.grey, size: 16),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${widget.restaurant.location}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.restaurant.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultIconBox({double size = 60}) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[100],
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 30),
    );
  }

  Widget _buildPlatosDelLocalHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'Platos del Localito',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return InkWell(
      onTap: _isAdding ? null : () => _addToCart(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultIconBox(size: 70);
                      },
                    )
                  : _buildDefaultIconBox(size: 70),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bs ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle, color: AppColors.primary, size: 26),
          ],
        ),
      ),
    );
  }
}
