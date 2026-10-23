import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/course.dart';

class CourseManageService {
  final ApiClient _api = ApiClient.instance;

  /// All courses, including hidden ones.
  Future<List<Course>> fetchAll() async {
    final res = await _api.get('/admin/courses');
    return (res['data'] as List)
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a course, or updates it when [id] is given.
  Future<Course> save({
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
    final bytes = image == null ? null : await image.readAsBytes();

    final res = await _api.postMultipart(
      id == null ? '/admin/courses' : '/admin/courses/$id',
      fields: {
        'title': title,
        'description': description,
        'category': category,
        'level': level,
        'fee': fee,
        'duration_months': durationMonths,
        'is_active': isActive ? '1' : '0',
      },
      fileField: image == null ? null : 'thumbnail_image',
      fileBytes: bytes,
      fileName: image?.name,
    );

    return Course.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> setActive(int id, bool active) async {
    await _api.post('/admin/courses/$id', body: {'is_active': active});
  }

  /// A course with enrollments is hidden instead of deleted ([hidden] = true).
  Future<({String message, bool hidden})> delete(int id) async {
    final res = await _api.delete('/admin/courses/$id');
    return (
      message: (res['message'] ?? '') as String,
      hidden: (res['hidden'] as bool?) ?? false,
    );
  }
}
