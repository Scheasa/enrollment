import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../models/course.dart';
import '../services/course_manage_service.dart';

class ManageCoursesProvider extends ChangeNotifier {
  final CourseManageService _service = CourseManageService();

  List<Course> _all = [];
  bool _loading = false;
  String? _error;
  String _status = 'all'; // all | active | hidden
  String _search = '';

  bool get isLoading => _loading;
  String? get error => _error;
  String get status => _status;
  int get total => _all.length;

  /// The list after the status chip and the search box are applied.
  List<Course> get items {
    final q = _search.toLowerCase();
    return _all.where((c) {
      final okStatus = switch (_status) {
        'active' => c.isActive,
        'hidden' => !c.isActive,
        _ => true,
      };
      final okSearch = q.isEmpty || c.title.toLowerCase().contains(q);
      return okStatus && okSearch;
    }).toList();
  }

  /// [reset] clears the list and filters, so a new login starts clean.
  Future<void> load({bool reset = false}) async {
    if (reset) {
      _all = [];
      _status = 'all';
      _search = '';
    }
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _all = await _service.fetchAll();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load courses.';
    }

    _loading = false;
    notifyListeners();
  }

  void setStatus(String status) {
    _status = status;
    notifyListeners();
  }

  void setSearch(String search) {
    _search = search.trim();
    notifyListeners();
  }

  /// All three return null on success, or an error message to show.
  Future<String?> save({
    int? id,
    required String title,
    required String description,
    required String category,
    required String level,
    required String fee,
    required String durationMonths,
    required bool isActive,
    XFile? image,
  }) async {
    try {
      await _service.save(
        id: id,
        title: title,
        description: description,
        category: category,
        level: level,
        fee: fee,
        durationMonths: durationMonths,
        isActive: isActive,
        image: image,
      );
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> setActive(Course course, bool active) async {
    try {
      await _service.setActive(course.id, active);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Returns the server's message ("Course deleted." or "...hidden instead...").
  Future<({String? error, String? message})> remove(Course course) async {
    try {
      final r = await _service.delete(course.id);
      await load();
      return (error: null, message: r.message);
    } on ApiException catch (e) {
      return (error: e.message, message: null);
    } catch (_) {
      return (error: 'Something went wrong. Please try again.', message: null);
    }
  }
}
