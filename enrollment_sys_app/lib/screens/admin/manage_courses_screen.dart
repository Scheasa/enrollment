import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/course.dart';
import '../../providers/manage_courses_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/course_card.dart' show Tag;
import '../../widgets/course_thumb.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';
import 'course_form_screen.dart';
import 'manage_schedules_screen.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ManageCoursesProvider>().load(reset: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm([Course? course]) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CourseFormScreen(course: course)));
  }

  Future<void> _toggle(Course c) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<ManageCoursesProvider>().setActive(
      c,
      !c.isActive,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (c.isActive
                  ? 'Course hidden from students.'
                  : 'Course is visible to students.'),
        ),
      ),
    );
  }

  Future<void> _delete(Course c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this course?'),
        content: Text(
          '"${c.title}" will be deleted. If it already has enrollments, '
          'it will be hidden instead so student history is kept.',
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
    final result = await context.read<ManageCoursesProvider>().remove(c);

    messenger.showSnackBar(
      SnackBar(content: Text(result.error ?? result.message ?? 'Done.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManageCoursesProvider>();
    final items = provider.items;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Courses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New course'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ManageCoursesProvider>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                context.read<ManageCoursesProvider>().setSearch(v);
                setState(() {}); // show/hide the clear button
              },
              decoration: InputDecoration(
                hintText: 'Search courses',
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<ManageCoursesProvider>().setSearch('');
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
                  CategoryChip(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    selected: provider.status == 'all',
                    onTap: () =>
                        context.read<ManageCoursesProvider>().setStatus('all'),
                  ),
                  const SizedBox(width: 10),
                  CategoryChip(
                    label: 'Active',
                    icon: Icons.visibility_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                    selected: provider.status == 'active',
                    onTap: () => context
                        .read<ManageCoursesProvider>()
                        .setStatus('active'),
                  ),
                  const SizedBox(width: 10),
                  CategoryChip(
                    label: 'Hidden',
                    icon: Icons.visibility_off_outlined,
                    color: AppColors.muted,
                    selected: provider.status == 'hidden',
                    onTap: () => context
                        .read<ManageCoursesProvider>()
                        .setStatus('hidden'),
                  ),
                ],
              ),
            ),
            if (provider.error != null) ...[
              ErrorBanner(provider.error!),
              TextButton.icon(
                onPressed: () => context.read<ManageCoursesProvider>().load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ] else if (provider.isLoading && provider.total == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text('No courses found.')),
              )
            else
              for (final c in items) _card(context, c),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Course c) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openForm(c),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            children: [
              Opacity(
                opacity: c.isActive ? 1 : 0.5,
                child: CourseThumb(
                  category: c.category,
                  url: c.thumbnailUrl,
                  width: 60,
                  height: 60,
                  accent: AppColors.accentFor(c.id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Tag(c.level),
                        Tag(c.feeText),
                        Tag('${c.schedulesCount ?? 0} schedules'),
                        if (!c.isActive) const _HiddenBadge(),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      _openForm(c);
                    case 'schedules':
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => ManageSchedulesScreen(course: c),
                            ),
                          )
                          .then((_) {
                            // schedule counts may have changed
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              context.read<ManageCoursesProvider>().load();
                            }
                          });
                    case 'toggle':
                      _toggle(c);
                    case 'delete':
                      _delete(c);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'schedules',
                    child: Text('Manage schedules'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      c.isActive ? 'Hide from students' : 'Show to students',
                    ),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenBadge extends StatelessWidget {
  const _HiddenBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Hidden',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
