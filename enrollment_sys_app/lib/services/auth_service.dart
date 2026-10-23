import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _api = ApiClient.instance;

  Future<User> login(String email, String password) async {
    final res = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    await _api.setToken(res['token'] as String?);
    return User.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await _api.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    await _api.setToken(res['token'] as String?);
    return User.fromJson(res['user'] as Map<String, dynamic>);
  }
}
