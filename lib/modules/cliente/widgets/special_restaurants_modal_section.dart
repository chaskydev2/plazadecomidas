// special_restaurants_modal.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/modules/cliente/services/restaurant_service.dart';
import 'package:kokorestaurant/theme/app_theme.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';

class SpecialRestaurantsModal extends StatefulWidget {
  final RestaurantService restaurantService;

  const SpecialRestaurantsModal({super.key, required this.restaurantService});

  @override
  State<SpecialRestaurantsModal> createState() =>
      _SpecialRestaurantsModalState();
}

class _SpecialRestaurantsModalState extends State<SpecialRestaurantsModal> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchQuery.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _searchQuery.value = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // --- Header: título + contador + cerrar ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primary.withOpacity(0.30),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Restaurantes Especiales',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Buscador ---
              _SearchField(
                controller: _searchController,
                focusNode: _searchFocus,
                primary: primary,
                onChanged: _onChanged,
                onClear: () {
                  _searchController.clear();
                  _onChanged('');
                  _searchFocus.requestFocus();
                },
                valueListenable: _searchQuery,
              ),
              const SizedBox(height: 14),

              // --- Lista dinámica ---
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, query, _) {
                    final stream =
                        query.isEmpty
                            ? widget.restaurantService.getEspecialRestaurants()
                            : widget.restaurantService
                                .searchEspecialRestaurants(query);

                    return StreamBuilder<List<Restaurant>>(
                      stream: stream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _LoadingState();
                        }
                        if (snapshot.hasError) {
                          return _ErrorState(
                            message: 'No se pudo cargar la lista.',
                            detail: '${snapshot.error}',
                            primary: primary,
                            onRetry: () => setState(() {}),
                          );
                        }

                        final restaurants = snapshot.data ?? [];
                        if (restaurants.isEmpty) {
                          return _EmptyState(
                            query: query,
                            primary: primary,
                            onClear:
                                query.isNotEmpty
                                    ? () {
                                      _searchController.clear();
                                      _onChanged('');
                                    }
                                    : null,
                          );
                        }

                        return Column(
                          children: [
                            // Contador alineado a la derecha
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: ShapeDecoration(
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: primary.withOpacity(0.35),
                                      width: 1,
                                    ),
                                  ),
                                  color: primary.withOpacity(0.10),
                                ),
                                child: Text(
                                  '${restaurants.length} encontrados',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ScrollConfiguration(
                                behavior: const _NoGlowScroll(),
                                child: ListView.separated(
                                  itemCount: restaurants.length,
                                  separatorBuilder:
                                      (_, __) => Divider(
                                        height: 10,
                                        thickness: 0.8,
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                  itemBuilder: (context, index) {
                                    final r = restaurants[index];
                                    return _SpecialTile(
                                      restaurant: r,
                                      primary: primary,
                                      onTap:
                                          () => Navigator.pop(
                                            context,
                                            r,
                                          ), // return
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== Widgets auxiliares ==================

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color primary;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueListenable<String> valueListenable;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.primary,
    required this.onChanged,
    required this.onClear,
    required this.valueListenable,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.18), width: 1),
    );

    return ValueListenableBuilder<String>(
      valueListenable: valueListenable,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: 'Buscar restaurante especial...',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
            suffixIcon:
                value.isNotEmpty
                    ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      splashRadius: 18,
                    )
                    : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: baseBorder,
            enabledBorder: baseBorder,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primary, width: 1.2),
            ),
          ),
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
        );
      },
    );
  }
}

class _SpecialTile extends StatelessWidget {
  final Restaurant restaurant;
  final Color primary;
  final VoidCallback onTap;

  const _SpecialTile({
    required this.restaurant,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg =
        restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Imagen
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  hasImg
                      ? Image.network(
                        restaurant.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return _placeholder(isLoading: true);
                        },
                      )
                      : _placeholder(),
            ),
            const SizedBox(width: 12),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (restaurant.stars != null)
                        _RatingPill(
                          rating: restaurant.stars!.toStringAsFixed(1),
                          primary: primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Botón Ver menú
            _MiniButton(primary: primary, onTap: onTap),
          ],
        ),
      ),
    );
  }

  Widget _placeholder({bool isLoading = false}) {
    return Center(
      child: Icon(
        isLoading ? Icons.downloading_rounded : Icons.restaurant,
        color: Colors.white54,
        size: 26,
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;

  const _MiniButton({required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: primary, width: 1.1),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
      child: const Text(
        'Ver menú',
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final String rating;
  final Color primary;

  const _RatingPill({required this.rating, required this.primary});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, size: 14, color: Colors.yellow),
            const SizedBox(width: 4),
            Text(
              rating,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  final Color primary;
  final VoidCallback? onClear;

  const _EmptyState({required this.query, required this.primary, this.onClear});

  @override
  Widget build(BuildContext context) {
    final isFiltered = query.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 44, color: primary),
          const SizedBox(height: 10),
          Text(
            isFiltered
                ? 'No encontramos resultados'
                : 'No hay restaurantes especiales.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Prueba con otro término o limpia la búsqueda.'
                : 'Cuando se agreguen, aparecerán aquí.',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (isFiltered && onClear != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onClear,
              icon: Icon(Icons.clear_rounded, color: primary),
              label: Text('Limpiar búsqueda', style: TextStyle(color: primary)),
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: primary.withOpacity(0.4)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String detail;
  final Color primary;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.detail,
    required this.primary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: primary),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: primary),
              label: Text('Reintentar', style: TextStyle(color: primary)),
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: primary.withOpacity(0.4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.8,
        color: AppColors.primary,
      ),
    );
  }
}

class _NoGlowScroll extends ScrollBehavior {
  const _NoGlowScroll();
  @override
  Widget buildViewportChrome(
    BuildContext context,
    Widget child,
    AxisDirection axisDirection,
  ) {
    return child;
  }
}
