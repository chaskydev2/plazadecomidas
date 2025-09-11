import 'package:flutter/material.dart';
import '../../modules/shared/screens/login_screen.dart';
import '../../modules/shared/screens/register_screen.dart';
import '../../modules/cliente/screens/home_screen.dart';
import '../../modules/admin/screens/admin_dashboard_screen.dart';
import '../../modules/manager/screens/manager_dashboard_screen.dart';
import '../../modules/admin/screens/manager_assignment_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String admin = '/admin';
  static const String managerAssignment = '/admin/manager-assignment';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    admin: (context) => const AdminDashboardScreen(),
    managerAssignment: (context) => const ManagerAssignmentScreen(),
  };

  static void navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  static void navigateToAndReplace(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  static void navigateToAndRemoveUntil(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }
}
