import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/dashboard_stats.dart';
import '../services/admin_service.dart';

class DashboardProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  DashboardStats? _stats;
  bool _loading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load({bool reset = false}) async {
    if (reset) _stats = null;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _service.fetchDashboard();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load the dashboard.';
    }

    _loading = false;
    notifyListeners();
  }
}
