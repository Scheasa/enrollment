import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'admin/admin_home_screen.dart';
import 'auth/login_screen.dart';
import 'student/student_home_screen.dart';

/// Shows the right screen for the current login state:
/// checking -> splash, signed out -> login, staff/admin -> admin home, else student home.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = auth.user;
    if (user == null) return const LoginScreen();

    return user.isStaff ? const AdminHomeScreen() : const StudentHomeScreen();
  }
}
