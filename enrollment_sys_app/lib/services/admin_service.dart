import '../core/api_client.dart';
import '../models/dashboard_stats.dart';
import '../models/enrollment.dart';

class AdminService {
  final ApiClient _api = ApiClient.instance;

  Future<DashboardStats> fetchDashboard() async {
    final res = await _api.get('/admin/dashboard');
    return DashboardStats.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<({List<Enrollment> items, int lastPage})> fetchEnrollments({
    String? status,
    String? search,
    int page = 1,
  }) async {
    final res = await _api.get(
      '/admin/enrollments',
      query: {
        'status': ?status,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': '$page',
        'per_page': '20',
      },
    );

    final items = (res['data'] as List)
        .map((e) => Enrollment.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = (res['meta'] as Map?) ?? const {};

    return (items: items, lastPage: (meta['last_page'] as num?)?.toInt() ?? 1);
  }

  Future<Enrollment> approve(int id, {String? remarks}) async {
    final res = await _api.post(
      '/admin/enrollments/$id/approve',
      body: {if (remarks != null && remarks.isNotEmpty) 'remarks': remarks},
    );
    return Enrollment.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Enrollment> reject(int id, String remarks) async {
    final res = await _api.post(
      '/admin/enrollments/$id/reject',
      body: {'remarks': remarks},
    );
    return Enrollment.fromJson(res['data'] as Map<String, dynamic>);
  }
}
