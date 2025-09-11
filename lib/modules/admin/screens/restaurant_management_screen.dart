import 'package:flutter/material.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/core/services/restaurant_service.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'add_restaurant_screen.dart';

class RestaurantManagementScreen extends StatefulWidget {
  const RestaurantManagementScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantManagementScreen> createState() =>
      _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState
    extends State<RestaurantManagementScreen> {
  final RestaurantService _restaurantService = RestaurantService();

  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  bool _asGrid = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _query.dispose();
    super.dispose();
  }

  // ===== Helpers de UI =====

  String _todayAbbrev() {
    // Mapea Mon..Sun -> Lun..Dom
    const map = {
      DateTime.monday: 'Lun',
      DateTime.tuesday: 'Mar',
      DateTime.wednesday: 'Mié',
      DateTime.thursday: 'Jue',
      DateTime.friday: 'Vie',
      DateTime.saturday: 'Sáb',
      DateTime.sunday: 'Dom',
    };
    return map[DateTime.now().weekday]!;
  }

  int? _parseToMinutes(String s) {
    // Intenta extraer HH:mm desde strings locales como "9:00", "09:00", "9:00 a. m.", etc.
    final reg = RegExp(r'(\d{1,2}):(\d{2})');
    final m = reg.firstMatch(s);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final mm = int.tryParse(m.group(2)!);
    if (h == null || mm == null) return null;

    // Heurística: si el texto trae "p" o "pm" y hora < 12 => suma 12
    final lower = s.toLowerCase();
    var hour = h;
    if ((lower.contains('p. m.') ||
            lower.contains('pm') ||
            lower.contains('p m') ||
            lower.contains('tarde')) &&
        hour < 12) {
      hour += 12;
    }
    // Si contiene "a. m." y hour == 12, poner 0
    if ((lower.contains('a. m.') ||
            lower.contains('am') ||
            lower.contains('a m') ||
            lower.contains('mañana')) &&
        hour == 12) {
      hour = 0;
    }
    return hour * 60 + mm;
  }

  bool _isOpenNow(Restaurant r) {
    try {
      final today = _todayAbbrev();
      if (r.openDays.isEmpty || !r.openDays.contains(today)) return false;

      final openingStr = r.openHours['opening']?.toString() ?? '';
      final closingStr = r.openHours['closing']?.toString() ?? '';
      final openMin = _parseToMinutes(openingStr);
      final closeMin = _parseToMinutes(closingStr);
      if (openMin == null || closeMin == null) return false;

      final now = TimeOfDay.fromDateTime(DateTime.now());
      final nowMin = now.hour * 60 + now.minute;

      if (closeMin > openMin) {
        return nowMin >= openMin && nowMin < closeMin;
      } else {
        // Horario pasando medianoche (ej: 18:00 - 02:00)
        return nowMin >= openMin || nowMin < closeMin;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _showRestaurantDetails(Restaurant restaurant) async {
    final isOpen = _isOpenNow(restaurant);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header con imagen
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child:
                              restaurant.imageUrl != null &&
                                      restaurant.imageUrl!.isNotEmpty
                                  ? Image.network(
                                    restaurant.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) =>
                                            Container(color: Colors.grey[200]),
                                    loadingBuilder: (c, w, p) {
                                      if (p == null) return w;
                                      return Container(color: Colors.grey[200]);
                                    },
                                  )
                                  : Container(color: Colors.grey[200]),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black54],
                              ),
                            ),
                          ),
                        ),
                        if (restaurant.logoUrl != null &&
                            restaurant.logoUrl!.isNotEmpty)
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(
                                  restaurant.logoUrl!,
                                ),
                                onBackgroundImageError: (_, __) {},
                              ),
                            ),
                          ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOpen ? 'Abierto ahora' : 'Cerrado',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _detailTile(
                    Icons.description_outlined,
                    'Descripción',
                    restaurant.description,
                  ),
                  _detailTile(
                    Icons.place_outlined,
                    'Ubicación',
                    restaurant.location,
                  ),
                  _detailTile(
                    Icons.calendar_today_outlined,
                    'Días de atención',
                    restaurant.openDays.join(', '),
                  ),
                  _detailTile(
                    Icons.access_time,
                    'Horario',
                    '${restaurant.openHours['opening']} - ${restaurant.openHours['closing']}',
                  ),
                  _detailTile(
                    Icons.link,
                    'Google Maps',
                    restaurant.googleMapsUrl,
                  ),
                  if (restaurant.managerId != null &&
                      restaurant.managerId!.isNotEmpty)
                    _detailTile(
                      Icons.badge_outlined,
                      'Manager',
                      'ID: ${restaurant.managerId}',
                    ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text('Cerrar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AddRestaurantScreen(
                                        key: ValueKey(restaurant.id),
                                        restaurant: restaurant,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD91010),
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text(
                                        '¿Eliminar Restaurante?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const Text(
                                        '¿Está seguro que desea eliminar este restaurante? Esta acción no se puede deshacer.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                          ),
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirmed == true) {
                                try {
                                  await _restaurantService.deleteRestaurant(
                                    restaurant.id,
                                  );
                                  if (mounted) {
                                    Navigator.pop(
                                      context,
                                    ); // cierra bottom sheet
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Restaurante eliminado exitosamente',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al eliminar restaurante: $e',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.restaurant, size: 42, color: Colors.grey),
      ),
    );
  }

  Widget _statusChip(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isOpen ? Colors.green : Colors.red).withOpacity(.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOpen ? Colors.green : Colors.red,
          width: .6,
        ),
      ),
      child: Text(
        isOpen ? 'Abierto' : 'Cerrado',
        style: TextStyle(
          color: isOpen ? Colors.green[800] : Colors.red[800],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ====== BUILD ======

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Restaurantes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            tooltip: _asGrid ? 'Ver en lista' : 'Ver en grid',
            onPressed: () => setState(() => _asGrid = !_asGrid),
            icon: Icon(
              _asGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => _query.value = v.trim().toLowerCase(),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, ubicación...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRestaurantScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar', style: TextStyle(color: Colors.white)),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: _query,
        builder: (_, q, __) {
          return StreamBuilder<List<Restaurant>>(
            stream: _restaurantService.getRestaurants(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'Ocurrió un error al cargar restaurantes',
                  detail: snapshot.error.toString(),
                );
              }

              if (!snapshot.hasData) {
                return const _LoadingGrid();
              }

              var restaurants = snapshot.data!;
              if (q.isNotEmpty) {
                restaurants =
                    restaurants.where((r) {
                      final n = r.name.toLowerCase();
                      final loc = r.location.toLowerCase();
                      final desc = r.description.toLowerCase();
                      return n.contains(q) ||
                          loc.contains(q) ||
                          desc.contains(q);
                    }).toList();
              }

              if (restaurants.isEmpty) {
                return const _EmptyState(
                  message: 'No se encontraron restaurantes',
                );
              }

              if (_asGrid) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final r = restaurants[index];
                    final isOpen = _isOpenNow(r);
                    return GestureDetector(
                      onTap: () => _showRestaurantDetails(r),
                      child: Card(
                        elevation: 2,
                        color: Colors.white,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Imagen de portada
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child:
                                        r.imageUrl != null &&
                                                r.imageUrl!.isNotEmpty
                                            ? Image.network(
                                              r.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      _buildPlaceholderIcon(),
                                              loadingBuilder: (c, w, p) {
                                                if (p == null) return w;
                                                return _buildPlaceholderIcon();
                                              },
                                            )
                                            : _buildPlaceholderIcon(),
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black54,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (r.logoUrl != null &&
                                      r.logoUrl!.isNotEmpty)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.white,
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundImage: NetworkImage(
                                            r.logoUrl!,
                                          ),
                                          onBackgroundImageError: (_, __) {},
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Info
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          r.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _statusChip(isOpen),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                        size: 20,
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
                  },
                );
              } else {
                // Lista
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: restaurants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final r = restaurants[i];
                    final isOpen = _isOpenNow(r);
                    return Material(
                      color: Colors.white,
                      elevation: 1,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showRestaurantDetails(r),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 92,
                                  height: 72,
                                  child:
                                      r.imageUrl != null &&
                                              r.imageUrl!.isNotEmpty
                                          ? Image.network(
                                            r.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) =>
                                                    _buildPlaceholderIcon(),
                                            loadingBuilder: (c, w, p) {
                                              if (p == null) return w;
                                              return _buildPlaceholderIcon();
                                            },
                                          )
                                          : _buildPlaceholderIcon(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: Colors.grey[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            r.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    _statusChip(isOpen),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}

// ====== Widgets de estado ======

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    // Placeholder simple (sin dependencias)
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.store_mall_directory_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String? detail;
  const _ErrorState({required this.message, this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
                  () =>
                      {}, // El Stream se reintenta solo al reconstruir; puedes setState si quieres.
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
