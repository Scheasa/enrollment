import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'manage_announcements_screen.dart';
import 'manage_courses_screen.dart';
import 'manage_payments_screen.dart';
import 'manage_users_screen.dart';

class ManageTab extends StatelessWidget {
  const ManageTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().user?.role == 'admin';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _ManageCard(
          icon: Icons.payments_rounded,
          color: AppColors.mint,
          title: 'Payments',
          subtitle: 'Check receipts, verify or reject payments',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ManagePaymentsScreen()),
          ),
        ),
        _ManageCard(
          icon: Icons.menu_book_rounded,
          color: AppColors.primary,
          title: 'Courses',
          subtitle: 'Add, edit or hide courses and set their schedules',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => ManageCoursesScreen())),
        ),
        _ManageCard(
          icon: Icons.campaign_rounded,
          color: AppColors.sun,
          title: 'Announcements',
          subtitle: 'Post news and updates for students',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ManageAnnouncementsScreen(),
            ),
          ),
        ),
        if (isAdmin)
          _ManageCard(
            icon: Icons.people_alt_rounded,
            color: AppColors.violet,
            title: 'Users',
            subtitle: 'Find, edit or create student, staff and admin accounts',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
            ),
          ),
      ],
    );
  }
}

class _ManageCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManageCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
