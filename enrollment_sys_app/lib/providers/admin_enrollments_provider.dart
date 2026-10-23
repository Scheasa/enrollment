import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/enrollment.dart';
import '../services/admin_service.dart';

class AdminEnrollmentsProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  List<Enrollment> _items = [];
  String? _status = 'pending'; // null = all
  String _search = '';
  int _page = 1;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _requestId = 0;

  List<Enrollment> get items => _items;
  String? get status => _status;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _page < _lastPage;
  String? get error => _error;

  /// [reset] also clears the filter, so a new login starts clean.
  Future<void> load({bool reset = false}) async {
    final id = ++_requestId;
    if (reset) {
      _items = [];
      _status = 'pending';
      _search = '';
    }
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final r = await _service.fetchEnrollments(
        status: _status,
        search: _search,
      );
      if (id != _requestId) return;
      _items = r.items;
      _page = 1;
      _lastPage = r.lastPage;
    } on ApiException catch (e) {
      if (id != _requestId) return;
      _error = e.message;
    } catch (_) {
      if (id != _requestId) return;
      _error = 'Could not load enrollments.';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMore || _loading || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final r = await _service.fetchEnrollments(
        status: _status,
        search: _search,
        page: _page + 1,
      );
      _items = [..._items, ...r.items];
      _page += 1;
      _lastPage = r.lastPage;
    } catch (_) {
      // Keep what we have; the button stays so the user can retry.
    }

    _loadingMore = false;
    notifyListeners();
  }

  Future<void> setStatus(String? status) {
    _status = status;
    return load();
  }

  Future<void> setSearch(String search) {
    if (search == _search) return Future.value();
    _search = search;
    return load();
  }

  /// Both return null on success, or an error message to show.
  Future<String?> approve(int id, {String? remarks}) =>
      _act(() => _service.approve(id, remarks: remarks));

  Future<String?> reject(int id, String remarks) =>
      _act(() => _service.reject(id, remarks));

  Future<String?> _act(Future<Enrollment> Function() call) async {
    try {
      final updated = await call();
      final i = _items.indexWhere((e) => e.id == updated.id);
      if (i >= 0) {
        if (_status == null || updated.status == _status) {
          _items[i] = updated;
        } else {
          _items.removeAt(i); // no longer matches the current filter
        }
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 409) load(); // someone else changed it: refresh
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }
}
