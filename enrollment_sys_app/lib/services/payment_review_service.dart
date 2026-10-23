import '../core/api_client.dart';
import '../models/payment.dart';

class PaymentReviewService {
  final ApiClient _api = ApiClient.instance;

  /// GET /admin/payments?status=&page=&per_page=
  Future<({List<Payment> items, int lastPage, int total})> fetch({
    String? status,
    int page = 1,
  }) async {
    final res = await _api.get(
      '/admin/payments',
      query: {'status': status, 'page': page, 'per_page': 20},
    );

    final items = (res['data'] as List)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = (res['meta'] ?? {}) as Map<String, dynamic>;

    return (
      items: items,
      lastPage: (meta['last_page'] ?? 1) as int,
      total: (meta['total'] ?? items.length) as int,
    );
  }

  /// POST /admin/payments/{id}/verify. Also approves a pending enrollment.
  Future<void> verify(int id) async {
    await _api.post('/admin/payments/$id/verify');
  }

  /// POST /admin/payments/{id}/reject. The reason is shown to the student.
  Future<void> reject(int id, String remarks) async {
    await _api.post('/admin/payments/$id/reject', body: {'remarks': remarks});
  }
}
