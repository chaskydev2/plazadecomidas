import 'package:flutter/material.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/cliente/models/user_profile.dart';
import 'package:kokorestaurant/modules/cliente/screens/home_screen.dart';
import 'package:kokorestaurant/modules/cliente/screens/profile_screen.dart';
import 'package:kokorestaurant/modules/cliente/screens/restaurant_list_screen.dart';
import 'package:kokorestaurant/modules/cliente/screens/qr_scanner_screen.dart';
import 'package:kokorestaurant/modules/cliente/screens/settings_screen.dart';
import 'package:kokorestaurant/modules/cliente/screens/history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onTabSelected;
  final UserProfile? userProfile;
  final int selectedDrawerIndex;

  const BaseScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.userProfile,
    required this.selectedDrawerIndex,
  });

  bool get _hasPhoto =>
      (userProfile?.photoUrl != null && userProfile!.photoUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFEECEC), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Builder(
                      builder: (innerContext) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.black87),
                            onPressed: () => Scaffold.of(innerContext).openDrawer(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userProfile?.name ?? "Usuario",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.09),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Avatar derecha AppBar (tu diseño original, pero con fallback robusto)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: _hasPhoto
                            ? ClipOval(
                                child: Image.network(
                                  userProfile!.photoUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 28,
                                  ),
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.grey, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // DRAWER
      drawer: _buildDrawer(context),
      body: body,

      // NAV BAR
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(28),
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.second,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  backgroundColor: AppColors.second,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 0,
                  unselectedFontSize: 0,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  onTap: onTabSelected,
                  items: [
                    BottomNavigationBarItem(
                      icon: _buildNavItem(
                        Icons.restaurant_menu,
                        'Restaurantes',
                        selectedIndex == 0,
                      ),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavItem(
                        Icons.qr_code_scanner,
                        'Escanear',
                        selectedIndex == 1,
                      ),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavItem(
                        Icons.history_toggle_off,
                        'Historial',
                        selectedIndex == 2,
                      ),
                      label: '',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.primary,
        child: Column(
          children: [
            // Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    // ⬇️ Aquí mostramos la foto del usuario (manteniendo tu borde y sombras)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFEECEC), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ClipOval(
                        child: _hasPhoto
                            ? Image.network(
                                userProfile!.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.grey, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Tu pill con inicial (lo mantenemos igual)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        (userProfile?.name != null && userProfile!.name.isNotEmpty)
                            ? userProfile!.name[0].toUpperCase()
                            : 'N',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Card(
                    color: Colors.white.withOpacity(0.10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.home,
                          label: 'Inicio',
                          index: 0,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.person_outline,
                          label: 'Perfil',
                          index: 3,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.settings_outlined,
                          label: 'Ajustes',
                          index: 5,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(
                          color: Colors.white24,
                          height: 1,
                          indent: 10,
                          endIndent: 10,
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'DOCUMENTACIÓN',
                            style: TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(180, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              shadowColor: AppColors.primary.withOpacity(0.15),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Cerrar sesión',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil('/', (route) => false);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int index,
    Color iconColor = Colors.white70,
  }) {
    final bool isSelected = selectedDrawerIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.white70,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.white70,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          onTap: onTap,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          tileColor: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        ),
      ),
    );
  }
}
