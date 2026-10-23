import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_enrollments_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/pill_nav_bar.dart';
import '../student/profile_tab.dart';
import 'admin_enrollments_tab.dart';
import 'dashboard_tab.dart';
import 'manage_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  static const _titles = ['', 'Enrollments', 'Manage', 'Profile'];

  static const _items = [
    PillNavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    PillNavItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      label: 'Enrollments',
    ),
    PillNavItem(
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune_rounded,
      label: 'Manage',
    ),
    PillNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().load(reset: true);
      context.read<AdminEnrollmentsProvider>().load(reset: true);
    });
  }

  void _select(int i) {
    setState(() => _index = i);
    // Keep the numbers and the list fresh when coming back to them.
    if (i == 0) context.read<DashboardProvider>().load();
    if (i == 1) context.read<AdminEnrollmentsProvider>().load();
  }

  void _openStatus(String? status) {
    context.read<AdminEnrollmentsProvider>().setStatus(status);
    setState(() => _index = 1);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // The Dashboard tab has its own greeting header instead of an app bar.
        appBar: _index == 0 ? null : AppBar(title: Text(_titles[_index])),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              DashboardTab(
                onOpenStatus: _openStatus,
                onOpenProfile: () => _select(3),
              ),
              const AdminEnrollmentsTab(),
              const ManageTab(),
              const ProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: PillNavBar(
          index: _index,
          items: _items,
          onSelected: _select,
        ),
      ),
    );
  }
}
