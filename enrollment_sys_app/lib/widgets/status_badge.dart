import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const StatusBadge({super.key, required this.status, required this.label});

  static Color colorFor(String status) => switch (status) {
    'approved' => Colors.green.shade700,
    'pending' => Colors.orange.shade800,
    'rejected' => Colors.red.shade700,
    _ => Colors.grey.shade700, // dropped
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
