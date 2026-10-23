import '../core/api_client.dart';
import '../models/user.dart';

class UserManageService {
  final ApiClient _api = ApiClient.instance;

  /// GET /admin/users?role=&search=&page=&per_page=
  Future<({List<User> items, int lastPage, int total})> fetch({
    String? role,
    String? search,
    int page = 1,
  }) async {
    final res = await _api.get(
      '/admin/users',
      query: {'role': role, 'search': search, 'page': page, 'per_page': 20},
    );

    final items = (res['data'] as List)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = (res['meta'] ?? {}) as Map<String, dynamic>;

    return (
      items: items,
      lastPage: (meta['last_page'] ?? 1) as int,
      total: (meta['total'] ?? items.length) as int,
    );
  }

  /// POST /admin/users. Throws ApiException (e.g. "email already taken").
  Future<void> create({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    await _api.post(
      '/admin/users',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  /// POST /admin/users/{id}. A non-empty [password] resets it and signs the
  /// user out of every device.
  Future<void> update({
    required int id,
    required String name,
    required String email,
    required String phone,
    required String role,
    String? password,
  }) async {
    await _api.post(
      '/admin/users/$id',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
  }

  /// DELETE /admin/users/{id}. Throws ApiException with the server's reason,
  /// e.g. "This user has enrollment history and cannot be deleted."
  Future<void> delete(int id) async {
    await _api.delete('/admin/users/$id');
  }
}
