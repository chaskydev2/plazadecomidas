import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/cliente/models/user_profile.dart';
import 'package:kokorestaurant/modules/cliente/screens/restaurant_list_screen.dart';
import 'package:kokorestaurant/modules/cliente/screens/qr_scanner_screen.dart';
import 'package:kokorestaurant/modules/cliente/screens/history_screen.dart';
import 'package:kokorestaurant/modules/cliente/services/user_service.dart';
import 'package:kokorestaurant/modules/shared/screens/BaseScaffoId.dart'; // Tu nuevo widget aquí

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final UserService _userService = UserService();

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Widget> _screens = const [
    RestaurantListScreen(),
    QRScannerScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _userService.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _userProfile = profile;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No hay usuario autenticado.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el perfil: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text('Error', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return BaseScaffold(
      body: _screens[_selectedIndex],
      selectedIndex: _selectedIndex,
      onTabSelected: (index) => setState(() => _selectedIndex = index),
      userProfile: _userProfile,
      selectedDrawerIndex: 1,
    );
  }
}
