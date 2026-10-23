import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/payment_style.dart';
import '../../models/enrollment.dart';
import '../../models/payment.dart';
import '../../widgets/gradient_scaffold.dart';

class PaymentHistoryScreen extends StatelessWidget {
  final Enrollment enrollment;

  const PaymentHistoryScreen({super.key, required this.enrollment});

  /// The server stores a rejection reason in the enrollment remarks as
  /// "[Payment #12 rejected] reason". Pull out the one for [p].
  String? _rejectReason(Payment p) {
    final marker = '[Payment #${p.id} rejected]';
    for (final line in (enrollment.remarks ?? '').split('\n')) {
      if (line.startsWith(marker)) {
        final reason = line.substring(marker.length).trim();
        return reason.isEmpty ? null : reason;
      }
    }
    return null;
  }

  void _showReceipt(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Could not load the receipt image.'),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payments = enrollment.payments;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            enrollment.course?.title ?? 'Course',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No payments yet.')),
            )
          else
            for (final p in payments) _card(context, p),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Payment p) {
    final theme = Theme.of(context);
    final status = paymentStatusStyle(p.status);
    final method = paymentMethodStyle(p.method);
    final reason = p.status == 'rejected' ? _rejectReason(p) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(method.icon, color: method.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        money(p.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${method.label} · ${p.dateText}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 14, color: status.color),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (p.status == 'verified' && p.verifierName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Confirmed by ${p.verifierName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
            if (reason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Reason: $reason'),
              ),
            ],
            if (p.receiptUrl != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showReceipt(context, p.receiptUrl!),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('View receipt'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
