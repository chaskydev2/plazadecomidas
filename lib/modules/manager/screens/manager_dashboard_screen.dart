import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kokorestaurant/modules/manager/screens/menu_management_screen.dart';
import 'package:kokorestaurant/modules/manager/screens/tables_management_screen.dart';
import 'package:kokorestaurant/modules/manager/screens/income_screen.dart';
import 'package:kokorestaurant/modules/manager/screens/manager_profile_screen.dart';
import 'package:kokorestaurant/modules/manager/screens/manager_settings_screen.dart';
import 'package:kokorestaurant/modules/manager/screens/pedidos_manager_screen.dart';
import 'package:kokorestaurant/modules/manager/screens/employees_screen.dart';
import 'package:kokorestaurant/modules/manager/screens/payment_qr_management_screen.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final String restaurantId;

  const ManagerDashboardScreen({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  _ManagerDashboardScreenState createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ===== APP BAR con estilo copiado del BaseScaffold =====
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Botón de menú que SÍ abre el Drawer (usa Builder)
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
                            onPressed:
                                () => Scaffold.of(innerContext).openDrawer(),
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
                            _getHeaderSubtitle(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Panel Manager',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Avatar con borde y sombra como en BaseScaffold
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
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.grey, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // ===== DRAWER con estética del BaseScaffold =====
      drawer: _buildDrawer(context),

      // ===== BODY =====
      body: _buildBody(),

      // ===== BOTTOM NAV con estética del BaseScaffold =====
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
                  currentIndex: _selectedIndex,
                  backgroundColor: AppColors.second,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 0,
                  unselectedFontSize: 0,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  items: [
                    BottomNavigationBarItem(
                      icon: _buildNavItem(
                        Icons.restaurant_menu,
                        'Menú',
                        _selectedIndex == 0,
                      ),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavItem(
                        Icons.table_bar,
                        'Mesas',
                        _selectedIndex == 1,
                      ),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavItem(
                        Icons.shopping_cart,
                        'Pedidos',
                        _selectedIndex == 2,
                      ),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavItem(
                        Icons.attach_money,
                        'Ingresos',
                        _selectedIndex == 3,
                      ),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavItem(
                        Icons.group,
                        'Empleados',
                        _selectedIndex == 4,
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

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            isSelected
                ? AppColors.primary.withOpacity(0.12)
                : Colors.transparent,
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

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.primary,
        child: Column(
          children: [
            // Header superior estilo BaseScaffold
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
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
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_menu,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                      child: const Text(
                        'M',
                        style: TextStyle(
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

            // Lista con “tarjeta” como en BaseScaffold
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
                          icon: Icons.settings_outlined,
                          label: 'Ajustes',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ManagerSettingsScreen(
                                      restaurantId: widget.restaurantId,
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.qr_code,
                          label: 'Mi QR de pagos',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PaymentQRManagementScreen(
                                      restaurantId: widget.restaurantId,
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.person_outline,
                          label: 'Mi perfil',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ManagerProfileScreen(
                                      restaurantId: widget.restaurantId,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Separador + botón Cerrar sesión con estilo BaseScaffold
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
                              // Cierra sesión y navega a raíz (misma UX que BaseScaffold)
                              await FirebaseAuth.instance.signOut();
                              if (!mounted) return;
                              Navigator.of(
                                context,
                              ).pushNamedAndRemoveUntil('/', (route) => false);
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

  // Ítem estilizado del Drawer (similar al BaseScaffold)
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          onTap: onTap,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          tileColor: Colors.white.withOpacity(0.15),
        ),
      ),
    );
  }

  String _getHeaderSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Gestión del Menú';
      case 1:
        return 'Gestión de Mesas';
      case 2:
        return 'Pedidos';
      case 3:
        return 'Ingresos';
      default:
        return 'Panel Manager';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return MenuManagementScreen(restaurantId: widget.restaurantId);
      case 1:
        return TablesManagementScreen(restaurantId: widget.restaurantId);
      case 2:
        return PedidosManagerScreen(restaurantId: widget.restaurantId);
      case 3:
        return IncomeScreen(restaurantId: widget.restaurantId);
      case 4:
        return EmployeesScreen(restaurantId: widget.restaurantId);
      default:
        return MenuManagementScreen(restaurantId: widget.restaurantId);
    }
  }
}
