import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'https://taro-backend-2o4k.onrender.com';
  static const String apiVersion = 'v1';

  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();

  ApiService._();

  Future<String?> _getAuthToken() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get fresh ID token from Firebase Auth
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    return headers;
  }

  Future<Map<String, String>> _getHeadersWithAuth() async {
    final headers = _getHeaders();
    final token = await _getAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ApiResponse<T>> post<T>(String endpoint, Map<String, dynamic>? body, {bool requiresAuth = false, T Function(Map<String, dynamic>)? parser}) async {
    try {
      final uri = Uri.parse('$baseUrl/$apiVersion$endpoint');
      print('POST $endpoint');

      final headers = requiresAuth ? await _getHeadersWithAuth() : _getHeaders();

      final response = await http.post(uri, headers: headers, body: body != null ? json.encode(body) : null);

      print('POST $endpoint -> ${response.statusCode}');
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Check if response has standard format
        if (responseData.containsKey('status') && responseData.containsKey('data')) {
          final status = responseData['status'] as bool;
          if (status) {
            return ApiResponse<T>(
              success: true,
              data: parser != null ? parser(responseData['data'] as Map<String, dynamic>) : responseData['data'] as T,
              statusCode: response.statusCode,
              message: responseData['message'] as String?,
              code: responseData['code'] as String?,
            );
          } else {
            return ApiResponse<T>(
              success: false,
              error: responseData['message'] as String? ?? 'An error occurred',
              errorCode: responseData['code'] as String?,
              statusCode: response.statusCode,
            );
          }
        } else {
          // Direct data response
          return ApiResponse<T>(success: true, data: parser != null ? parser(responseData) : responseData as T, statusCode: response.statusCode);
        }
      } else {
        final error = responseData['error'] as Map<String, dynamic>?;
        return ApiResponse<T>(
          success: false,
          error: responseData['message'] as String? ?? error?['message'] ?? 'An error occurred',
          errorCode: responseData['code'] as String? ?? error?['code']?.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('POST $endpoint -> ERROR: $e');
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}', statusCode: 0);
    }
  }

  Future<ApiResponse<T>> get<T>(String endpoint, {Map<String, String>? queryParams, bool requiresAuth = false, T Function(Map<String, dynamic>)? parser}) async {
    try {
      var uri = Uri.parse('$baseUrl/$apiVersion$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      print('GET $endpoint');

      final headers = requiresAuth ? await _getHeadersWithAuth() : _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('GET $endpoint -> ${response.statusCode}');
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Check if response has standard format
        if (responseData.containsKey('status') && responseData.containsKey('data')) {
          final status = responseData['status'] as bool;
          if (status) {
            return ApiResponse<T>(
              success: true,
              data: parser != null ? parser(responseData['data'] as Map<String, dynamic>) : responseData['data'] as T,
              statusCode: response.statusCode,
              message: responseData['message'] as String?,
              code: responseData['code'] as String?,
            );
          } else {
            return ApiResponse<T>(
              success: false,
              error: responseData['message'] as String? ?? 'An error occurred',
              errorCode: responseData['code'] as String?,
              statusCode: response.statusCode,
            );
          }
        } else {
          // Direct data response
          return ApiResponse<T>(success: true, data: parser != null ? parser(responseData) : responseData as T, statusCode: response.statusCode);
        }
      } else {
        final error = responseData['error'] as Map<String, dynamic>?;
        return ApiResponse<T>(
          success: false,
          error: responseData['message'] as String? ?? error?['message'] ?? 'An error occurred',
          errorCode: responseData['code'] as String? ?? error?['code']?.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('GET $endpoint -> ERROR: $e');
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}', statusCode: 0);
    }
  }

  Future<ApiResponse<T>> put<T>(String endpoint, Map<String, dynamic>? body, {bool requiresAuth = false, T Function(Map<String, dynamic>)? parser}) async {
    try {
      final uri = Uri.parse('$baseUrl/$apiVersion$endpoint');
      print('PUT $endpoint');

      final headers = requiresAuth ? await _getHeadersWithAuth() : _getHeaders();

      final response = await http.put(uri, headers: headers, body: body != null ? json.encode(body) : null);

      print('PUT $endpoint -> ${response.statusCode}');
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData.containsKey('status') && responseData.containsKey('data')) {
          final status = responseData['status'] as bool;
          if (status) {
            return ApiResponse<T>(
              success: true,
              data: parser != null ? parser(responseData['data'] as Map<String, dynamic>) : responseData['data'] as T,
              statusCode: response.statusCode,
              message: responseData['message'] as String?,
              code: responseData['code'] as String?,
            );
          } else {
            return ApiResponse<T>(
              success: false,
              error: responseData['message'] as String? ?? 'An error occurred',
              errorCode: responseData['code'] as String?,
              statusCode: response.statusCode,
            );
          }
        } else {
          return ApiResponse<T>(success: true, data: parser != null ? parser(responseData) : responseData as T, statusCode: response.statusCode);
        }
      } else {
        final error = responseData['error'] as Map<String, dynamic>?;
        return ApiResponse<T>(
          success: false,
          error: responseData['message'] as String? ?? error?['message'] ?? 'An error occurred',
          errorCode: responseData['code'] as String? ?? error?['code']?.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('PUT $endpoint -> ERROR: $e');
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}', statusCode: 0);
    }
  }

  Future<ApiResponse<T>> delete<T>(String endpoint, Map<String, dynamic>? body, {bool requiresAuth = false, T Function(Map<String, dynamic>)? parser}) async {
    try {
      final uri = Uri.parse('$baseUrl/$apiVersion$endpoint');
      print('DELETE $endpoint');

      final headers = requiresAuth ? await _getHeadersWithAuth() : _getHeaders();

      final response = await http.delete(uri, headers: headers, body: body != null ? json.encode(body) : null);

      print('DELETE $endpoint -> ${response.statusCode}');
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData.containsKey('status') && responseData.containsKey('data')) {
          final status = responseData['status'] as bool;
          if (status) {
            final data = responseData['data'];
            return ApiResponse<T>(
              success: true,
              data: data != null && parser != null ? parser(data as Map<String, dynamic>) : (data != null ? data as T : null),
              statusCode: response.statusCode,
              message: responseData['message'] as String?,
              code: responseData['code'] as String?,
            );
          } else {
            return ApiResponse<T>(
              success: false,
              error: responseData['message'] as String? ?? 'An error occurred',
              errorCode: responseData['code'] as String?,
              statusCode: response.statusCode,
            );
          }
        } else {
          return ApiResponse<T>(success: true, data: parser != null ? parser(responseData) : responseData as T, statusCode: response.statusCode);
        }
      } else {
        final error = responseData['error'] as Map<String, dynamic>?;
        return ApiResponse<T>(
          success: false,
          error: responseData['message'] as String? ?? error?['message'] ?? 'An error occurred',
          errorCode: responseData['code'] as String? ?? error?['code']?.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('DELETE $endpoint -> ERROR: $e');
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}', statusCode: 0);
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;
  final String? message;
  final String? code;
  final int statusCode;

  ApiResponse({required this.success, this.data, this.error, this.errorCode, this.message, this.code, required this.statusCode});

  bool get isSuccess => success;
  bool get isError => !success;
}
