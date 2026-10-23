import '../core/api_client.dart';
import '../models/announcement.dart';
import '../models/course.dart';

class CourseService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Course>> fetchCourses({String? category, String? search}) async {
    final query = <String, String>{
      'category': ?category,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _api.get('/courses', query: query);
    return (res['data'] as List)
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Course with all its schedules and seat counts.
  Future<Course> fetchCourse(int id) async {
    final res = await _api.get('/courses/$id');
    return Course.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<List<Announcement>> fetchAnnouncements() async {
    final res = await _api.get('/announcements');
    return (res['data'] as List)
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
