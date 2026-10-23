import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';
import 'constants.dart';

/// The one place that talks to the Laravel API.
///  - sends the Sanctum token as "Authorization: Bearer "
///  - turns every failure into an [ApiException] with a readable message
///  - tells the app (via [onUnauthorized]) when the server rejects our token
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'auth_token';

  String? _token;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Called when the server answers 401 while we hold a token
  /// (expired, revoked, or the account was deleted). AuthProvider logs out.
  void Function()? onUnauthorized;

  /// Reads the saved token. Call once at app start, before the first request.
  Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
    } catch (_) {
      _token = null;
    }
  }

  /// Saves the token after login/register, or clears it when [token] is null.
  Future<void> setToken(String? token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_tokenKey, token);
      }
    } catch (_) {
      // storage unavailable: the token still works for this session
    }
  }

  Map<String, String> _headers({bool json = false}) => {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    if (hasToken) 'Authorization': 'Bearer $_token',
  };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null && '$value'.isNotEmpty) params[key] = '$value';
    });
    return Uri.parse(
      '${AppConstants.baseUrl}$path',
    ).replace(queryParameters: params.isEmpty ? null : params);
  }

  /// POST with form fields and one optional file (for photo uploads).
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    String? fileField,
    List<int>? fileBytes,
    String? fileName,
  }) {
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers())
      ..fields.addAll(fields ?? {});

    if (fileField != null && fileBytes != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: (fileName == null || fileName.isEmpty)
              ? 'photo.jpg'
              : fileName,
        ),
      );
    }

    return _handle(req.send().then(http.Response.fromStream));
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) => _handle(http.get(_uri(path, query), headers: _headers()));

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => _handle(
    http.post(
      _uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body ?? {}),
    ),
  );

  Future<Map<String, dynamic>> delete(String path) =>
      _handle(http.delete(_uri(path), headers: _headers()));

  Future<Map<String, dynamic>> _handle(Future<http.Response> request) async {
    // Remember whether this request was sent with a token. A 401 from the
    // login screen ("Invalid email or password") must NOT trigger a logout.
    final hadToken = hasToken;
    http.Response res;

    try {
      res = await request.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException('The server took too long to respond.');
    } catch (_) {
      throw ApiException(
        'Cannot reach the server. Is the API running? '
        '(On web this can also be a CORS problem.)',
      );
    }

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(res.body);
      body = decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } catch (_) {
      throw ApiException(
        'Unexpected response from the server (HTTP ${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    if (res.statusCode == 401 && hadToken) {
      onUnauthorized?.call();
    }

    throw ApiException.fromResponse(res.statusCode, body);
  }
}
