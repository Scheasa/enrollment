import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/managed_announcement.dart';

class AnnouncementManageService {
  final ApiClient _api = ApiClient.instance;

  /// GET /admin/announcements (includes hidden ones)
  Future<List<ManagedAnnouncement>> fetchAll() async {
    final res = await _api.get('/admin/announcements');
    return (res['data'] as List)
        .map((e) => ManagedAnnouncement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates an announcement, or updates it when [id] is given.
  /// Always sent as multipart so the image can be attached.
  Future<void> save({
    int? id,
    required String title,
    required String content,
    required bool isActive,
    XFile? image,
  }) async {
    final bytes = image == null ? null : await image.readAsBytes();

    await _api.postMultipart(
      id == null ? '/admin/announcements' : '/admin/announcements/$id',
      fields: {
        'title': title,
        'content': content,
        'is_active': isActive ? '1' : '0',
      },
      fileField: image == null ? null : 'image',
      fileBytes: bytes,
      fileName: image?.name,
    );
  }

  Future<void> setActive(int id, bool active) async {
    await _api.post('/admin/announcements/$id', body: {'is_active': active});
  }

  Future<void> delete(int id) async {
    await _api.delete('/admin/announcements/$id');
  }
}
