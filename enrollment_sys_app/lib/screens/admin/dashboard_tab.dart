import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/payment_style.dart';
import '../../models/dashboard_stats.dart';
import '../../models/payment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/course_thumb.dart' show DecorBubble;
import '../../widgets/error_banner.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';
import 'manage_payments_screen.dart';
import 'payment_review_screen.dart';

class DashboardTab extends StatelessWidget {
  /// Called when a card is tapped, to jump to the filtered list.
  /// `null` means "all statuses".
  final void Function(String? status) onOpenStatus;
  final VoidCallback onOpenProfile;

  const DashboardTab({
    super.key,
    required this.onOpenStatus,
    required this.onOpenProfile,
  });

  /// Opens the Payments screen, then refreshes the numbers when you come back.
  Future<void> _openPayments(
    BuildContext context, [
    String status = 'pending',
  ]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManagePaymentsScreen(initialStatus: status),
      ),
    );
    if (context.mounted) context.read<DashboardProvider>().load();
  }

  Future<void> _review(BuildContext context, Payment p) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentReviewScreen(payment: p)),
    );
    if (changed == true && context.mounted) {
      context.read<DashboardProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final stats = dash.stats;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // ---- Greeting ----
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onOpenProfile,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: UserAvatar(
                    name: user.name,
                    url: user.profileImageUrl,
                    radius: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (dash.error != null) ...[
            ErrorBanner(dash.error!),
            TextButton.icon(
              onPressed: () => context.read<DashboardProvider>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ] else if (stats == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _pendingHero(context, stats.count('pending')),
            const SizedBox(height: 24),
            Text(
              'Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 142,
              ),
              children: [
                _StatCard(
                  label: 'All requests',
                  value: stats.enrollments.values.fold(0, (a, b) => a + b),
                  icon: Icons.assignment_outlined,
                  color: AppColors.primary,
                  onTap: () => onOpenStatus(null),
                ),
                _StatCard(
                  label: 'Approved',
                  value: stats.count('approved'),
                  icon: Icons.check_circle_outline,
                  color: StatusBadge.colorFor('approved'),
                  onTap: () => onOpenStatus('approved'),
                ),
                _StatCard(
                  label: 'Rejected',
                  value: stats.count('rejected'),
                  icon: Icons.cancel_outlined,
                  color: StatusBadge.colorFor('rejected'),
                  onTap: () => onOpenStatus('rejected'),
                ),
                _StatCard(
                  label: 'Dropped',
                  value: stats.count('dropped'),
                  icon: Icons.remove_circle_outline,
                  color: StatusBadge.colorFor('dropped'),
                  onTap: () => onOpenStatus('dropped'),
                ),
                _StatCard(
                  label: 'Students',
                  value: stats.totalStudents,
                  icon: Icons.groups_outlined,
                  color: AppColors.violet,
                ),
                _StatCard(
                  label: 'Active courses',
                  value: stats.activeCourses,
                  icon: Icons.menu_book_outlined,
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
            ..._paymentsSection(context, stats),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Payments
  // ---------------------------------------------------------------------------

  List<Widget> _paymentsSection(BuildContext context, DashboardStats stats) {
    final theme = Theme.of(context);

    return [
      const SizedBox(height: 28),
      Row(
        children: [
          Expanded(
            child: Text(
              'Payments',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _openPayments(context),
            child: const Text('See all'),
          ),
        ],
      ),
      Text(
        'Revenue counts verified payments only.',
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _MoneyCard(
              label: 'This month',
              value: money(stats.revenueThisMonth),
              icon: Icons.trending_up_rounded,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MoneyCard(
              label: 'All time',
              value: money(stats.revenueTotal),
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _paymentCounts(context, stats),
      if (stats.recentPendingPayments.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text(
          'Needs review',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final p in stats.recentPendingPayments)
          _PendingPaymentTile(payment: p, onTap: () => _review(context, p)),
      ],
    ];
  }

  Widget _paymentCounts(BuildContext context, DashboardStats stats) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: AppColors.primary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          for (final s in const ['pending', 'verified', 'rejected'])
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _openPayments(context, s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Text(
                        '${stats.paymentCount(s)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: paymentStatusStyle(s).color,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            paymentStatusStyle(s).icon,
                            size: 14,
                            color: paymentStatusStyle(s).color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            paymentStatusStyle(s).label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Enrollment hero (unchanged)
  // ---------------------------------------------------------------------------

  Widget _pendingHero(BuildContext context, int pending) {
    final theme = Theme.of(context);
    const deepOrange = Color(0xFFF58A07);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sun, deepOrange],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sun.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -30,
            top: -30,
            child: DecorBubble(size: 150, opacity: 0.16),
          ),
          const Positioned(
            right: 60,
            bottom: -45,
            child: DecorBubble(size: 100, opacity: 0.12),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        pending > 0 ? Icons.hourglass_top : Icons.check_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Waiting for review',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        pending == 1 ? 'pending request' : 'pending requests',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (pending > 0)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: deepOrange,
                    ),
                    onPressed: () => onOpenStatus('pending'),
                    child: const Text('Review now'),
                  )
                else
                  Text(
                    "You're all caught up!",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: AppColors.primary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A money amount (text), e.g. "This month  $450.00".
class _MoneyCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MoneyCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: AppColors.primary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One payment waiting for review. Tap to open the review screen.
class _PendingPaymentTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;

  const _PendingPaymentTile({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final method = paymentMethodStyle(payment.method);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: method.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(method.icon, color: method.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.studentName ?? 'Student',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${payment.courseTitle ?? 'Course'} · ${method.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                money(payment.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
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
