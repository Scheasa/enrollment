import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Icon and color for a shift, shared by the schedule list and form.
({IconData icon, Color color}) shiftStyle(String shift) => switch (shift) {
  'morning' => (icon: Icons.wb_sunny_rounded, color: AppColors.sun),
  'afternoon' => (icon: Icons.wb_twilight_rounded, color: AppColors.violet),
  _ => (icon: Icons.nights_stay_rounded, color: AppColors.primary),
};
