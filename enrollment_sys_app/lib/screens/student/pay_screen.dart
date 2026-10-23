import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/payment_style.dart';
import '../../models/enrollment.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';

class PayScreen extends StatefulWidget {
  final Enrollment enrollment;

  const PayScreen({super.key, required this.enrollment});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  static const _methods = ['aba', 'acleda', 'wing', 'cash'];
  static const _maxImageBytes = 5 * 1024 * 1024; // matches the server's 5 MB

  /// Put the school's real account details here (shown to the student).
  /// Leave a value empty to hide it. Example: 'aba': 'ABA 000 123 456 (CC Language School)'
  static const _accountInfo = <String, String>{
    'aba': 'ABA 000 123 456 (CC Language School)',
  };

  final _service = PaymentService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;

  String _method = 'aba';
  XFile? _receipt;
  Uint8List? _receiptBytes;

  String? _error;
  bool _saving = false;

  PaymentSummary get _summary => widget.enrollment.paymentSummary!;
  bool get _isCash => _method == 'cash';

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: _summary.remaining.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    if (bytes.length > _maxImageBytes) {
      setState(
        () => _error = 'That image is larger than 5 MB. Pick a smaller one.',
      );
      return;
    }

    setState(() {
      _error = null;
      _receipt = file;
      _receiptBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isCash && _receipt == null) {
      setState(() => _error = 'Please attach a screenshot of your receipt.');
      return;
    }

    FocusScope.of(context).unfocus();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final message = await _service.submit(
        enrollmentId: widget.enrollment.id,
        amount: double.parse(_amountCtrl.text.trim()),
        method: _method,
        receipt: _isCash ? null : _receipt,
      );

      if (!mounted) return;
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(content: Text(message)));
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
    final s = _summary;
    final account = _accountInfo[_method] ?? '';

    return GradientScaffold(
      appBar: AppBar(title: const Text('Make a payment')),
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
                      widget.enrollment.course?.title ?? 'Course',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _row('Course fee', money(s.fee)),
                            _row('Paid', money(s.verified)),
                            if (s.pending > 0)
                              _row('Waiting for review', money(s.pending)),
                            const Divider(height: 20),
                            _row('Balance', money(s.remaining), bold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      ErrorBanner(_error!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount (USD)',
                        prefixIcon: const Icon(Icons.attach_money),
                        helperText: 'You can pay part now and the rest later',
                        suffix: TextButton(
                          onPressed: () =>
                              _amountCtrl.text = s.remaining.toStringAsFixed(2),
                          child: const Text('Full balance'),
                        ),
                      ),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Enter an amount';
                        if (n > s.remaining + 0.001) {
                          return 'The most you can pay is ${money(s.remaining)}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('Payment method', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final m in _methods)
                          CategoryChip(
                            label: paymentMethodStyle(m).label,
                            icon: paymentMethodStyle(m).icon,
                            color: paymentMethodStyle(m).color,
                            selected: _method == m,
                            onTap: () => setState(() {
                              _method = m;
                              _error = null;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCash
                                ? 'Pay at the school office. Staff will confirm '
                                      'your payment once they receive the cash.'
                                : 'Transfer the amount with '
                                      '${paymentMethodStyle(_method).label}, then attach '
                                      'a screenshot of the receipt. Staff will check it '
                                      'and confirm your payment.',
                          ),
                          if (account.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SelectableText(
                              account,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!_isCash) ...[
                      const SizedBox(height: 16),
                      _receiptArea(),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isCash ? 'Submit cash payment' : 'Send receipt',
                            ),
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

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _receiptArea() {
    final placeholder = Container(
      color: AppColors.sky.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.sky),
          SizedBox(height: 6),
          Text('Attach your receipt', style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: _saving ? null : _pickReceipt,
            child: SizedBox(
              height: 200,
              child: _receiptBytes == null
                  ? placeholder
                  : Image.memory(_receiptBytes!, fit: BoxFit.cover),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _saving ? null : _pickReceipt,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              _receiptBytes == null ? 'Choose image' : 'Change image',
            ),
          ),
        ),
      ],
    );
  }
}
