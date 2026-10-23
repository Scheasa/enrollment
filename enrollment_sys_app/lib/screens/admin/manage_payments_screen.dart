import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/payment_style.dart';
import '../../models/payment.dart';
import '../../services/payment_review_service.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';
import 'payment_review_screen.dart';

class ManagePaymentsScreen extends StatefulWidget {
  /// Which filter to open on: pending | verified | rejected.
  final String initialStatus;

  const ManagePaymentsScreen({super.key, this.initialStatus = 'pending'});

  @override
  State<ManagePaymentsScreen> createState() => _ManagePaymentsScreenState();
}

class _ManagePaymentsScreenState extends State<ManagePaymentsScreen> {
  final _service = PaymentReviewService();

  List<Payment> _items = [];
  String? _status = 'pending'; // null = all
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _requestId = 0; // ignores answers from out-of-date requests

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _load();
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
      final res = await _service.fetch(status: _status, page: target);
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
        _error = 'Could not load payments.';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _setStatus(String? status) {
    if (_status == status) return;
    _status = status;
    _load();
  }

  Future<void> _open(Payment p) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentReviewScreen(payment: p)),
    );
    if (changed == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
            child: Row(
              children: [
                for (final s in const ['pending', 'verified', 'rejected']) ...[
                  CategoryChip(
                    label: paymentStatusStyle(s).label,
                    icon: paymentStatusStyle(s).icon,
                    color: paymentStatusStyle(s).color,
                    selected: _status == s,
                    onTap: () => _setStatus(s),
                  ),
                  const SizedBox(width: 10),
                ],
                CategoryChip(
                  label: 'All',
                  icon: Icons.apps_rounded,
                  color: AppColors.primary,
                  selected: _status == null,
                  onTap: () => _setStatus(null),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              _status == 'pending'
                  ? 'Nothing waiting for review.'
                  : 'No payments here.',
            ),
          ),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          '$_total ${_total == 1 ? 'payment' : 'payments'}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ),
      for (final p in _items) _card(context, p),
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

  Widget _card(BuildContext context, Payment p) {
    final theme = Theme.of(context);
    final status = paymentStatusStyle(p.status);
    final method = paymentMethodStyle(p.method);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
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
                      p.studentName ?? 'Student',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      p.courseTitle ?? 'Course',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${method.label} · ${p.dateText}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(p.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
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
