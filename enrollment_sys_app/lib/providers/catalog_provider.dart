import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/announcement.dart';
import '../models/course.dart';
import '../services/course_service.dart';

class CatalogProvider extends ChangeNotifier {
  final CourseService _service = CourseService();

  List<Course> _courses = [];
  List<Announcement> _announcements = [];
  String? _category; // null = all
  String _search = '';
  bool _loading = false;
  String? _error;
  int _requestId = 0; // ignores slow, outdated responses

  List<Course> get courses => _courses;
  List<Announcement> get announcements => _announcements;
  String? get category => _category;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> refresh() => Future.wait([_loadAnnouncements(), _loadCourses()]);

  Future<void> setCategory(String? category) {
    _category = category;
    return _loadCourses();
  }

  Future<void> setSearch(String search) {
    if (search == _search) return Future.value();
    _search = search;
    return _loadCourses();
  }

  Future<void> _loadCourses() async {
    final id = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.fetchCourses(
        category: _category,
        search: _search,
      );
      if (id != _requestId) return;
      _courses = result;
    } on ApiException catch (e) {
      if (id != _requestId) return;
      _error = e.message;
    } catch (_) {
      if (id != _requestId) return;
      _error = 'Could not load courses.';
    }

    _loading = false;
    notifyListeners();
  }

  /// Announcements are a bonus: if they fail, the course list still works.
  Future<void> _loadAnnouncements() async {
    try {
      _announcements = await _service.fetchAnnouncements();
      notifyListeners();
    } catch (_) {}
  }
}
