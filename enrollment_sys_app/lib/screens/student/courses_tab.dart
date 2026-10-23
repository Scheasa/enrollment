import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/announcement.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/course_card.dart';
import '../../widgets/course_thumb.dart' show DecorBubble;
import '../../widgets/error_banner.dart';
import '../../widgets/user_avatar.dart';
import 'course_detail_screen.dart';

class CoursesTab extends StatefulWidget {
  /// Called when the avatar in the header is tapped.
  final VoidCallback? onOpenProfile;

  const CoursesTab({super.key, this.onOpenProfile});

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  final _searchCtrl = TextEditingController();
  final _coursesKey = GlobalKey();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CatalogProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<CatalogProvider>().setSearch(value.trim());
    });
    setState(() {}); // show/hide the clear button
  }

  void _scrollToCourses() {
    final ctx = _coursesKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _showAnnouncement(Announcement a) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(a.title),
        content: SingleChildScrollView(child: Text(a.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final catalog = context.watch<CatalogProvider>();
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => context.read<CatalogProvider>().refresh(),
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
                      'Hello,',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.waving_hand_rounded,
                          color: AppColors.sun,
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onOpenProfile,
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

          // ---- Search ----
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search courses',
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _debounce?.cancel();
                        context.read<CatalogProvider>().setSearch('');
                        setState(() {});
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Category chips ----
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CategoryChip(
                label: 'All',
                icon: Icons.apps_rounded,
                color: AppColors.primary,
                selected: catalog.category == null,
                onTap: () => context.read<CatalogProvider>().setCategory(null),
              ),
              CategoryChip(
                label: 'Computer',
                icon: Icons.computer,
                color: AppColors.violet,
                selected: catalog.category == 'computer',
                onTap: () =>
                    context.read<CatalogProvider>().setCategory('computer'),
              ),
              CategoryChip(
                label: 'English',
                icon: Icons.translate,
                color: AppColors.sun,
                selected: catalog.category == 'english',
                onTap: () =>
                    context.read<CatalogProvider>().setCategory('english'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---- Banner ----
          _FindCourseBanner(onPressed: _scrollToCourses),

          // ---- Announcements ----
          if (catalog.announcements.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Announcements',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: catalog.announcements.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, i) =>
                    _announcementCard(context, catalog.announcements[i]),
              ),
            ),
          ],

          // ---- Courses ----
          const SizedBox(height: 24),
          Row(
            key: _coursesKey,
            children: [
              Text(
                'Courses',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (!catalog.isLoading && catalog.courses.isNotEmpty)
                Text(
                  '${catalog.courses.length} available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (catalog.error != null) ...[
            ErrorBanner(catalog.error!),
            TextButton.icon(
              onPressed: () => context.read<CatalogProvider>().refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ] else if (catalog.isLoading && catalog.courses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (catalog.courses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No courses found.')),
            )
          else
            for (final course in catalog.courses)
              CourseCard(
                course: course,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(course: course),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _announcementCard(BuildContext context, Announcement a) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 260,
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _showAnnouncement(a),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sun.withValues(alpha: 0.18),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        size: 20,
                        color: AppColors.sun,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    a.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FindCourseBanner extends StatelessWidget {
  final VoidCallback onPressed;

  const _FindCourseBanner({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sky, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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
            child: DecorBubble(size: 150, opacity: 0.14),
          ),
          const Positioned(
            right: 70,
            bottom: -40,
            child: DecorBubble(size: 90, opacity: 0.10),
          ),
          Positioned(
            right: 18,
            bottom: 14,
            child: Icon(
              Icons.school_rounded,
              size: 88,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 90),
                  child: Text(
                    'Find a course you\nwant to learn!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: onPressed,
                  child: const Text('Browse courses'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
