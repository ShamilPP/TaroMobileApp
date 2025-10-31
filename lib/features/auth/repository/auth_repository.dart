import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taro_mobile/core/services/api_service.dart';
import 'package:taro_mobile/core/services/backend_api_service.dart';
import 'package:taro_mobile/core/models/api_models.dart';

class AuthRepository {
  final ApiService _apiService = ApiService.instance;

  Future<SendVerificationCodeResponse> sendVerificationCode({
    required String phoneNumber,
    String recaptchaToken = 'TEST',
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/accounts:sendVerificationCode',
        {
          'phoneNumber': phoneNumber,
          'recaptchaToken': recaptchaToken,
        },
      );

      if (response.isSuccess && response.data != null) {
        return SendVerificationCodeResponse(
          success: true,
          sessionInfo: response.data!['sessionInfo'] as String,
        );
      } else {
        throw AuthException(
          message: response.error ?? 'Failed to send verification code',
          code: response.errorCode,
        );
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<SignInResponse> signInWithPhoneNumber({
    required String sessionInfo,
    required String code,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/accounts:signInWithPhoneNumber',
        {
          'sessionInfo': sessionInfo,
          'code': code,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return SignInResponse(
          success: true,
          idToken: data['idToken'] as String? ?? '',
          refreshToken: data['refreshToken'] as String? ?? '',
          expiresIn: data['expiresIn'] as String? ?? '3600',
          localId: data['localId'] as String? ?? '',
          isNewUser: data['isNewUser'] as bool? ?? false,
          phoneNumber: data['phoneNumber'] as String? ?? '',
        );
      } else {
        throw AuthException(
          message: response.error ?? 'Invalid OTP',
          code: response.errorCode,
        );
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<VerifyPhoneResponse> verifyPhone({
    required String idToken,
  }) async {
    try {
      final uri = Uri.parse('${BackendApiService.baseUrl}/${BackendApiService.apiVersion}/mobile/auth/verify-phone');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $idToken',
      };
      
      final httpResponse = await http.post(
        uri,
        headers: headers,
      );

      final responseData = json.decode(httpResponse.body) as Map<String, dynamic>;

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        if (responseData.containsKey('status') && responseData['status'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          return VerifyPhoneResponse(
            success: true,
            user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
            firebaseClaims: data['firebaseClaims'] as Map<String, dynamic>? ?? {},
          );
        } else {
          throw AuthException(
            message: responseData['message'] as String? ?? 'Failed to verify phone',
            code: responseData['code'] as String?,
          );
        }
      } else {
        throw AuthException(
          message: responseData['message'] as String? ?? 'Failed to verify phone',
          code: responseData['code'] as String?,
        );
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}

class SendVerificationCodeResponse {
  final bool success;
  final String sessionInfo;

  SendVerificationCodeResponse({
    required this.success,
    required this.sessionInfo,
  });
}

class SignInResponse {
  final bool success;
  final String idToken;
  final String refreshToken;
  final String expiresIn;
  final String localId;
  final bool isNewUser;
  final String phoneNumber;

  SignInResponse({
    required this.success,
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.localId,
    required this.isNewUser,
    required this.phoneNumber,
  });
}

class VerifyPhoneResponse {
  final bool success;
  final UserModel user;
  final Map<String, dynamic> firebaseClaims;

  VerifyPhoneResponse({
    required this.success,
    required this.user,
    required this.firebaseClaims,
  });
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException({required this.message, this.code});

  @override
  String toString() => message;
}

