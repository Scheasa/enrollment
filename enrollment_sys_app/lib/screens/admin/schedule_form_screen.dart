import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/shift_style.dart';
import '../../models/course.dart';
import '../../models/schedule.dart';
import '../../services/schedule_manage_service.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';

class ScheduleFormScreen extends StatefulWidget {
  final Course course;

  /// null = create a new schedule, otherwise edit this one.
  final Schedule? schedule;

  /// Teachers already responsible for this course (shown in the dropdown).
  final List<String> teachers;

  const ScheduleFormScreen({
    super.key,
    required this.course,
    this.schedule,
    this.teachers = const [],
  });

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  static const _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _newTeacherKey = '__new__';

  String? _teacherChoice;

  String get _teacherName => _teacherChoice == _newTeacherKey
      ? _teacherCtrl.text.trim()
      : (_teacherChoice ?? '');

  static const _shiftDefaults = <String, (TimeOfDay, TimeOfDay)>{
    'morning': (TimeOfDay(hour: 7, minute: 30), TimeOfDay(hour: 9, minute: 0)),
    'afternoon': (
      TimeOfDay(hour: 13, minute: 30),
      TimeOfDay(hour: 15, minute: 0),
    ),
    'evening': (
      TimeOfDay(hour: 17, minute: 30),
      TimeOfDay(hour: 19, minute: 0),
    ),
  };

  final _service = ScheduleManageService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _teacherCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _capacityCtrl;

  late String _shift;
  late Set<String> _days;
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _timesTouched = false;

  String? _daysError;
  String? _timeError;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.schedule != null;

  static TimeOfDay _parse(String hhmm, TimeOfDay fallback) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return fallback;
    return TimeOfDay(hour: h, minute: m);
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;

    _teacherCtrl = TextEditingController(text: s?.teacherName ?? '');
    _roomCtrl = TextEditingController(text: s?.roomNumber ?? '');
    _capacityCtrl = TextEditingController(text: '${s?.maxCapacity ?? 30}');

    _shift = s?.shift.isNotEmpty == true ? s!.shift : 'morning';
    _days = {...?s?.days};

    final current = s?.teacherName.trim() ?? '';
    if (widget.teachers.isEmpty) {
      _teacherChoice = _newTeacherKey; // nobody yet, so type the first name
    } else if (widget.teachers.contains(current)) {
      _teacherChoice = current;
    } else if (s != null) {
      _teacherChoice = _newTeacherKey; // safety net, keeps the typed name
    }

    final defaults = _shiftDefaults[_shift]!;
    _start = s == null ? defaults.$1 : _parse(s.startTime, defaults.$1);
    _end = s == null ? defaults.$2 : _parse(s.endTime, defaults.$2);
    _timesTouched = s != null;
  }

  @override
  void dispose() {
    _teacherCtrl.dispose();
    _roomCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  void _setShift(String shift) {
    setState(() {
      _shift = shift;
      if (!_timesTouched) {
        final d = _shiftDefaults[shift]!;
        _start = d.$1;
        _end = d.$2;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _timesTouched = true;
      _timeError = null;
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();

    final daysOk = _days.isNotEmpty;
    final timesOk =
        _end.hour * 60 + _end.minute > _start.hour * 60 + _start.minute;

    setState(() {
      _daysError = daysOk ? null : 'Pick at least one day';
      _timeError = timesOk ? null : 'End time must be after the start time';
    });

    if (!formOk || !daysOk || !timesOk) return;

    FocusScope.of(context).unfocus();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.save(
        id: widget.schedule?.id,
        courseId: widget.course.id,
        teacher: _teacherName,
        room: _roomCtrl.text.trim(),
        shift: _shift,
        days: [
          for (final d in _allDays)
            if (_days.contains(d)) d,
        ],
        start: _fmt(_start),
        end: _fmt(_end),
        capacity: int.parse(_capacityCtrl.text.trim()),
      );

      if (!mounted) return;
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Schedule updated.' : 'Schedule created.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit schedule' : 'New schedule')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.course.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      ErrorBanner(_error!),
                      const SizedBox(height: 16),
                    ],
                    if (widget.teachers.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _teacherChoice,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Teacher',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: [
                          for (final t in widget.teachers)
                            DropdownMenuItem(
                              value: t,
                              child: Text(t, overflow: TextOverflow.ellipsis),
                            ),
                          const DropdownMenuItem(
                            value: _newTeacherKey,
                            child: Text('+ Add new teacher…'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _teacherChoice = v),
                        validator: (v) => v == null ? 'Choose a teacher' : null,
                      ),
                    if (_teacherChoice == _newTeacherKey) ...[
                      if (widget.teachers.isNotEmpty)
                        const SizedBox(height: 12),
                      TextFormField(
                        controller: _teacherCtrl,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: widget.teachers.isEmpty
                              ? 'Teacher name'
                              : 'New teacher name',
                          prefixIcon: const Icon(Icons.person_add_alt_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter the teacher name'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _roomCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Room',
                              prefixIcon: Icon(Icons.meeting_room_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter a room'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _capacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacity',
                              prefixIcon: Icon(Icons.event_seat_outlined),
                            ),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null) return 'Enter a number';
                              if (n < 1 || n > 500) return '1 to 500';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Shift', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final shift in const [
                          'morning',
                          'afternoon',
                          'evening',
                        ])
                          CategoryChip(
                            label: shift[0].toUpperCase() + shift.substring(1),
                            icon: shiftStyle(shift).icon,
                            color: shiftStyle(shift).color,
                            selected: _shift == shift,
                            onTap: () => _setShift(shift),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Days', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final d in _allDays)
                          _DayChip(
                            label: d,
                            selected: _days.contains(d),
                            onTap: () => setState(() {
                              _daysError = null;
                              if (!_days.remove(d)) _days.add(d);
                            }),
                          ),
                      ],
                    ),
                    if (_daysError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _daysError!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeBox(
                            label: 'Start',
                            value: _fmt(_start),
                            onTap: () => _pickTime(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeBox(
                            label: 'End',
                            value: _fmt(_end),
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    if (_timeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _timeError!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEdit ? 'Save changes' : 'Create schedule'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      elevation: selected ? 3 : 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 42,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule),
        ),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
