import 'package:taro_mobile/core/services/api_service.dart';
import 'package:taro_mobile/core/models/api_models.dart';

class UserRepository {
  final ApiService _api = ApiService.instance;

  Future<UserModel> getProfile() async {
    final res = await _api.get<Map<String, dynamic>>(
      '/mobile/users/me',
      requiresAuth: true,
      parser: (data) => data,
    );
    if (res.isSuccess && res.data != null) {
      return UserModel.fromJson(res.data!);
    } else {
      throw Exception(res.error ?? 'Failed to fetch profile');
    }
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final res = await _api.put<Map<String, dynamic>>(
      '/mobile/users/me',
      {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      },
      requiresAuth: true,
      parser: (data) => data,
    );
    if (res.isSuccess && res.data != null) {
      return UserModel.fromJson(res.data!);
    } else {
      throw Exception(res.error ?? 'Failed to update profile');
    }
  }
}
