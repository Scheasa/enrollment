import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';

class PaymentService {
  final ApiClient _api = ApiClient.instance;

  /// POST /payments (multipart). Returns the server's message.
  /// Throws ApiException, e.g. "Amount exceeds the remaining balance of $20.00."
  Future<String> submit({
    required int enrollmentId,
    required double amount,
    required String method,
    XFile? receipt,
  }) async {
    final bytes = receipt == null ? null : await receipt.readAsBytes();

    final res = await _api.postMultipart(
      '/payments',
      fields: {
        'enrollment_id': '$enrollmentId',
        'amount': amount.toStringAsFixed(2),
        'payment_method': method,
      },
      fileField: receipt == null ? null : 'receipt_image',
      fileBytes: bytes,
      fileName: receipt?.name,
    );

    return (res['message'] ?? 'Payment submitted.') as String;
  }
}
