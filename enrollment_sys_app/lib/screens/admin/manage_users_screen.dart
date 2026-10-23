import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/role_style.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_manage_service.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';
import 'user_form_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _service = UserManageService();

  List<User> _items = [];
  String? _role; // null = all roles
  String _search = '';
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  Timer? _debounce;
  int _requestId = 0; // ignores answers from out-of-date requests

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    final id = ++_requestId;
    final target = reset ? 1 : _page + 1;

    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final res = await _service.fetch(
        role: _role,
        search: _search.trim(),
        page: target,
      );
      if (!mounted || id != _requestId) return;

      setState(() {
        _items = reset ? res.items : [..._items, ...res.items];
        _page = target;
        _lastPage = res.lastPage;
        _total = res.total;
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = 'Could not load users.';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value;
      _load();
    });
  }

  void _setRole(String? role) {
    if (_role == role) return;
    _role = role;
    _load();
  }

  /// Opens the form: a new user when [user] is null, otherwise edit [user].
  Future<void> _openForm([User? user]) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => UserFormScreen(user: user)));
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(User u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this user?'),
        content: Text('${u.name} (${u.email}) will be removed for good.'),
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
      await _service.delete(u.id);
      messenger.showSnackBar(const SnackBar(content: Text('User deleted.')));
      _load();
    } on ApiException catch (e) {
      // e.g. 409: this user has enrollment history
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
    return GradientScaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New user'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: TextField(
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                CategoryChip(
                  label: 'All',
                  icon: Icons.groups_rounded,
                  color: AppColors.primary,
                  selected: _role == null,
                  onTap: () => _setRole(null),
                ),
                for (final r in const ['student', 'staff', 'admin']) ...[
                  const SizedBox(width: 10),
                  CategoryChip(
                    label: roleStyle(r).label,
                    icon: roleStyle(r).icon,
                    color: roleStyle(r).color,
                    selected: _role == r,
                    onTap: () => _setRole(r),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: _listChildren(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _listChildren(BuildContext context) {
    if (_error != null) {
      return [
        ErrorBanner(_error!),
        TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ];
    }

    if (_loading && _items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: Text('No users match your search.')),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          '$_total ${_total == 1 ? 'user' : 'users'}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ),
      for (final u in _items) _tile(context, u),
      if (_page < _lastPage)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Center(
            child: _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                : OutlinedButton(
                    onPressed: () => _load(reset: false),
                    child: const Text('Load more'),
                  ),
          ),
        ),
    ];
  }

  Widget _tile(BuildContext context, User u) {
    final theme = Theme.of(context);
    final style = roleStyle(u.role);
    final hasPhone = u.phone?.isNotEmpty == true;
    final isSelf = context.read<AuthProvider>().user?.id == u.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openForm(u),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            children: [
              _Avatar(user: u, color: style.color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      u.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    if (hasPhone)
                      Text(
                        u.phone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: style.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            style.label,
                            style: TextStyle(
                              color: style.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 8),
                          Text(
                            'You',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      _openForm(u);
                    case 'delete':
                      _delete(u);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  // you cannot delete your own account
                  if (!isSelf)
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

class _Avatar extends StatelessWidget {
  final User user;
  final Color color;

  const _Avatar({required this.user, required this.color});

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim()[0].toUpperCase();

    final fallback = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      color: color.withValues(alpha: 0.18),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );

    final url = user.profileImageUrl;

    return ClipOval(
      child: SizedBox(
        width: 48,
        height: 48,
        child: (url == null || url.isEmpty)
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
