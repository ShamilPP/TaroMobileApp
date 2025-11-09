import 'package:taro_mobile/core/models/api_models.dart';
import 'package:taro_mobile/core/services/api_service.dart';

class OrganizationRepository {
  final ApiService _api = ApiService.instance;

  /// ✅ Get organization details (GET /mobile/organization/{{ORG_SLUG}})
  Future<OrganizationModel> getOrganization({required String slug}) async {
    final res = await _api.get<Map<String, dynamic>>('/mobile/organization/$slug', requiresAuth: true, parser: (data) => data);

    print('ORG RESPONSE: ${res.data}');
    if (res.isSuccess && res.data != null) {
      return OrganizationModel.fromJson(res.data!['data']);
    } else {
      throw Exception(res.error ?? 'Failed to fetch organization');
    }
  }

  /// ✅ Create new organization (POST /mobile/organization/create)
  Future<OrganizationModel> createOrganization({required String name, required String address, required int maxAgents}) async {
    final body = {
      'name': name,
      'address': address,
      'limits': {'maxAgents': maxAgents},
    };

    final res = await _api.post<Map<String, dynamic>>('/mobile/organization/create', body, requiresAuth: true, parser: (data) => data);

    print('CREATE ORG RESPONSE: ${res.data}');
    if (res.isSuccess && res.data != null) {
      return OrganizationModel.fromJson(res.data!['data']);
    } else {
      throw Exception(res.error ?? 'Failed to create organization');
    }
  }

  /// ✅ Update organization name (PUT /mobile/organization/{{ORG_SLUG}})
  Future<void> updateOrganization({required String slug, required String newName}) async {
    final res = await _api.put<Map<String, dynamic>>('/mobile/organization/$slug', {'name': newName}, requiresAuth: true, parser: (data) => data);

    print('UPDATE ORG RESPONSE: ${res.data}');
    if (!res.isSuccess) {
      throw Exception(res.error ?? 'Failed to update organization');
    }
  }

  /// ✅ Get organization members (POST /mobile/organization/{{ORG_SLUG}}/members)
  Future<List<OrganizationMemberModel>> getMembers({required String slug}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/mobile/organization/$slug/members',
      {
        'options': {'page': 1, 'limit': 20},
      },
      requiresAuth: true,
      parser: (data) => data,
    );

    print('MEMBERS RESPONSE: ${res.data}');
    if (res.isSuccess && res.data != null) {
      final members = res.data!['data']['data'] as List<dynamic>;
      return members.map((e) => OrganizationMemberModel.fromJson(e)).toList();
    } else {
      throw Exception(res.error ?? 'Failed to fetch members');
    }
  }

  /// ✅ Invite new member (POST /mobile/organization/{{ORG_SLUG}}/invite)
  Future<void> inviteMember({required String slug, required String phone}) async {
    final body = {'phone': phone};

    final res = await _api.post<Map<String, dynamic>>('/mobile/organization/$slug/invite', body, requiresAuth: true, parser: (data) => data);

    print('INVITE RESPONSE: ${res.data}');
    if (!res.isSuccess) {
      throw Exception(res.error ?? 'Failed to invite member');
    }
  }

  /// ✅ Remove team member (DELETE /mobile/organization/{{ORG_SLUG}}/members)
  Future<void> deleteMember({required String slug, required String uid}) async {
    final res = await _api.delete<Map<String, dynamic>>('/mobile/organization/$slug/members', {'uid': uid}, requiresAuth: true, parser: (data) => data);

    print('DELETE MEMBER RESPONSE: ${res.data}');
    if (!res.isSuccess) {
      throw Exception(res.error ?? 'Failed to delete member');
    }
  }

  /// ✅ Get invites list (POST /mobile/organization/{{ORG_SLUG}}/invites)
  Future<List<OrganizationInviteModel>> getInvites({required String slug}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/mobile/organization/$slug/invites',
      {
        'options': {'page': 1, 'limit': 10},
      },
      requiresAuth: true,
      parser: (data) => data,
    );

    print('INVITES RESPONSE: ${res.data}');
    if (res.isSuccess && res.data != null) {
      final invites = res.data!['data']['data'] as List<dynamic>;
      return invites.map((e) => OrganizationInviteModel.fromJson(e)).toList();
    } else {
      throw Exception(res.error ?? 'Failed to fetch invites');
    }
  }

  /// ✅ Delete invite (DELETE /mobile/organization/{{ORG_SLUG}}/invites)
  Future<void> deleteInvite({required String slug, required String phone}) async {
    final res = await _api.delete<Map<String, dynamic>>('/mobile/organization/$slug/invites', {'phone': phone}, requiresAuth: true, parser: (data) => data);

    print('DELETE INVITE RESPONSE: ${res.data}');
    if (!res.isSuccess) {
      throw Exception(res.error ?? 'Failed to delete invite');
    }
  }

  /// ✅ Accept team invite (POST /mobile/organization/accept-invite)
  Future<void> acceptInvite({required String token}) async {
    final body = {'token': token};

    final res = await _api.post<Map<String, dynamic>>('/mobile/organization/accept-invite', body, requiresAuth: true, parser: (data) => data);

    print('ACCEPT INVITE RESPONSE: ${res.data}');
    if (!res.isSuccess) {
      throw Exception(res.error ?? 'Failed to accept invite');
    }
  }

  /// ✅ Get my invites (POST /mobile/organization/invites/me)
  Future<List<OrganizationInviteModel>> getMyInvites() async {
    final res = await _api.post<Map<String, dynamic>>(
      '/mobile/organization/invites/me',
      {
        'options': {'page': 1, 'limit': 10},
      },
      requiresAuth: true,
      parser: (data) => data,
    );

    print('MY INVITES RESPONSE: ${res.data}');
    if (res.isSuccess && res.data != null) {
      final invites = res.data!['data']['data'] as List<dynamic>;
      return invites.map((e) => OrganizationInviteModel.fromJson(e)).toList();
    } else {
      throw Exception(res.error ?? 'Failed to fetch my invites');
    }
  }

  /// ✅ Get organization statistics (GET /mobile/organization/{{ORG_SLUG}}/stats)
  Future<Map<String, dynamic>> getOrganizationStats({required String slug}) async {
    final res = await _api.get<Map<String, dynamic>>('/mobile/organization/$slug/stats', requiresAuth: true, parser: (data) => data);

    print('ORG STATS RESPONSE: ${res.data}');
    if (res.isSuccess && res.data != null) {
      return res.data!['data'] as Map<String, dynamic>;
    } else {
      throw Exception(res.error ?? 'Failed to fetch organization stats');
    }
  }
}
