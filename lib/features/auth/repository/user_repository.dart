import 'package:taro_mobile/core/services/api_service.dart';
import 'package:taro_mobile/core/models/api_models.dart';

class UserRepository {
  final ApiService _apiService = ApiService.instance;

  Future<UserModel> getProfile() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/mobile/users/me',
        requiresAuth: true,
        parser: (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        return UserModel.fromJson(response.data!);
      } else {
        throw Exception(response.error ?? 'Failed to fetch profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (email != null) body['email'] = email;

      final response = await _apiService.put<Map<String, dynamic>>(
        '/mobile/users/me',
        body,
        requiresAuth: true,
        parser: (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        return UserModel.fromJson(response.data!);
      } else {
        throw Exception(response.error ?? 'Failed to update profile');
      }
    } catch (e) {
      rethrow;
    }
  }
}

