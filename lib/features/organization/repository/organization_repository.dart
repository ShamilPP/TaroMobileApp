import 'package:taro_mobile/core/services/api_service.dart';
import 'package:taro_mobile/core/models/api_models.dart';

class OrganizationRepository {
  final ApiService _apiService = ApiService.instance;

  Future<PaginatedResponse<OrganizationInviteModel>> getMyInvitations({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/mobile/organization/invites/me',
        {
          'options': {
            'page': page,
            'limit': limit,
          },
        },
        requiresAuth: true,
        parser: (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        return PaginatedResponse.fromJson(
          response.data!,
          (json) => OrganizationInviteModel.fromJson(json),
        );
      } else {
        throw Exception(response.error ?? 'Failed to fetch invitations');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<OrganizationModel> createOrganization({
    required String name,
    required String address,
    int maxAgents = 10,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/mobile/organization/create',
        {
          'name': name,
          'address': address,
          'limits': {
            'maxAgents': maxAgents,
          },
        },
        requiresAuth: true,
        parser: (data) => data['org'] as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return OrganizationModel.fromJson(response.data!);
      } else {
        throw Exception(response.error ?? 'Failed to create organization');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<OrganizationInviteModel> inviteUser({
    required String orgSlug,
    required String phone,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/mobile/organization/$orgSlug/invite',
        {
          'phone': phone,
        },
        requiresAuth: true,
        parser: (data) => data['invite'] as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return OrganizationInviteModel.fromJson(response.data!);
      } else {
        throw Exception(response.error ?? 'Failed to send invitation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PaginatedResponse<OrganizationMemberModel>> getMembers({
    required String orgSlug,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/mobile/organization/$orgSlug/members',
        {
          'options': {
            'page': page,
            'limit': limit,
          },
        },
        requiresAuth: true,
        parser: (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        return PaginatedResponse.fromJson(
          response.data!,
          (json) => OrganizationMemberModel.fromJson(json),
        );
      } else {
        throw Exception(response.error ?? 'Failed to fetch members');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PaginatedResponse<OrganizationInviteModel>> getInvites({
    required String orgSlug,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/mobile/organization/$orgSlug/invites',
        {
          'options': {
            'page': page,
            'limit': limit,
          },
        },
        requiresAuth: true,
        parser: (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        return PaginatedResponse.fromJson(
          response.data!,
          (json) => OrganizationInviteModel.fromJson(json),
        );
      } else {
        throw Exception(response.error ?? 'Failed to fetch invites');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeInvite({
    required String orgSlug,
    required String phone,
  }) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>?>(
        '/mobile/organization/$orgSlug/invites',
        {
          'phone': phone,
        },
        requiresAuth: true,
      );

      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to remove invite');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptInvite({
    required String token,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>?>(
        '/mobile/organization/accept-invite',
        {
          'token': token,
        },
        requiresAuth: true,
      );

      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to accept invite');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeMember({
    required String orgSlug,
    required String uid,
  }) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>?>(
        '/mobile/organization/$orgSlug/members',
        {
          'uid': uid,
        },
        requiresAuth: true,
      );

      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to remove member');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<OrganizationModel> getOrganization({
    required String orgSlug,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/mobile/organization/$orgSlug',
        requiresAuth: true,
        parser: (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        return OrganizationModel.fromJson(response.data!);
      } else {
        throw Exception(response.error ?? 'Failed to fetch organization');
      }
    } catch (e) {
      rethrow;
    }
  }
}

