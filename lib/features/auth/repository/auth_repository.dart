import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taro_mobile/core/services/api_service.dart';
import 'package:taro_mobile/core/models/api_models.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendVerificationCode({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    Function(PhoneAuthCredential credential)? onVerificationCompleted,
    Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    try {
      // Format phone number if needed
      final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

      // Use Firebase Auth to send verification code
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted:
            onVerificationCompleted ??
            (PhoneAuthCredential credential) {
              // Auto-verification completed (usually on Android)
              // This can be handled if needed
            },
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout:
            onCodeAutoRetrievalTimeout ??
            (String verificationId) {
              // Auto-retrieval timeout
            },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        onVerificationFailed(e);
      } else {
        onVerificationFailed(FirebaseAuthException(code: 'unknown', message: 'Network error: ${e.toString()}'));
      }
    }
  }

  Future<SignInResponse> signInWithPhoneNumber({required String verificationId, required String code}) async {
    try {
      // Create phone auth credential
      final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);

      // Sign in with credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: 'Failed to sign in');
      }

      // Get ID token
      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw AuthException(message: 'Failed to get ID token');
      }

      final phoneNumber = user.phoneNumber ?? '';

      return SignInResponse(success: true, idToken: idToken, localId: user.uid, isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false, phoneNumber: phoneNumber);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      if (e is FirebaseAuthException) {
        throw AuthException(message: e.message ?? 'Invalid OTP', code: e.code);
      }
      throw AuthException(message: 'Network error: ${e.toString()}');
    }
  }

  Future<VerifyPhoneResponse> verifyPhone({required String idToken}) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/${ApiService.apiVersion}/mobile/auth/verify-phone');
      final headers = {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $idToken'};

      final httpResponse = await http.post(uri, headers: headers);
      final responseData = json.decode(httpResponse.body) as Map<String, dynamic>;
      
      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        if (responseData.containsKey('status') && responseData['status'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          final userData = data['user'] as Map<String, dynamic>;
          
          // Parse only wanted fields from user object
          final parsedUser = UserModel(
            uid: userData['uid'] as String? ?? '',
            orgId: userData['orgId'] as String?,
            role: userData['role'] as String? ?? 'Agent',
            name: userData['name'] as String? ?? '',
            firstName: userData['firstName'] as String? ?? '',
            lastName: userData['lastName'] as String? ?? '',
            email: userData['email'] as String?,
            phoneNumber: userData['phoneNumber'] as String? ?? '',
            tokenVersion: userData['tokenVersion'] as int? ?? 0,
            status: userData['status'] as String? ?? 'Active',
            isActive: true, // Default value since not in response
            isDeleted: false, // Default value since not in response
            id: userData['_id'] as String? ?? '',
            createdAt: '', // Not in response
            updatedAt: '', // Not in response
            publicSlug: userData['publicSlug'] as String? ?? '',
          );
          
          return VerifyPhoneResponse(
            success: true,
            user: parsedUser,
            firebaseClaims: data['firebaseClaims'] as Map<String, dynamic>? ?? {},
          );
        } else {
          throw AuthException(message: responseData['message'] as String? ?? 'Failed to verify phone', code: responseData['code'] as String?);
        }
      } else {
        throw AuthException(message: responseData['message'] as String? ?? 'Failed to verify phone', code: responseData['code'] as String?);
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      print('Error verifying phone: $e');
      throw AuthException(message: 'Network error: ${e.toString()}');
    }
  }
}

class SignInResponse {
  final bool success;
  final String idToken;
  final String localId;
  final bool isNewUser;
  final String phoneNumber;

  SignInResponse({required this.success, required this.idToken, required this.localId, required this.isNewUser, required this.phoneNumber});
}

class VerifyPhoneResponse {
  final bool success;
  final UserModel user;
  final Map<String, dynamic> firebaseClaims;

  VerifyPhoneResponse({required this.success, required this.user, required this.firebaseClaims});
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException({required this.message, this.code});

  @override
  String toString() => message;
}
