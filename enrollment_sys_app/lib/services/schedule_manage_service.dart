import '../core/api_client.dart';
import '../models/schedule.dart';

class ScheduleManageService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Schedule>> fetch(int courseId) async {
    final res = await _api.get(
      '/admin/schedules',
      query: {'course_id': courseId},
    );
    return (res['data'] as List)
        .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a schedule, or updates it when [id] is given.
  /// Times are "HH:mm" strings. Throws ApiException with the server's message.
  Future<void> save({
    int? id,
    required int courseId,
    required String teacher,
    required String room,
    required String shift,
    required List<String> days,
    required String start,
    required String end,
    required int capacity,
  }) async {
    await _api.post(
      id == null ? '/admin/schedules' : '/admin/schedules/$id',
      body: {
        'course_id': courseId,
        'teacher_name': teacher,
        'room_number': room,
        'shift': shift,
        'days': days,
        'start_time': start,
        'end_time': end,
        'max_capacity': capacity,
      },
    );
  }

  Future<void> delete(int id) async {
    await _api.delete('/admin/schedules/$id');
  }
}
