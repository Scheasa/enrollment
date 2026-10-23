import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/enrollment.dart';
import '../../providers/admin_enrollments_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/note_dialog.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';

class AdminEnrollmentsTab extends StatefulWidget {
  const AdminEnrollmentsTab({super.key});

  @override
  State<AdminEnrollmentsTab> createState() => _AdminEnrollmentsTabState();
}

class _AdminEnrollmentsTabState extends State<AdminEnrollmentsTab> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const _filters = <(String, String?, IconData)>[
    ('Pending', 'pending', Icons.hourglass_top),
    ('Approved', 'approved', Icons.check_circle_outline),
    ('Rejected', 'rejected', Icons.cancel_outlined),
    ('Dropped', 'dropped', Icons.remove_circle_outline),
    ('All', null, Icons.apps_rounded),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<AdminEnrollmentsProvider>().setSearch(value.trim());
      }
    });
    setState(() {}); // show/hide the clear button
  }

  Future<void> _approve(Enrollment e) async {
    final note = await showNoteDialog(
      context,
      title: 'Approve enrollment',
      label: 'Note to student (optional)',
      confirmLabel: 'Approve',
    );
    if (note == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AdminEnrollmentsProvider>().approve(
      e.id,
      remarks: note,
    );

    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Enrollment approved.')),
    );
  }

  Future<void> _reject(Enrollment e) async {
    final reason = await showNoteDialog(
      context,
      title: 'Reject enrollment',
      label: 'Reason (shown to the student)',
      confirmLabel: 'Reject',
      required: true,
    );
    if (reason == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AdminEnrollmentsProvider>().reject(
      e.id,
      reason,
    );

    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Enrollment rejected.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminEnrollmentsProvider>();

    return RefreshIndicator(
      onRefresh: () => context.read<AdminEnrollmentsProvider>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search student name or email',
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _debounce?.cancel();
                        context.read<AdminEnrollmentsProvider>().setSearch('');
                        setState(() {});
                      },
                    ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                      selected: provider.status == f.$2,
                      onTap: () => context
                          .read<AdminEnrollmentsProvider>()
                          .setStatus(f.$2),
                    ),
                  ),
              ],
            ),
          ),
          if (provider.error != null) ...[
            ErrorBanner(provider.error!),
            TextButton.icon(
              onPressed: () => context.read<AdminEnrollmentsProvider>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ] else if (provider.isLoading && provider.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No enrollments found.')),
            )
          else ...[
            for (final e in provider.items) _card(context, e),
            if (provider.hasMore)
              Center(
                child: provider.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    : TextButton(
                        onPressed: () =>
                            context.read<AdminEnrollmentsProvider>().loadMore(),
                        child: const Text('Load more'),
                      ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Enrollment e) {
    final theme = Theme.of(context);
    final s = e.schedule;
    final accent = AppColors.accentFor(e.course?.id ?? e.id);
    final canApprove = e.status == 'pending';
    final canReject = e.status == 'pending' || e.status == 'approved';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student
            Row(
              children: [
                UserAvatar(
                  name: e.student?.name ?? 'Student',
                  url: e.student?.profileImageUrl,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.student?.name ?? 'Student',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (e.student != null)
                        Text(
                          e.student!.email,
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
                StatusBadge(status: e.status, label: e.statusLabel),
              ],
            ),
            const SizedBox(height: 12),

            // Course + schedule
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      (e.course?.isEnglish ?? false)
                          ? Icons.translate
                          : Icons.computer,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.course?.title ?? 'Course',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (s != null)
                          Text(
                            '${s.shiftLabel} · ${s.daysText} · ${s.timeText}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (s != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _info(context, Icons.person_outline, s.teacherName),
                  _info(
                    context,
                    Icons.meeting_room_outlined,
                    'Room ${s.roomNumber}',
                  ),
                  _info(
                    context,
                    Icons.event_seat_outlined,
                    '${s.seatsTaken}/${s.maxCapacity} seats taken',
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
            if (canApprove || canReject) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canReject)
                    OutlinedButton(
                      onPressed: () => _reject(e),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  if (canApprove) ...[
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => _approve(e),
                      child: const Text('Approve'),
                    ),
                  ],
                ],
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
