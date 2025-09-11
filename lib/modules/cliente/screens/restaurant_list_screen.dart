import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:kokorestaurant/modules/cliente/models/user_profile.dart';
import 'package:kokorestaurant/modules/cliente/widgets/normal_restaurants_list.dart';
import 'package:kokorestaurant/modules/cliente/widgets/normal_restaurants_modal.dart';
import 'package:kokorestaurant/modules/cliente/widgets/special_restaurants_modal_section.dart';

import 'restaurant_menu_simple_screen.dart';
import 'package:flutter/material.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/cliente/models/foodCategory.dart';
import 'package:kokorestaurant/modules/cliente/services/categoriefood_service.dart';
import 'package:kokorestaurant/modules/cliente/services/restaurant_service.dart';
import 'package:kokorestaurant/modules/cliente/widgets/restaurant_special_card.dart';
import 'package:kokorestaurant/modules/cliente/widgets/special_restaurants_modal_list.dart';
import 'package:kokorestaurant/theme/app_theme.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final CategorieFoodService _categorieFoodService = CategorieFoodService();
  final user = FirebaseAuth.instance.currentUser;

  int _selectedCategoryIndex = 0;
  bool _isSearching = false;

  final ValueNotifier<bool> _isSearchActive = ValueNotifier<bool>(false);
  // Index for selected category (e.g., Pizza is 2 in mock data)

  // --- Categorías dinámicas desde Firestore ---
  // Elimina el array fijo y usa un stream de FoodCategory
  // ...

  // ...existing code...
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  // ...existing code...// --- Mock Data for Special Restaurants (Hardcoded as per constraint) ---
  final _searchDebouncer = Debouncer(milliseconds: 500);

  String _getSaludoPorHora() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) {
      return '¡Buenos Días!';
    } else if (hora >= 12 && hora < 19) {
      return '¡Buenas Tardes!';
    } else {
      return '¡Buenas Noches!';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miércoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return '';
    }
  }

  DateTime _parseTime(String time, DateTime baseDate) {
    final parts = time.split(':');
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _selectedCategoryIndex = 2;

    // Ejecutar normalización una sola vez
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchQuery.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _searchQuery.value = '';
      _isSearchActive.value = false;
      return;
    }

    _isSearchActive.value = true;
    _searchDebouncer.run(() {
      _searchQuery.value = query;
    });
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEECEC), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar comida o restaurante...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                prefixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.search,
                    key: ValueKey(_searchController.text.isEmpty),
                    color:
                        _searchController.text.isEmpty
                            ? Colors.grey[500]
                            : AppColors.primary,
                    size: 24,
                  ),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                          splashRadius: 18,
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 20,
                ),
              ),
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              cursorColor: AppColors.primary,
            ),
          ),
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _selectedCategoryId;

  Widget _buildSpecialRestaurants() {
    return ValueListenableBuilder<String>(
      valueListenable: _searchQuery,
      builder: (context, query, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isSearchActive,
          builder: (context, isActive, _) {
            Stream<List<Restaurant>> stream;
            // Si la categoría es "Todas" (id == ''), no filtrar por categoría
            if ((_selectedCategoryId == null || _selectedCategoryId == '') &&
                isActive &&
                query.isNotEmpty) {
              stream = _restaurantService.searchEspecialRestaurants(query);
            } else if ((_selectedCategoryId == null ||
                _selectedCategoryId == '')) {
              stream = _restaurantService.getEspecialRestaurants();
            } else if (isActive && query.isNotEmpty) {
              // ⬇️ Antes llamabas a searchEspecialRestaurantsByCategoryAndName(...) y pedía índice
              //    Ahora: busca por query y luego filtra por categoría en memoria (sin índice compuesto)
              stream = _restaurantService
                  .searchEspecialRestaurants(query)
                  .map(
                    (list) =>
                        list
                            .where(
                              (r) => r.idCategoriaFood == _selectedCategoryId,
                            )
                            .toList(),
                  );
            } else {
              stream = _restaurantService.getEspecialRestaurants().map(
                (list) =>
                    list
                        .where((r) => r.idCategoriaFood == _selectedCategoryId)
                        .toList(),
              );
            }

            return StreamBuilder<List<Restaurant>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final restaurants = snapshot.data ?? [];

                if (restaurants.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        query.isEmpty
                            ? 'No hay restaurantes especiales'
                            : 'No se encontraron resultados para "$query"',
                        style: TextStyle(color: AppTheme.onSurfaceColor),
                      ),
                    ),
                  );
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
                          onTap: () => _navigateToRestaurantMenu(restaurant),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _navigateToRestaurantMenu(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RestaurantMenuSimpleScreen(
              restaurant: restaurant,
              userId: user!.uid,
              restaurantId: restaurant.id,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  _getSaludoPorHora(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                _buildSearchField(),
              ],
            ),
          ),
        ),
        // Categorías desde Firestore
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 5),
            child: SizedBox(
              height: 100,
              child: StreamBuilder<List<FoodCategory>>(
                stream: _categorieFoodService.getCategoryFood(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \${snapshot.error}'));
                  }

                  final datos = snapshot.data ?? [];

                  // Insert 'Todas' category at the start
                  final todasCategory = FoodCategory(
                    id: '',
                    category: 'Todas',
                    imageUrl:
                        'assets/images/koko-logo.png', // Usa tu logo o un ícono genérico
                    description: '',
                  );
                  final categories = [todasCategory, ...?snapshot.data];
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final bool isSelected = _selectedCategoryIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                            _selectedCategoryId = category.id;
                          });
                          print('Categoría seleccionada: ${category.id}');
                          _searchDebouncer.run(() {
                            _searchQuery.value = _searchController.text.trim();
                            _isSearchActive.value =
                                _searchController.text.trim().isNotEmpty;
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    category.imageUrl.startsWith('http')
                                        ? Image.network(
                                          category.imageUrl,
                                          height: 40,
                                          width: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.fastfood,
                                                    size: 40,
                                                    color:
                                                        isSelected
                                                            ? AppTheme
                                                                .primaryColor
                                                            : Colors.grey[700],
                                                  ),
                                        )
                                        : Image.asset(
                                          category.imageUrl,
                                          height: 40,
                                          width: 40,
                                          color:
                                              isSelected
                                                  ? AppTheme.primaryColor
                                                  : Colors.grey[700],
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.fastfood,
                                                    size: 40,
                                                    color:
                                                        isSelected
                                                            ? AppTheme
                                                                .primaryColor
                                                            : Colors.grey[700],
                                                  ),
                                        ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        // Aquí continuarían los SliverToBoxAdapter de restaurantes especiales y comunes
        // sin necesidad de modificar esa parte si ya está bien estructurada.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Restaurantes Especiales',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      isScrollControlled: true,
                      builder:
                          (context) => SpecialRestaurantsModal(
                            restaurantService: _restaurantService,
                          ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Ver Todo',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // --- Restaurantes Especiales desde Firestore ---
        SliverToBoxAdapter(child: _buildSpecialRestaurants()),
        // Restaurantes (Main List)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Restaurantes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      isScrollControlled: true,
                      builder:
                          (context) => NormalRestaurantsModal(
                            restaurantService: _restaurantService,
                          ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Ver Todo',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Main restaurant list
        SliverToBoxAdapter(
          child: NormalRestaurantsList(
            restaurantService: _restaurantService,
            searchQuery: _searchQuery,
            isSearchActive: _isSearchActive,
            selectedCategoryId: _selectedCategoryId,
            user: user!, // ya lo tienes arriba
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
