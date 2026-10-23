import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/enrollment.dart';
import '../services/enrollment_service.dart';

class EnrollmentsProvider extends ChangeNotifier {
  final EnrollmentService _service = EnrollmentService();

  List<Enrollment> _items = [];
  bool _loading = false;
  String? _error;

  List<Enrollment> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;

  /// [reset] clears the old list first, so a different user never sees
  /// the previous user's enrollments while loading.
  Future<void> load({bool reset = false}) async {
    if (reset) _items = [];
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _service.fetchMine();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load your enrollments.';
    }

    _loading = false;
    notifyListeners();
  }

  /// Returns null on success, or an error message to show.
  Future<String?> drop(int id) async {
    try {
      await _service.drop(id);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }
}
