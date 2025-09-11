import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // <- kReleaseMode

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // <- APP CHECK
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'core/navigation/app_routes.dart';
import 'core/services/auth_service.dart';
import 'modules/admin/screens/admin_dashboard_screen.dart';
import 'modules/manager/screens/manager_dashboard_screen.dart';
import 'modules/cliente/screens/home_screen.dart';
import 'modules/shared/screens/login_screen.dart';
import 'modules/shared/screens/register_screen.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) Activa App Check ANTES de tocar Firestore/Auth
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kReleaseMode
            ? AndroidProvider
                .playIntegrity // Producción
            : AndroidProvider
                .debug, // Desarrollo: imprime Debug Token en el log
  );

  // Fuerza la obtención del token (en debug mostrará el Debug Token en Logcat)
  try {
    await FirebaseAppCheck.instance.getToken(true);
  } catch (_) {
    // no pasa nada si falla; igual AppCheck queda activo
  }

  // 3) Quita el warning de locale nulo
  await FirebaseAuth.instance.setLanguageCode('es');

  // 4) Cualquier código que toque Firestore/Auth va DESPUÉS de App Check
  await AuthService().createInitialAdmin();

  await Future.delayed(const Duration(seconds: 1));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koko Restaurant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routes: {
        ...AppRoutes.routes,
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/client': (context) => const HomeScreen(),
      },
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            left: 0,
            right: -140,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: double.infinity,
              child: Image.asset(
                'assets/images/imagenback.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(padding: const EdgeInsets.only(bottom: 24.0)),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.1,
                    vertical: isPortrait ? size.height * 0.1 : 6,
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ELIGE LOQUE QUIERES COMER \nY DISFRUTA',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.black.withOpacity(0.55),
                                builder: (context) => const RegisterScreen(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                            ),
                            child: const Text('Registrarse'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.black.withOpacity(0.55),
                                builder: (context) => const LoginScreen(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.second,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                            ),
                            child: const Text('Iniciar Sesión'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isPortrait ? size.height * 0.07 : 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
