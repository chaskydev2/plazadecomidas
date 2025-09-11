import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/cliente/services/restaurant_service.dart';
import 'package:kokorestaurant/modules/cliente/widgets/restaurant_special_card.dart';

class SpecialRestaurantsModalList extends StatefulWidget {
  final RestaurantService restaurantService;
  const SpecialRestaurantsModalList({Key? key, required this.restaurantService})
    : super(key: key);

  @override
  State<SpecialRestaurantsModalList> createState() =>
      _SpecialRestaurantsModalListState();
}

class _SpecialRestaurantsModalListState
    extends State<SpecialRestaurantsModalList> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    final Stream<List<Restaurant>> stream =
        _searchQuery.isEmpty
            ? widget.restaurantService.getEspecialRestaurants()
            : widget.restaurantService.searchEspecialRestaurants(_searchQuery);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Header ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primary.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Restaurantes especiales',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Buscador ---
          _SearchField(
            controller: _searchController,
            focusNode: _focusNode,
            primary: primary,
            onChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              _onSearchChanged('');
              _focusNode.requestFocus();
            },
          ),
          const SizedBox(height: 14),

          // --- Lista ---
          SizedBox(
            height: 340,
            child: StreamBuilder<List<Restaurant>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                    query: _searchQuery,
                    primary: primary,
                    onClear:
                        _searchQuery.isNotEmpty
                            ? () {
                              _searchController.clear();
                              _onSearchChanged('');
                            }
                            : null,
                  );
                }

                return ScrollConfiguration(
                  behavior: const _NoGlowScroll(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 6),
                    itemCount: restaurants.length,
                    separatorBuilder:
                        (_, __) => Divider(
                          height: 10,
                          thickness: 0.8,
                          color: Colors.white.withOpacity(0.06),
                        ),
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return RestaurantSpecialCard(
                        restaurant: restaurant,
                        onTap: () {
                          Navigator.pop(context);
                          // Navega al detalle si deseas
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // --- Footer contador ---
          const SizedBox(height: 6),
          StreamBuilder<List<Restaurant>>(
            stream: stream,
            builder: (context, snapshot) {
              final count = (snapshot.data ?? []).length;
              return Align(
                alignment: Alignment.centerRight,
                child: Container(
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
                    '$count encontrados',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// === Widgets auxiliares estilizados ===

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color primary;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.primary,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.18), width: 1),
    );

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
            controller.text.isNotEmpty
                ? IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, color: Colors.white70),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.2),
        ),
      ),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
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
          Icon(Icons.inbox_rounded, size: 42, color: primary),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'No encontramos resultados'
                : 'No hay restaurantes especiales.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
            const SizedBox(height: 10),
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
            Icon(Icons.error_outline_rounded, size: 42, color: primary),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
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
            const SizedBox(height: 10),
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
    // Carga simple con color primario
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
