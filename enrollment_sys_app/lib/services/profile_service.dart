import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/user.dart';

class ProfileService {
  final ApiClient _api = ApiClient.instance;

  Future<User> update({
    required String name,
    required String phone,
    XFile? image,
    bool removeImage = false,
  }) async {
    final bytes = image == null ? null : await image.readAsBytes();

    final res = await _api.postMultipart(
      '/me',
      fields: {
        'name': name,
        'phone': phone,
        if (removeImage && image == null) 'remove_image': '1',
      },
      fileField: image == null ? null : 'image',
      fileBytes: bytes,
      fileName: image?.name,
    );

    return User.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String current,
    required String password,
    required String confirmation,
  }) async {
    await _api.post(
      '/me/password',
      body: {
        'current_password': current,
        'password': password,
        'password_confirmation': confirmation,
      },
    );
  }
}
