import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Icon and color for a user role, shared by the users list and form.
({IconData icon, Color color, String label}) roleStyle(String role) =>
    switch (role) {
      'admin' => (
        icon: Icons.shield_rounded,
        color: AppColors.sun,
        label: 'Admin',
      ),
      'staff' => (
        icon: Icons.badge_rounded,
        color: AppColors.violet,
        label: 'Staff',
      ),
      _ => (icon: Icons.school_rounded, color: AppColors.sky, label: 'Student'),
    };
