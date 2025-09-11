import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';
import 'package:kokorestaurant/modules/manager/screens/manager_dashboard_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('last_email') ?? '';
      _passwordController.text = prefs.getString('last_password') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? true;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('last_email', _emailController.text);
      await prefs.setString('last_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('last_email');
      await prefs.remove('last_password');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _saveCredentials();
        final user = await _authService.signIn(
          _emailController.text,
          _passwordController.text,
          context,
        );
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error inesperado: usuario no encontrado.'),
                backgroundColor: Color(0xFFD91010),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        final snapshot =
            await _firestore.collection('users').doc(user.uid).get();
        final role = snapshot.data()?['role'] ?? 'client';
        final restaurantId = snapshot.data()?['restaurantId'];

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          if (role == 'admin') {
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushReplacementNamed('/admin');
          } else if (role == 'manager') {
            if (restaurantId != null && restaurantId.toString().isNotEmpty) {
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (_) => ManagerDashboardScreen(restaurantId: restaurantId),
                ),
              );
            } else {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushReplacementNamed('/client');
            }
          } else {
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushReplacementNamed('/client');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _getErrorMessage(e),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFD91010),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No existe una cuenta con este correo electrónico';
        case 'wrong-password':
          return 'Contraseña incorrecta. Intenta nuevamente';
        case 'invalid-email':
          return 'El formato del correo electrónico es inválido';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Intenta más tarde';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu internet';
        case 'operation-not-allowed':
          return 'Inicio con email y contraseña no habilitado';
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos';
        default:
          if (error.code.contains('credential') ||
              error.code.contains('password')) {
            return 'Correo o contraseña incorrectos';
          }
          return 'Error de autenticación: ${error.code}';
      }
    }
    return 'Error desconocido: $error';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: size.height * 0.28,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/imagenback.png', fit: BoxFit.cover),
                Container(
                  color: const Color.fromARGB(255, 0, 11, 44).withOpacity(0.75),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Iniciar Sesion',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Por favor inicia sesión con tu cuenta existente',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.22,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 30.0,
                ),
                child: _buildForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Correo electrónico',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          _buildTextField(_emailController, 'example@gmail.com', false),
          const SizedBox(height: 8),
          const Text(
            'Contraseña',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          _buildPasswordField(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password',
                style: TextStyle(
                  color: AppColors.second,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6C5A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar Sesión'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'O inicia sesión con',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  'Facebook',
                  FontAwesomeIcons.facebookF,
                  Colors.blue,
                  () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSocialButton(
                  'Google',
                  FontAwesomeIcons.google,
                  Colors.red,
                  _loginWithGoogle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No tienes cuenta?',
                style: TextStyle(color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.55),
                    builder: (_) => const RegisterScreen(),
                  );
                },
                child: Text(
                  'Registrate',
                  style: TextStyle(
                    color: AppColors.second,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool obscure,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      validator:
          (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: '•••••••••',
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      validator:
          (value) =>
              value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
    );
  }

  Widget _buildSocialButton(
    String label,
    IconData icon,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      icon: Icon(icon, color: iconColor),
      label: Text(label),
    );
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle(context);
      if (user != null && mounted) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final role = userDoc.data()?['role'] ?? 'client';
        if (role == 'admin') {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushReplacementNamed('/admin');
        } else {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushReplacementNamed('/client');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al iniciar sesión con Google: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFD91010),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
