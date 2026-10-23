import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/app_colors.dart';
import '../../models/course.dart';
import '../../models/schedule.dart';
import '../../providers/enrollments_provider.dart';
import '../../services/course_service.dart';
import '../../services/enrollment_service.dart';
import '../../widgets/course_thumb.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';

class CourseDetailScreen extends StatefulWidget {
  /// The summary from the list; the full course (with schedules) is loaded here.
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _courses = CourseService();
  final _enrollments = EnrollmentService();

  late Future<Course> _future;
  int? _enrollingId;

  @override
  void initState() {
    super.initState();
    _future = _courses.fetchCourse(widget.course.id);
  }

  void _reload() {
    setState(() => _future = _courses.fetchCourse(widget.course.id));
  }

  Future<void> _enroll(Course course, Schedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm enrollment'),
        content: Text(
          '${course.title}\n'
          '${schedule.shiftLabel} · ${schedule.daysText}\n'
          '${schedule.timeText}\n\n'
          'Staff will review your request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Enroll'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final myEnrollments = context.read<EnrollmentsProvider>();
    setState(() => _enrollingId = schedule.id);

    try {
      await _enrollments.enroll(schedule.id);
      myEnrollments.load(); // keep the Enrollments tab up to date
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Enrollment submitted. Waiting for staff approval.'),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _enrollingId = null;
      _future = _courses.fetchCourse(widget.course.id); // refresh seat counts
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Course details')),
      body: FutureBuilder<Course>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final err = snapshot.error;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ErrorBanner(
                      err is ApiException
                          ? err.message
                          : 'Could not load this course.',
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildContent(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Course course) {
    final theme = Theme.of(context);
    final accent = AppColors.accentFor(course.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _hero(context, course, accent),
        const SizedBox(height: 24),
        Text(
          'About this course',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              course.description.isEmpty
                  ? 'No description yet.'
                  : course.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Choose a schedule',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${course.schedules.length} available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (course.schedules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No schedules are open for this course yet.'),
          )
        else
          for (final s in course.schedules) _scheduleCard(context, course, s),
      ],
    );
  }

  Widget _hero(BuildContext context, Course course, Color accent) {
    final theme = Theme.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -40,
            top: -40,
            child: DecorBubble(size: 170, opacity: 0.14),
          ),
          const Positioned(
            left: -30,
            bottom: -50,
            child: DecorBubble(size: 130, opacity: 0.10),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.thumbnailUrl != null) ...[
                  CourseThumb(
                    category: course.category,
                    url: course.thumbnailUrl,
                    width: double.infinity,
                    height: 150,
                    accent: accent,
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        course.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        course.isEnglish ? Icons.translate : Icons.computer,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _HeroTag(course.isEnglish ? 'English' : 'Computer'),
                    _HeroTag(course.level),
                    _HeroTag(course.durationText),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      course.feeText,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        'per course',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(BuildContext context, Course course, Schedule s) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enrolling = _enrollingId == s.id;

    final (shiftIcon, shiftColor) = switch (s.shift) {
      'morning' => (Icons.wb_sunny_rounded, AppColors.sun),
      'afternoon' => (Icons.wb_twilight_rounded, AppColors.violet),
      _ => (Icons.nights_stay_rounded, AppColors.primary),
    };

    final ratio = s.maxCapacity > 0
        ? (s.seatsTaken / s.maxCapacity).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final seatColor = s.isFull
        ? scheme.error
        : ratio >= 0.8
        ? AppColors.sun
        : scheme.tertiary;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: shiftColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(shiftIcon, color: shiftColor),
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
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _info(Icons.person_outline, s.teacherName),
                _info(Icons.meeting_room_outlined, 'Room ${s.roomNumber}'),
              ],
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            FilledButton(
              onPressed: (s.isFull || _enrollingId != null)
                  ? null
                  : () => _enroll(course, s),
              child: enrolling
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(s.isFull ? 'Full' : 'Enroll now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
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

class _HeroTag extends StatelessWidget {
  final String text;

  const _HeroTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
