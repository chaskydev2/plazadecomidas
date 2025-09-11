import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/core/services/auth_service.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/shared/screens/login_screen.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For Facebook and Google icons

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.email, this.name});

  final String? email;
  final String? name;

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        context,
      );

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'No se pudo crear el usuario.',
        );
      }

      if (mounted) {
        try {
          if (!user.emailVerified) {
            await user.sendEmailVerification();
            _showOverlayMessage(
              'Cuenta creada exitosamente. Se envió un correo de verificación.',
              Colors.green,
            );
          }
        } catch (e) {
          _showOverlayMessage(
            'Cuenta creada, pero no se pudo enviar el correo de verificación.',
            Colors.deepOrange,
          );
        }

        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/client');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showOverlayMessage(_getErrorMessage(e), Colors.redAccent);
      }
    } catch (e) {
      if (mounted) {
        _showOverlayMessage('Error inesperado: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOverlayMessage(String message, Color color) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.utensils,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (message.contains('correo'))
                      TextButton(
                        onPressed: () {
                          entry.remove();
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.55),
                            builder: (context) => const LoginScreen(),
                          );
                        },
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }

  String _getErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico';
      case 'invalid-email':
        return 'El formato del correo electrónico es inválido';
      case 'operation-not-allowed':
        return 'El registro con correo y contraseña no está habilitado';
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu conexión a internet';
      default:
        return 'Error en el registro: ${error.message ?? error.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent, // Make dialog background transparent
      insetPadding: EdgeInsets.zero, // Remove default dialog padding
      // Wrap content in a Scaffold to properly extend to safe areas if needed,
      // or use a Sizedbox.expand to guarantee full screen.
      // For a Dialog, directly setting the child to expand usually works.
      child: SizedBox.expand(
        // This makes the child expand to fill all available space
        child: Stack(
          children: [
            // Background Image with secondary color overlay
            Positioned(
              top: 0, // Start from the very top
              left: 0,
              right: 0, // Extend to the full width
              bottom:
                  size.height *
                  0.4, // Adjust this as needed to control background height
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/imagenback.png', // Ensure this asset exists
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: const Color.fromARGB(
                      255,
                      0,
                      11,
                      44,
                    ).withOpacity(0.75),
                  ),
                ],
              ),
            ),
            // Overlay: Back button, Title, Subtitle
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  20, // Add padding relative to status bar
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(
                            10,
                          ), // Slightly larger padding
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.25,
                            ), // Slightly more opaque
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 22, // Slightly larger icon
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.01,
                    ), // More vertical spacing
                    // Title
                    const Text(
                      'Registrarse', // Changed to "Registrarse" for clarity in a register screen
                      style: TextStyle(
                        fontSize: 32, // Larger title
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8, // Increased blur
                            offset: Offset(0, 3), // Slightly more offset
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4), // Consistent spacing
                    // Subtitle
                    const Text(
                      'Crea una cuenta para empezar', // Adjusted subtitle for registration
                      style: TextStyle(
                        fontSize: 18, // Slightly larger subtitle
                        color: Colors.white,
                        fontFamily: 'Inter',
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 5, // Increased blur
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // White container for login/registration form
            Positioned(
              top:
                  size.height *
                  0.20, // Adjusted to position the white card lower and overlap less with the top content
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 30.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nombre
                        const Text(
                          'Nombre completo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600, // Slightly bolder
                            color: Colors.black87, // Darker for better contrast
                            fontFamily: 'Inter', // Consistent font family
                          ),
                        ),
                        const SizedBox(height: 4), // Consistent spacing
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Nombre completo',
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            errorStyle: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese su nombre';
                            }
                            if (value.trim().length > 50) {
                              return 'El nombre no debe superar los 50 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 4), // Consistent spacing
                        // Email
                        const Text(
                          'Correo electrónico',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Correo electrónico',
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            errorStyle: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese su correo';
                            }
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Ingrese un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        // Password
                        const Text(
                          'Contraseña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.second,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            errorStyle: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese una contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            if (!RegExp(
                              r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$',
                            ).hasMatch(value)) {
                              return 'Debe tener letras y números';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        // Confirm Password
                        const Text(
                          'Confirmar Contraseña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Confirmar Contraseña',
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.second,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            errorStyle: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          validator:
                              (value) =>
                                  value != _passwordController.text
                                      ? 'Las contraseñas no coinciden'
                                      : null,
                        ),
                        const SizedBox(height: 14), // Consistent spacing
                        ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                12,
                              ), // Consistent with text fields
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            elevation: 5, // Add a subtle shadow to the button
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 24, // Adjusted size for spinner
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth:
                                          2.5, // Slightly thicker spinner
                                    ),
                                  )
                                  : const Text('Registrarme'),
                        ),
                        const SizedBox(height: 20), // Consistent spacing
                        // Botón de Google
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              FontAwesomeIcons.google,
                              color: Colors.red,
                            ),
                            label: const Text('Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey),
                              ),
                            ),
                            onPressed:
                                _isLoading
                                    ? null
                                    : () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      try {
                                        final user = await _authService
                                            .signInWithGoogle(context);
                                        if (user != null && mounted) {
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Cuenta creada con Google exitosamente',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppColors.primary,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: EdgeInsets.all(16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(12),
                                                ),
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          // Example navigation - replace with your actual route
                                          // Navigator.of(context, rootNavigator: true).pushReplacementNamed('/client');
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Error al iniciar sesión con Google',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            margin: EdgeInsets.all(16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(12),
                                              ),
                                            ),
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    },
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "¿Ya tienes cuenta?",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pop(); // Close current dialog
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.black.withOpacity(0.55),
                                  builder:
                                      (context) =>
                                          const LoginScreen(), // Assuming LoginScreen exists
                                );
                              },
                              child: Text(
                                'Inicia sesión',
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
