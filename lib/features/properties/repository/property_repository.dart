import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taro_mobile/core/models/api_models.dart';
import 'package:taro_mobile/core/services/api_service.dart';

class PropertyRepository {
  final ApiService _api = ApiService.instance;

  /// Create Property
  /// POST /mobile/property
  Future<PropertyModel> createProperty({
    required String title,
    required String type,
    required String status,
    required double price,
    required String currency,
    required Address address,
    required Location location,
    int? bedrooms,
    int? bathrooms,
    double? areaSqFt,
    required List<String> amenities,
    required List<String> images,
    String? description,
    required String orgSlug,
  }) async {
    final body = {
      'title': title,
      'type': type,
      'status': status,
      'price': price,
      'currency': currency,
      'address': address.toJson(),
      'location': location.toJson(),
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (areaSqFt != null) 'areaSqFt': areaSqFt,
      'amenities': amenities,
      'images': images,
      if (description != null) 'description': description,
      'orgSlug': orgSlug,
    };

    final res = await _api.post<Map<String, dynamic>>('/mobile/property', body, requiresAuth: true, parser: (data) => data);

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final propertyData = responseData['data'] ?? responseData;
      return PropertyModel.fromJson(propertyData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to create property');
    }
  }

  /// Get Property
  /// GET /mobile/property/{propertyId}
  Future<PropertyModel> getProperty({required String propertyId}) async {
    final res = await _api.get<Map<String, dynamic>>('/mobile/property/$propertyId', requiresAuth: true, parser: (data) => data);

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final propertyData = responseData['data'] ?? responseData;
      return PropertyModel.fromJson(propertyData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to fetch property');
    }
  }

  /// Update Property
  /// PUT /mobile/property/{propertyId}
  Future<PropertyModel> updateProperty({
    required String propertyId,
    String? title,
    String? type,
    String? status,
    double? price,
    String? currency,
    Address? address,
    Location? location,
    int? bedrooms,
    int? bathrooms,
    double? areaSqFt,
    List<String>? amenities,
    List<String>? images,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (type != null) body['type'] = type;
    if (status != null) body['status'] = status;
    if (price != null) body['price'] = price;
    if (currency != null) body['currency'] = currency;
    if (address != null) body['address'] = address.toJson();
    if (location != null) body['location'] = location.toJson();
    if (bedrooms != null) body['bedrooms'] = bedrooms;
    if (bathrooms != null) body['bathrooms'] = bathrooms;
    if (areaSqFt != null) body['areaSqFt'] = areaSqFt;
    if (amenities != null) body['amenities'] = amenities;
    if (images != null) body['images'] = images;
    if (description != null) body['description'] = description;

    final res = await _api.put<Map<String, dynamic>>('/mobile/property/$propertyId', body.isNotEmpty ? body : null, requiresAuth: true, parser: (data) => data);

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final propertyData = responseData['data'] ?? responseData;
      return PropertyModel.fromJson(propertyData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to update property');
    }
  }

  /// Delete Property
  /// DELETE /mobile/property/{propertyId}
  Future<Map<String, dynamic>> deleteProperty({required String propertyId}) async {
    final res = await _api.delete<Map<String, dynamic>>('/mobile/property/$propertyId', null, requiresAuth: true, parser: (data) => data);

    if (res.isSuccess) {
      return res.data ?? {'deleted': true, 'id': propertyId};
    } else {
      throw Exception(res.error ?? 'Failed to delete property');
    }
  }

  /// List Properties (Search)
  /// POST /mobile/property/search
  Future<PropertySearchResponse> searchProperties(PropertySearchRequest request) async {
    final res = await _api.post<Map<String, dynamic>>('/mobile/property/search', request.toJson(), requiresAuth: true, parser: (data) => data);

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final searchData = responseData['data'] ?? responseData;
      return PropertySearchResponse.fromJson(searchData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to search properties');
    }
  }

  /// Upload Property Images
  /// POST /mobile/property/{propertyId}/images
  /// Body: multipart/form-data with file(s) images[]
  Future<ImageUploadResponse> uploadPropertyImages({required String propertyId, required List<File> imageFiles}) async {
    try {
      // Get auth token
      String? token;
      try {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          token = await user.getIdToken();
        }
      } catch (e) {
        print('Error getting auth token: $e');
      }

      final uri = Uri.parse('${ApiService.baseUrl}/${ApiService.apiVersion}/mobile/property/$propertyId/images');

      var request = http.MultipartRequest('POST', uri);

      // Add authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Add image files
      for (var file in imageFiles) {
        request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final uploadData = responseData['data'] ?? responseData;
        return ImageUploadResponse.fromJson(uploadData as Map<String, dynamic>);
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'Failed to upload images');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Change Property Status
  /// POST /mobile/property/{propertyId}/status
  Future<PropertyModel> changePropertyStatus({
    required String propertyId,
    required String status, // "draft" | "active" | "archived"
  }) async {
    final res = await _api.post<Map<String, dynamic>>('/mobile/property/$propertyId/status', {'status': status}, requiresAuth: true, parser: (data) => data);

    if (res.isSuccess && res.data != null) {
      final responseData = res.data!;
      final propertyData = responseData['data'] ?? responseData;
      return PropertyModel.fromJson(propertyData as Map<String, dynamic>);
    } else {
      throw Exception(res.error ?? 'Failed to change property status');
    }
  }
}
