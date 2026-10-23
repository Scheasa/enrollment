import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/payment_style.dart';
import '../../models/payment.dart';
import '../../services/payment_review_service.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/receipt_viewer.dart';

class PaymentReviewScreen extends StatefulWidget {
  final Payment payment;

  const PaymentReviewScreen({super.key, required this.payment});

  @override
  State<PaymentReviewScreen> createState() => _PaymentReviewScreenState();
}

class _PaymentReviewScreenState extends State<PaymentReviewScreen> {
  final _service = PaymentReviewService();

  bool _busy = false;
  String? _error;

  Payment get _p => widget.payment;

  Future<void> _verify() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify this payment?'),
        content: Text(
          '${money(_p.amount)} from ${_p.studentName ?? 'the student'}. '
          'If their enrollment is still pending, it will be approved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    await _run(() => _service.verify(_p.id), 'Payment verified.');
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );

    if (reason == null || !mounted) return;
    await _run(() => _service.reject(_p.id, reason), 'Payment rejected.');
  }

  Future<void> _run(Future<void> Function() action, String doneMessage) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await action();
      if (!mounted) return;
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
    } on ApiException catch (e) {
      // e.g. 409: another staff member already reviewed it
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = paymentStatusStyle(_p.status);
    final method = paymentMethodStyle(_p.method);
    final pending = _p.status == 'pending';

    return GradientScaffold(
      appBar: AppBar(title: const Text('Review payment')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    ErrorBanner(_error!),
                    const SizedBox(height: 16),
                  ],
                  _receipt(context),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  money(_p.amount),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: status.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      status.icon,
                                      size: 16,
                                      color: status.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status.label,
                                      style: TextStyle(
                                        color: status.color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          _row('Student', _p.studentName ?? '-'),
                          if (_p.studentEmail != null)
                            _row('Email', _p.studentEmail!),
                          _row('Course', _p.courseTitle ?? '-'),
                          _row('Method', method.label),
                          _row('Date', _p.dateText),
                          if (_p.verifierName != null)
                            _row('Reviewed by', _p.verifierName!),
                        ],
                      ),
                    ),
                  ),
                  if (pending) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _busy ? null : _verify,
                      icon: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Verify payment'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _reject,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _receipt(BuildContext context) {
    final url = _p.receiptUrl;

    if (url == null) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.mint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Cash payment, no receipt image'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => showReceiptViewer(context, url),
        child: Container(
          height: 300,
          color: Colors.white,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, _, _) =>
                const Center(child: Text('Could not load the receipt image.')),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for the reason shown to the student. Pops the text, or null on cancel.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please give a reason');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject this payment?'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLength: 500,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Reason (the student will see this)',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Reject')),
      ],
    );
  }
}
