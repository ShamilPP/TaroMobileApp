import 'package:taro_mobile/core/models/api_models.dart';
import 'package:taro_mobile/core/services/api_service.dart';

class LeadRepository {
  final ApiService _api = ApiService.instance;

  /// Create Lead
  /// POST /mobile/leads
  Future<LeadModel> createLead({
    required String source,
    String? propertyId,
    required String name,
    required String email,
    required String phone,
    String? message,
    required String orgSlug,
    required List<String> tags,
    Map<String, dynamic>? utm,
  }) async {
    final body = {
      'source': source,
      if (propertyId != null) 'propertyId': propertyId,
      'name': name,
      'email': email,
      'phone': phone,
      if (message != null) 'message': message,
      'orgSlug': orgSlug,
      'tags': tags,
      if (utm != null) 'utm': utm,
    };

    final res = await _api.post<Map<String, dynamic>>(
      '/mobile/leads',
      body,
      requiresAuth: true,
      parser: (data) => data,
    );

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final leadData = responseData['data'] ?? responseData;
      return LeadModel.fromJson(leadData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to create lead');
    }
  }

  /// Get Lead
  /// GET /mobile/leads/{leadId}
  Future<LeadModel> getLead({required String leadId}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/mobile/leads/$leadId',
      requiresAuth: true,
      parser: (data) => data,
    );

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final leadData = responseData['data'] ?? responseData;
      return LeadModel.fromJson(leadData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to fetch lead');
    }
  }

  /// Update Lead
  /// PUT /mobile/leads/{leadId}
  Future<LeadModel> updateLead({
    required String leadId,
    String? name,
    String? email,
    String? phone,
    String? message,
    List<String>? tags,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (message != null) body['message'] = message;
    if (tags != null) body['tags'] = tags;

    final res = await _api.put<Map<String, dynamic>>(
      '/mobile/leads/$leadId',
      body.isNotEmpty ? body : null,
      requiresAuth: true,
      parser: (data) => data,
    );

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final leadData = responseData['data'] ?? responseData;
      return LeadModel.fromJson(leadData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to update lead');
    }
  }

  /// Change Lead Status
  /// POST /mobile/leads/{leadId}/status
  Future<LeadModel> changeLeadStatus({
    required String leadId,
    required String status, // "new" | "contacted" | "qualified" | "lost" | "won"
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/mobile/leads/$leadId/status',
      {'status': status},
      requiresAuth: true,
      parser: (data) => data,
    );

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final leadData = responseData['data'] ?? responseData;
      return LeadModel.fromJson(leadData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to change lead status');
    }
  }

  /// Assign Lead
  /// POST /mobile/leads/{leadId}/assign
  Future<LeadModel> assignLead({
    required String leadId,
    required String userId,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/mobile/leads/$leadId/assign',
      {'userId': userId},
      requiresAuth: true,
      parser: (data) => data,
    );

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final leadData = responseData['data'] ?? responseData;
      return LeadModel.fromJson(leadData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to assign lead');
    }
  }

  /// Add Lead Note
  /// POST /mobile/leads/{leadId}/notes
  Future<LeadNote> addLeadNote({
    required String leadId,
    required String text,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/mobile/leads/$leadId/notes',
      {'text': text},
      requiresAuth: true,
      parser: (data) => data,
    );

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final noteData = responseData['data'] ?? responseData;
      return LeadNote.fromJson(noteData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to add lead note');
    }
  }

  /// List Leads (Search)
  /// POST /mobile/leads/search
  Future<LeadSearchResponse> searchLeads(LeadSearchRequest request) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/mobile/leads/search',
      request.toJson(),
      requiresAuth: true,
      parser: (data) => data,
    );

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final searchData = responseData['data'] ?? responseData;
      return LeadSearchResponse.fromJson(searchData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to search leads');
    }
  }

  /// Delete Lead
  /// DELETE /mobile/leads/{leadId}
  Future<Map<String, dynamic>> deleteLead({required String leadId}) async {
    final res = await _api.delete<Map<String, dynamic>>(
      '/mobile/leads/$leadId',
      null,
      requiresAuth: true,
      parser: (data) => data,
    );

    if (res.isSuccess) {
      return res.data ?? {'deleted': true, 'id': leadId};
    } else {
      throw Exception(res.error ?? 'Failed to delete lead');
    }
  }
}

