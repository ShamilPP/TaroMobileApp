// import 'package:taro_mobile/core/models/api_models.dart';
// import 'package:taro_mobile/core/services/api_service.dart';
//
// class OrganizationRepository {
//   final ApiService _apiService = ApiService.instance;
//
//   /// ✅ Get organization details
//   Future<OrganizationModel> getOrganization({required String slug}) async {
//     final response = await _apiService.get<Map<String, dynamic>>(
//       '/mobile/organization/$slug',
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (response.isSuccess && response.data != null) {
//       return OrganizationModel.fromJson(response.data!['data']);
//     } else {
//       throw Exception(response.error ?? 'Failed to fetch organization');
//     }
//   }
//
//   /// ✅ Get organization members list
//   Future<List<OrganizationMemberModel>> getMembers({required String slug}) async {
//     final response = await _apiService.post<Map<String, dynamic>>(
//       '/mobile/organization/$slug/members',
//       {
//         'options': {'page': 1, 'limit': 20}
//       },
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (response.isSuccess && response.data != null) {
//       final members = response.data!['data']['data'] as List<dynamic>;
//       return members.map((e) => OrganizationMemberModel.fromJson(e)).toList();
//     } else {
//       throw Exception(response.error ?? 'Failed to fetch organization members');
//     }
//   }
//
//   /// ✅ Create new organization
//   Future<OrganizationModel> createOrganization({
//     required String name,
//     required String address,
//     required int maxAgents,
//   }) async {
//     final body = {
//       'name': name,
//       'address': address,
//       'limits': {'maxAgents': maxAgents},
//     };
//
//     final response = await _apiService.post<Map<String, dynamic>>(
//       '/mobile/organization/create',
//       body,
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (response.isSuccess && response.data != null) {
//       return OrganizationModel.fromJson(response.data!['data']);
//     } else {
//       throw Exception(response.error ?? 'Failed to create organization');
//     }
//   }
//
//   /// ✅ Update organization name
//   Future<void> updateOrganization({
//     required String slug,
//     required String newName,
//   }) async {
//     final response = await _apiService.put<Map<String, dynamic>>(
//       '/mobile/organization/$slug',
//       {'name': newName},
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (!response.isSuccess) {
//       throw Exception(response.error ?? 'Failed to update organization');
//     }
//   }
//
//   /// ✅ Invite a new member
//   Future<void> inviteMember({
//     required String slug,
//     required String phone,
//     required String role,
//   }) async {
//     final body = {
//       'phone': phone,
//       'role': role,
//     };
//
//     final response = await _apiService.post<Map<String, dynamic>>(
//       '/mobile/organization/$slug/invite',
//       body,
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (!response.isSuccess) {
//       throw Exception(response.error ?? 'Failed to invite member');
//     }
//   }
//
//   /// ✅ Remove a member from organization
//   Future<void> deleteMember({
//     required String slug,
//     required String uid,
//   }) async {
//     final response = await _apiService.delete<Map<String, dynamic>>(
//       '/mobile/organization/$slug/members',
//       body: {'uid': uid},
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (!response.isSuccess) {
//       throw Exception(response.error ?? 'Failed to remove member');
//     }
//   }
//
//   /// ✅ Get list of pending invites
//   Future<List<OrganizationInviteModel>> getInvites({required String slug}) async {
//     final response = await _apiService.post<Map<String, dynamic>>(
//       '/mobile/organization/$slug/invites',
//       {
//         'options': {'page': 1, 'limit': 10}
//       },
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (response.isSuccess && response.data != null) {
//       final invites = response.data!['data']['data'] as List<dynamic>;
//       return invites.map((e) => OrganizationInviteModel.fromJson(e)).toList();
//     } else {
//       throw Exception(response.error ?? 'Failed to fetch invites');
//     }
//   }
//
//   /// ✅ Delete an invite
//   Future<void> deleteInvite({
//     required String slug,
//     required String phone,
//   }) async {
//     final response = await _apiService.delete<Map<String, dynamic>>(
//       '/mobile/organization/$slug/invites',
//       body: {'phone': phone},
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (!response.isSuccess) {
//       throw Exception(response.error ?? 'Failed to delete invite');
//     }
//   }
//
//   /// ✅ Accept invite (for user joining organization)
//   Future<void> acceptInvite({required String token}) async {
//     final response = await _apiService.post<Map<String, dynamic>>(
//       '/mobile/organization/accept-invite',
//       {'token': token},
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (!response.isSuccess) {
//       throw Exception(response.error ?? 'Failed to accept invite');
//     }
//   }
//
//   /// ✅ Get invites belonging to current user
//   Future<List<OrganizationInviteModel>> getMyInvites() async {
//     final response = await _apiService.post<Map<String, dynamic>>(
//       '/mobile/organization/invites/me',
//       {
//         'options': {'page': 1, 'limit': 10}
//       },
//       requiresAuth: true,
//       parser: (data) => data,
//     );
//
//     if (response.isSuccess && response.data != null) {
//       final invites = response.data!['data']['data'] as List<dynamic>;
//       return invites.map((e) => OrganizationInviteModel.fromJson(e)).toList();
//     } else {
//       throw Exception(response.error ?? 'Failed to fetch user invites');
//     }
//   }
// }
