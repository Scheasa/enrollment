import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/shift_style.dart';
import '../../models/course.dart';
import '../../models/schedule.dart';
import '../../services/schedule_manage_service.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';
import 'schedule_form_screen.dart';

class ManageSchedulesScreen extends StatefulWidget {
  final Course course;

  const ManageSchedulesScreen({super.key, required this.course});

  @override
  State<ManageSchedulesScreen> createState() => _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends State<ManageSchedulesScreen> {
  final _service = ScheduleManageService();

  List<Schedule> _items = [];
  bool _loading = true;
  String? _error;

  /// Distinct teachers already assigned to this course's schedules.
  List<String> get _teacherNames {
    final names = {for (final s in _items) s.teacherName.trim()}..remove('');
    return names.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.fetch(widget.course.id);
      if (!mounted) return;
      setState(() {
        _items = result;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load schedules.';
        _loading = false;
      });
    }
  }

  Future<void> _openForm([Schedule? schedule]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(
          course: widget.course,
          schedule: schedule,
          teachers: _teacherNames,
        ),
      ),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(Schedule s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this schedule?'),
        content: Text(
          '${s.shiftLabel} · ${s.daysText} · ${s.timeText} '
          'will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _service.delete(s.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Schedule deleted.')),
      );
      _load();
    } on ApiException catch (e) {
      // e.g. 409: this schedule has enrollment history
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Schedules')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New schedule'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            Text(
              widget.course.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Classes students can choose when they enroll',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              ErrorBanner(_error!),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ] else if (_loading && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No schedules yet.\nTap "New schedule" to add one.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              for (final s in _items) _card(context, s),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Schedule s) {
    final theme = Theme.of(context);
    final style = shiftStyle(s.shift);
    final ratio = s.maxCapacity > 0
        ? (s.seatsTaken / s.maxCapacity).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final seatColor = s.isFull
        ? theme.colorScheme.error
        : ratio >= 0.8
        ? AppColors.sun
        : theme.colorScheme.tertiary;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openForm(s),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: style.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(style.icon, color: style.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.shiftLabel} · ${s.timeText}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          s.daysText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          _openForm(s);
                        case 'delete':
                          _delete(s);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          s.isFull ? 'Full' : '${s.seatsAvailable} seats left',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: seatColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${s.seatsTaken}/${s.maxCapacity} taken',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        color: seatColor,
                        backgroundColor: seatColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
