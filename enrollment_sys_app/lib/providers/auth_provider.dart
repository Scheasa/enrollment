import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/local_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  final ProfileService _profile = ProfileService();

  User? _user;
  bool _initialized = false; // finished checking for a saved login
  bool _busy = false;
  String? _error;

  AuthProvider() {
    // If the server rejects our token at any time (expired, revoked, account
    // deleted), drop back to the login screen.
    ApiClient.instance.onUnauthorized = _handleExpiredSession;
  }

  User? get user => _user;
  bool get isInitialized => _initialized;
  bool get isBusy => _busy;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<void> _handleExpiredSession() async {
    if (_user == null) return; // already logged out
    _user = null;
    await ApiClient.instance.setToken(null);
    await LocalStorage.clear();
    _error = 'Your session has ended. Please log in again.';
    notifyListeners();
  }

  /// Runs once at app start: restores the saved login.
  /// The saved token is re-checked with the server (GET /me), so a revoked
  /// token or an account that no longer exists (for example after
  /// migrate:fresh) is logged out cleanly.
  Future<void> restore() async {
    await ApiClient.instance.loadToken();
    final saved = await LocalStorage.loadUser();

    if (saved != null && !ApiClient.instance.hasToken) {
      // Logged in with the old X-User-Id version: no token, so log in again.
      await LocalStorage.clear();
    } else if (saved != null) {
      try {
        final cached = User.fromJson(saved);

        try {
          final res = await ApiClient.instance.get('/me');
          _user = User.fromJson(res['data'] as Map<String, dynamic>);
          await LocalStorage.saveUser(_user!.toJson());
        } on ApiException catch (e) {
          if (e.statusCode == 401) {
            await ApiClient.instance.setToken(null);
            await LocalStorage.clear();
          } else {
            _user = cached; // server unreachable: keep the saved login
          }
        }
      } catch (_) {
        await ApiClient.instance.setToken(null);
        await LocalStorage.clear();
      }
    }

    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _authenticate(() => _service.login(email, password));

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) => _authenticate(
    () => _service.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    ),
  );

  Future<bool> _authenticate(Future<User> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final user = await action();
      _user = user;
      await LocalStorage.saveUser(user.toJson());
      _busy = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    }

    _busy = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    // Start revoking the token on the server. The request captures the token
    // right now, so we don't have to wait for the answer.
    if (ApiClient.instance.hasToken) {
      unawaited(
        ApiClient.instance
            .post('/auth/logout')
            .then((_) {}, onError: (Object _) {}),
      );
    }

    _user = null;
    await ApiClient.instance.setToken(null);
    await LocalStorage.clear();
    notifyListeners();
  }

  /// Returns null on success, or an error message to show.
  Future<String?> updateProfile({
    required String name,
    required String phone,
    XFile? image,
    bool removeImage = false,
  }) async {
    try {
      final updated = await _profile.update(
        name: name,
        phone: phone,
        image: image,
        removeImage: removeImage,
      );
      _user = updated;
      await LocalStorage.saveUser(updated.toJson());
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Returns null on success, or an error message to show.
  Future<String?> changePassword({
    required String current,
    required String password,
  }) async {
    try {
      await _profile.changePassword(
        current: current,
        password: password,
        confirmation: password,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
