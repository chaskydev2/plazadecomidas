// lib/modules/cliente/widgets/normal_restaurants_list.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/modules/cliente/services/restaurant_service.dart';
import 'package:kokorestaurant/theme/app_theme.dart';
import 'package:kokorestaurant/modules/cliente/screens/restaurant_menu_simple_screen.dart';

class NormalRestaurantsList extends StatelessWidget {
  final RestaurantService restaurantService;

  /// ValueListenable del texto de búsqueda (el mismo que usas en tu Screen)
  final ValueListenable<String> searchQuery;

  /// ValueListenable que indica si hay búsqueda activa
  final ValueListenable<bool> isSearchActive;

  /// Id de categoría seleccionada ('' o null => todas)
  final String? selectedCategoryId;

  /// Usuario autenticado (para navegar al menú)
  final User user;

  const NormalRestaurantsList({
    super.key,
    required this.restaurantService,
    required this.searchQuery,
    required this.isSearchActive,
    required this.selectedCategoryId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: searchQuery,
      builder: (context, query, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isSearchActive,
          builder: (context, active, __) {
            final Stream<List<Restaurant>> stream = _buildStream(
              service: restaurantService,
              selectedCategoryId: selectedCategoryId,
              query: query,
              isActive: active,
            );

            return StreamBuilder<List<Restaurant>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar los restaurantes: ${snapshot.error}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                final restaurants = snapshot.data ?? [];
                if (restaurants.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No hay restaurantes disponibles.',
                        style: TextStyle(
                          color: AppTheme.onSurfaceColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final r = restaurants[index];
                    return _RestaurantCard(
                      restaurant: r,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RestaurantMenuSimpleScreen(
                                  restaurant: r,
                                  userId: user.uid,
                                  restaurantId: r.id,
                                ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Lógica original de selección de stream, intacta.
  Stream<List<Restaurant>> _buildStream({
    required RestaurantService service,
    required String? selectedCategoryId,
    required String query,
    required bool isActive,
  }) {
    final allCats = selectedCategoryId == null || selectedCategoryId.isEmpty;

    if (allCats && isActive && query.isNotEmpty) {
      return service.searchRestaurants(query);
    } else if (allCats) {
      return service.getRestaurants();
    } else if (isActive && query.isNotEmpty) {
      // Filtrar por categoría y búsqueda (en memoria)
      return service.getRestaurants().map(
        (list) =>
            list
                .where(
                  (r) =>
                      r.idCategoriaFood == selectedCategoryId &&
                      r.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList(),
      );
    } else {
      // Solo categoría
      return service.getRestaurants().map(
        (list) =>
            list.where((r) => r.idCategoriaFood == selectedCategoryId).toList(),
      );
    }
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  String _formatOpenHours(Map<String, String> openHours) {
    if (openHours.containsKey('monday') &&
        (openHours['monday'] ?? '').isNotEmpty) {
      return 'Lun: ${openHours['monday']}';
    } else if (openHours.containsKey('sunday') &&
        (openHours['sunday'] ?? '').isNotEmpty) {
      return 'Dom: ${openHours['sunday']}';
    }
    if (openHours.isEmpty) return 'Horario no disponible';
    return openHours.values.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final rating = restaurant.stars ?? 4.2;
    final subtitle =
        restaurant.description.isNotEmpty
            ? restaurant.description
            : 'Pizza, Snacks, Pasta'; // fallback
    final horario = _formatOpenHours(restaurant.openHours);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 7 / 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: restaurant.imageUrl ?? '',
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 250),
                        placeholder:
                            (c, _) => Container(color: Colors.grey[200]),
                        errorWidget:
                            (c, _, __) => Container(
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                      Container(color: Colors.black.withOpacity(0.18)),
                    ],
                  ),
                ),
                // Badge rojo "Free Delivery"
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Con Delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
                // Rating en rojo
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón corazón
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                      onPressed: () {},
                      splashRadius: 22,
                    ),
                  ),
                ),
              ],
            ),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.black38,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        horario,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
