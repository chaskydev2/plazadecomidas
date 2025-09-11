import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/core/services/restaurant_service.dart';
// Opcional: descomenta si usarás acciones de email/teléfono
// import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // Para Clipboard

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  Restaurant? _managerRestaurant;
  bool _isLoading = true;
  String? _error;

  // ==== CONFIG DE MARCA ====
  static const Color kBrand = Color(0xFFD91010);
  static const _headerHeight = 220.0;

  @override
  void initState() {
    super.initState();
    final role = widget.userData['role']?.toString().toLowerCase();
    if (role == 'manager') {
      _loadManagerRestaurant();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadManagerRestaurant() async {
    try {
      final restaurantId = widget.userData['restaurantId']?.toString();
      if (restaurantId != null && restaurantId.isNotEmpty) {
        final restaurant = await _restaurantService.getRestaurantById(
          restaurantId,
        );
        if (!mounted) return;
        setState(() {
          _managerRestaurant = restaurant;
          _isLoading = false;
          _error = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar restaurante del manager: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'No se pudo cargar la info del restaurante.';
      });
    }
  }

  // ==== HELPERS UI ====
  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFD91010);
      case 'manager':
        return const Color(0xFF2563EB); // blue-600
      case 'client':
        return const Color(0xFF16A34A); // green-600
      default:
        return Colors.grey;
    }
  }

  String _roleText(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Gerente';
      case 'client':
        return 'Cliente';
      default:
        return role;
    }
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final d = date.toDate();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yyyy = d.year.toString();
      return '$dd/$mm/$yyyy';
    }
    return 'Fecha no disponible';
  }

  Future<void> _copy(String text, {String label = 'Copiado'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Opcional: acciones rápidas (requiere url_launcher)
  // Future<void> _launchEmail(String email) async {
  //   final uri = Uri(scheme: 'mailto', path: email);
  //   if (await canLaunchUrl(uri)) await launchUrl(uri);
  // }
  // Future<void> _launchPhone(String phone) async {
  //   final uri = Uri(scheme: 'tel', path: phone);
  //   if (await canLaunchUrl(uri)) await launchUrl(uri);
  // }

  @override
  Widget build(BuildContext context) {
    final role = widget.userData['role']?.toString().toLowerCase() ?? '';
    final name = (widget.userData['name']?.toString() ?? 'Usuario').trim();
    final email = widget.userData['email']?.toString();
    final phone = widget.userData['phone']?.toString();
    final createdAt = widget.userData['createdAt'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Perfil de Usuario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBrand,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        color: kBrand,
        onRefresh: () async {
          if (role == 'manager') {
            setState(() => _isLoading = true);
            await _loadManagerRestaurant();
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                height: _headerHeight,
                avatarLetter: (name.isNotEmpty ? name[0] : 'U').toUpperCase(),
                name: name,
                role: _roleText(role),
                roleColor: _roleColor(role),
                brand: kBrand,
                createdAtText: _formatDate(createdAt),
              ),
            ),
            // Información del usuario
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SectionCard(
                  title: 'Información del Usuario',
                  children: [
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Correo',
                      value: email ?? 'No disponible',
                      onCopy:
                          email != null
                              ? () => _copy(email, label: 'Correo copiado')
                              : null,
                      // onTap: email != null ? () => _launchEmail(email) : null,
                    ),
                    if (phone != null && phone.isNotEmpty)
                      _InfoTile(
                        icon: Icons.phone_android_outlined,
                        label: 'Teléfono',
                        value: phone,
                        onCopy: () => _copy(phone, label: 'Teléfono copiado'),
                        // onTap: () => _launchPhone(phone),
                      ),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Fecha de Registro',
                      value: _formatDate(createdAt),
                    ),
                  ],
                ),
              ),
            ),

            // Estado de carga / error / restaurante del manager
            if (role == 'manager') ...[
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: const _Shimmer(height: 120),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: _SectionCard(
                      title: 'Información del Restaurante',
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_managerRestaurant != null)
                          _ManagerRestaurantTile(
                            restaurant: _managerRestaurant!,
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No hay información del restaurante disponible',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

/// =================== WIDGETS PRIVADOS ===================

class _Header extends StatelessWidget {
  const _Header({
    required this.height,
    required this.avatarLetter,
    required this.name,
    required this.role,
    required this.roleColor,
    required this.brand,
    required this.createdAtText,
  });

  final double height;
  final String avatarLetter;
  final String name;
  final String role;
  final Color roleColor;
  final Color brand;
  final String createdAtText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand, brand.withOpacity(.85)],
        ),
        boxShadow: [
          BoxShadow(
            color: brand.withOpacity(.25),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoración suave
          Positioned(
            top: -30,
            right: -20,
            child: _Bubble(size: 140, opacity: .15),
          ),
          Positioned(
            bottom: -20,
            left: -10,
            child: _Bubble(size: 120, opacity: .10),
          ),

          // Contenido
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _AvatarRing(letter: avatarLetter, ringColor: roleColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.white.withOpacity(.95),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  role,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Opacity(
                            opacity: .95,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Miembro desde $createdAtText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.letter, required this.ringColor});
  final String letter;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [ringColor, ringColor.withOpacity(.5)],
        ),
      ),
      child: CircleAvatar(
        radius: 44,
        backgroundColor: Colors.white.withOpacity(.95),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: ringColor,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.grey.shade600;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: muted, fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onCopy != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: onCopy,
                tooltip: 'Copiar',
              ),
          ],
        ),
      ),
    );
  }
}

class _ManagerRestaurantTile extends StatelessWidget {
  const _ManagerRestaurantTile({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.grey.shade600;

    // Intentamos obtener campos frecuentes; caemos a vacíos si no existen
    final name = (restaurant.name).toString();
    final location =
        (tryGet(restaurant, 'location') ?? 'Ubicación no disponible')
            .toString();
    final description = (tryGet(restaurant, 'description') ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(Icons.restaurant, size: 28),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 16, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(color: muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          // TODO: navegar a detalle del restaurante si existe esa pantalla
          // Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: restaurant)));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Abrir detalle del restaurante (implementa la navegación)',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  /// Intenta leer un campo opcional del modelo usando `toString()` como fallback.
  /// Evita errores si el modelo no expone getters para ciertos campos.
  static dynamic tryGet(Object obj, String field) {
    try {
      final map = (obj as dynamic).toJson?.call();
      if (map is Map && map.containsKey(field)) return map[field];
    } catch (_) {}
    try {
      return (obj as dynamic)?.$field;
    } catch (_) {}
    return null;
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({this.height = 100, this.borderRadius = 14});
  final double height;
  final double borderRadius;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final percent = _controller.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            height: widget.height,
            decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment(-1.0 + 2 * percent, 0),
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFFF3F4F6).withOpacity(.0),
                            const Color(0xFFFFFFFF).withOpacity(.7),
                            const Color(0xFFF3F4F6).withOpacity(.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
