import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://identitytoolkit.googleapis.com/v1';
  static const String apiKey = 'AIzaSyCPCKCwZ5jl4BeAv6rLglx2Dj0NYEtkgY8';

  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();

  ApiService._();

  Map<String, String> get _headers => {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<ApiResponse<T>> post<T>(String endpoint, Map<String, dynamic> body, {Map<String, String>? headers, T Function(Map<String, dynamic>)? parser}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint?key=$apiKey');
      final response = await http.post(uri, headers: {..._headers, ...?headers}, body: json.encode(body));

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>(success: true, data: parser != null ? parser(responseData) : responseData as T, statusCode: response.statusCode);
      } else {
        final error = responseData['error'] as Map<String, dynamic>?;
        return ApiResponse<T>(success: false, error: error?['message'] ?? 'An error occurred', errorCode: error?['code']?.toString(), statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}', statusCode: 0);
    }
  }

  Future<ApiResponse<T>> get<T>(String endpoint, {Map<String, String>? queryParams, Map<String, String>? headers, T Function(Map<String, dynamic>)? parser}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint?key=$apiKey');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: {..._headers, ...?headers});

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>(success: true, data: parser != null ? parser(responseData) : responseData as T, statusCode: response.statusCode);
      } else {
        final error = responseData['error'] as Map<String, dynamic>?;
        return ApiResponse<T>(success: false, error: error?['message'] ?? 'An error occurred', errorCode: error?['code']?.toString(), statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}', statusCode: 0);
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;
  final int statusCode;

  ApiResponse({required this.success, this.data, this.error, this.errorCode, required this.statusCode});

  bool get isSuccess => success;
  bool get isError => !success;
}
