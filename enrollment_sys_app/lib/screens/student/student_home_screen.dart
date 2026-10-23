import 'package:flutter/material.dart';

import '../../widgets/gradient_background.dart';
import '../../widgets/pill_nav_bar.dart';
import 'courses_tab.dart';
import 'my_enrollments_tab.dart';
import 'profile_tab.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _index = 0;

  static const _titles = ['', 'My enrollments', 'Profile'];

  static const _items = [
    PillNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    PillNavItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      label: 'Enrollments',
    ),
    PillNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // The Home tab has its own greeting header instead of an app bar.
        appBar: _index == 0 ? null : AppBar(title: Text(_titles[_index])),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              CoursesTab(onOpenProfile: () => setState(() => _index = 2)),
              const MyEnrollmentsTab(),
              const ProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: PillNavBar(
          index: _index,
          items: _items,
          onSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
