import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:kokorestaurant/modules/cliente/models/user_profile.dart';

import 'restaurant_menu_simple_screen.dart';
import 'package:flutter/material.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/cliente/models/foodCategory.dart';
import 'package:kokorestaurant/modules/cliente/services/categoriefood_service.dart';
import 'package:kokorestaurant/modules/cliente/services/restaurant_service.dart';
import 'package:kokorestaurant/modules/cliente/widgets/restaurant_special_card.dart';
import 'package:kokorestaurant/theme/app_theme.dart';

class _SpecialRestaurantsStreamBuilder extends StatelessWidget {
  final Stream<List<Restaurant>> stream;
  final String query;
  final Function(Restaurant) navigateToRestaurantMenu;

  const _SpecialRestaurantsStreamBuilder({
    Key? key,
    required this.stream,
    required this.query,
    required this.navigateToRestaurantMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Restaurant>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar restaurantes: ${snapshot.error}',
              style: TextStyle(
                color: AppTheme.errorColor,
              ), // Assuming an error color in your theme
            ),
          );
        }

        final restaurants = snapshot.data ?? [];

        if (restaurants.isEmpty) {
          return _buildEmptyState(context, query);
        }

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: RestaurantSpecialCard(
                  restaurant: restaurant,
                  onTap: () => navigateToRestaurantMenu(restaurant),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String currentQuery) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu, // Example icon
              size: 50,
              color: AppTheme.onSurfaceColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              currentQuery.isEmpty
                  ? 'No hay restaurantes especiales disponibles en este momento.'
                  : 'No se encontraron resultados para "$currentQuery".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceColor, fontSize: 16),
            ),
            if (currentQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Intenta con otra búsqueda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.onSurfaceColor.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
