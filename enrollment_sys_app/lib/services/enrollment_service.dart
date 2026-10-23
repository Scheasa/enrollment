import '../core/api_client.dart';
import '../models/enrollment.dart';

class EnrollmentService {
  final ApiClient _api = ApiClient.instance;

  /// Throws ApiException with the server's message when the schedule is full
  /// (409), the student is already enrolled in the course (409), and so on.
  Future<void> enroll(int scheduleId) async {
    await _api.post('/enrollments', body: {'schedule_id': scheduleId});
  }

  Future<List<Enrollment>> fetchMine() async {
    final res = await _api.get('/enrollments');
    return (res['data'] as List)
        .map((e) => Enrollment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> drop(int id) async {
    await _api.post('/enrollments/$id/drop');
  }
}
