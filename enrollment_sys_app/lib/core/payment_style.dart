import 'package:flutter/material.dart';

import 'app_colors.dart';

const _okColor = Color(0xFF0E9F8E);
const _badColor = Color(0xFFE5484D);

/// Icon, color and label for a payment status.
({IconData icon, Color color, String label}) paymentStatusStyle(
  String status,
) => switch (status) {
  'verified' => (
    icon: Icons.check_circle_rounded,
    color: _okColor,
    label: 'Verified',
  ),
  'rejected' => (
    icon: Icons.cancel_rounded,
    color: _badColor,
    label: 'Rejected',
  ),
  _ => (
    icon: Icons.hourglass_top_rounded,
    color: AppColors.sun,
    label: 'Pending',
  ),
};

/// Icon, color and label for a payment method.
({IconData icon, Color color, String label}) paymentMethodStyle(
  String method,
) => switch (method) {
  'aba' => (
    icon: Icons.account_balance_rounded,
    color: AppColors.primary,
    label: 'ABA',
  ),
  'acleda' => (
    icon: Icons.account_balance_wallet_rounded,
    color: AppColors.violet,
    label: 'ACLEDA',
  ),
  'wing' => (
    icon: Icons.phone_android_rounded,
    color: AppColors.sun,
    label: 'Wing',
  ),
  _ => (icon: Icons.payments_rounded, color: AppColors.mint, label: 'Cash'),
};
