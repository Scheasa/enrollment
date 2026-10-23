import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/enrollment.dart';
import '../../models/payment.dart';
import '../../providers/enrollments_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_badge.dart';
import 'pay_screen.dart';
import 'payment_history_screen.dart';

class MyEnrollmentsTab extends StatefulWidget {
  const MyEnrollmentsTab({super.key});

  @override
  State<MyEnrollmentsTab> createState() => _MyEnrollmentsTabState();
}

class _MyEnrollmentsTabState extends State<MyEnrollmentsTab> {
  String? _filter; // null = all

  static const _filters = <(String, String?, IconData)>[
    ('All', null, Icons.apps_rounded),
    ('Pending', 'pending', Icons.hourglass_top),
    ('Approved', 'approved', Icons.check_circle_outline),
    ('Rejected', 'rejected', Icons.cancel_outlined),
    ('Dropped', 'dropped', Icons.remove_circle_outline),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EnrollmentsProvider>().load(reset: true);
    });
  }

  Future<void> _drop(Enrollment e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Drop this course?'),
        content: Text(
          'You will leave "${e.course?.title ?? 'this course'}" '
          'and give up your seat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Drop'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<EnrollmentsProvider>().drop(e.id);

    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Enrollment dropped.')),
    );
  }

  Future<void> _pay(Enrollment e) async {
    final paid = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => PayScreen(enrollment: e)));
    if (paid == true && mounted) {
      context.read<EnrollmentsProvider>().load();
    }
  }

  void _history(Enrollment e) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentHistoryScreen(enrollment: e)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnrollmentsProvider>();
    final items = _filter == null
        ? provider.items
        : provider.items.where((e) => e.status == _filter).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<EnrollmentsProvider>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CategoryChip(
                      label: f.$1,
                      icon: f.$3,
                      color: f.$2 == null
                          ? AppColors.primary
                          : StatusBadge.colorFor(f.$2!),
                      selected: _filter == f.$2,
                      onTap: () => setState(() => _filter = f.$2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (provider.error != null) ...[
            ErrorBanner(provider.error!),
            TextButton.icon(
              onPressed: () => context.read<EnrollmentsProvider>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ] else if (provider.isLoading && provider.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  provider.items.isEmpty
                      ? 'You have not enrolled in any course yet.'
                      : 'No enrollments with this status.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            for (final e in items) _card(context, e),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Enrollment e) {
    final theme = Theme.of(context);
    final s = e.schedule;
    final accent = AppColors.accentFor(e.course?.id ?? e.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    (e.course?.isEnglish ?? false)
                        ? Icons.translate
                        : Icons.computer,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.course?.title ?? 'Course #${e.id}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (s != null)
                        Text(
                          '${s.shiftLabel} · ${s.timeText}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: e.status, label: e.statusLabel),
              ],
            ),
            if (s != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _info(context, Icons.calendar_today_outlined, s.daysText),
                  _info(context, Icons.person_outline, s.teacherName),
                  _info(
                    context,
                    Icons.meeting_room_outlined,
                    'Room ${s.roomNumber}',
                  ),
                ],
              ),
            ],
            if (e.enrolledDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Requested on ${e.enrolledDate}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
            if (e.remarks != null && e.remarks!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Note: ${e.remarks}'),
              ),
            ],
            _paymentBlock(context, e),
            if (e.canPay || e.payments.isNotEmpty || e.canDrop) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (e.payments.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _history(e),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Payments'),
                      ),
                    if (e.canPay)
                      FilledButton.icon(
                        onPressed: () => _pay(e),
                        icon: const Icon(Icons.payments_rounded),
                        label: const Text('Pay'),
                      ),
                    if (e.canDrop)
                      TextButton.icon(
                        onPressed: () => _drop(e),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Drop'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Paid / fee progress. Hidden when there is nothing to show.
  Widget _paymentBlock(BuildContext context, Enrollment e) {
    final p = e.paymentSummary;
    if (p == null || p.fee <= 0) return const SizedBox.shrink();
    if (!e.canDrop && e.payments.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final done = p.isFullyPaid;
    final color = done ? theme.colorScheme.tertiary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  done ? Icons.verified_rounded : Icons.payments_outlined,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    done
                        ? 'Fully paid'
                        : 'Paid ${money(p.verified)} of ${money(p.fee)}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                if (!done)
                  Text(
                    'Balance ${money(p.remaining + p.pending)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: p.paidRatio,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
            if (p.pending > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${money(p.pending)} waiting for staff to confirm',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.sun,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
