import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:taro_mobile/features/auth/model/users_model.dart' as localRepo;
import 'package:taro_mobile/features/auth/repository/auth_repository.dart';
import 'package:taro_mobile/features/auth/repository/user_repository.dart' as backendUserRepo;
import 'package:taro_mobile/core/models/api_models.dart' as userModel;

class AuthProvider extends ChangeNotifier {
  static const String baseUrl = "{{URL}}";
  static const String apiVersion = "{{API_VERSION}}";

  final AuthRepository _authRepository = AuthRepository();
  final localRepo.UserRepository _userRepository = localRepo.UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _canResend = true;
  int _remainingSeconds = 0;
  Timer? _resendTimer;
  String? _verificationId;
  int? _resendToken;
  String? _localId;
  String? _phoneNumber;
  bool _isLoggedIn = false;
  localRepo.UserModel? _userData;
  bool _isInitialized = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  // Getters
  bool get isLoading => _isLoading;
  bool get canResend => _canResend;
  int get remainingSeconds => _remainingSeconds;
  bool get isLoggedIn => _isLoggedIn;
  String? get localId => _localId;
  String? get phoneNumber => _phoneNumber;
  localRepo.UserModel? get userData => _userData;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      final completer = Completer<void>();
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isInitialized) {
          timer.cancel();
          completer.complete();
        }
      });
      await completer.future;
    }
  }
  // ---------------------------------------------------------------------------
  // 🔹 Utility Methods
  // ---------------------------------------------------------------------------
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
  };

  String formatTime(int seconds) => '${seconds}s';

  // ---------------------------------------------------------------------------
  // 🔹 Initialization
  // ---------------------------------------------------------------------------
  Future<void> _initializeAuth() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        _localId = currentUser.uid;
        _phoneNumber = currentUser.phoneNumber;
        _isLoggedIn = true;
        await currentUser.getIdToken();
        await _saveLoginState(true);
        await _fetchUserData();
      } else {
        _isLoggedIn = false;
        await _saveLoginState(false);
      }

      _isInitialized = true;
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
      notifyListeners();
    } catch (e) {
      print('Error initializing auth: $e');
      _isInitialized = true;
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
      notifyListeners();
    }
  }

  Future<void> _saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);

    if (isLoggedIn) {
      if (_localId != null) prefs.setString('localId', _localId!);
      if (_phoneNumber != null) prefs.setString('phoneNumber', _phoneNumber!);
    } else {
      prefs.remove('localId');
      prefs.remove('phoneNumber');
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 Firebase OTP Flow
  // ---------------------------------------------------------------------------
  Future<void> sendOTP(
      String phoneNumber,
      Function(String, int?) onCodeSent,
      Function(dynamic) onVerificationFailed,
      ) async {
    setLoading(true);
    try {
      final formattedPhone = phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      await _authRepository.sendVerificationCode(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _phoneNumber = formattedPhone;
          setLoading(false);
          _startResendTimer();
          onCodeSent(verificationId, resendToken);
        },
        onVerificationFailed: (e) {
          setLoading(false);
          onVerificationFailed(e);
        },
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await verifyCredential(credential);
          } catch (e) {
            onVerificationFailed(e);
          }
        },
      );
    } catch (e) {
      setLoading(false);
      onVerificationFailed(e);
    }
  }

  Future<void> verifyOTP(String otp) async {
    if (_verificationId == null) {
      throw Exception('Verification ID not found. Please request OTP again.');
    }

    setLoading(true);
    try {
      final firebaseResponse = await _authRepository.signInWithPhoneNumber(
        verificationId: _verificationId!,
        code: otp,
      );

      if (!firebaseResponse.success) throw Exception('Invalid OTP');

      final verifyResponse = await _authRepository.verifyPhone(idToken: firebaseResponse.idToken!);
      if (verifyResponse.success) {
        _localId = verifyResponse.user.uid;
        _phoneNumber = verifyResponse.user.phoneNumber;
        _isLoggedIn = true;
        await _saveLoginState(true);
        await _syncUserDataFromBackend(verifyResponse.user);
      } else {
        throw Exception('Failed to verify phone with backend');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> verifyCredential(PhoneAuthCredential credential) async {
    setLoading(true);
    try {
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('Failed to sign in');

      final idToken = await user.getIdToken();
      final verifyResponse = await _authRepository.verifyPhone(idToken: idToken!);
      if (verifyResponse.success) {
        _localId = verifyResponse.user.uid;
        _phoneNumber = verifyResponse.user.phoneNumber;
        _isLoggedIn = true;
        await _saveLoginState(true);
        await _syncUserDataFromBackend(verifyResponse.user);
      } else {
        throw Exception('Failed to verify phone with backend');
      }
    } catch (e) {
      print('Error verifying credential: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 Backend Integration
  // ---------------------------------------------------------------------------

  Future<userModel.UserModel?> verifyPhoneWithBackend(String phoneNumber) async {
    try {
      final url = Uri.parse('$baseUrl/$apiVersion/mobile/auth/verify-phone');
      final res = await http.post(url, headers: _headers, body: jsonEncode({"phone": phoneNumber}));
      final data = jsonDecode(res.body);

      if (data['status'] == true) {
        return userModel.UserModel.fromJson(data['data']['user']);
      } else {
        print("Backend verification failed: ${data['message']}");
      }
    } catch (e) {
      print("verifyPhoneWithBackend error: $e");
    }
    return null;
  }

  Future<bool> createOrganization(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/$apiVersion/mobile/organization/create');
      final res = await http.post(url, headers: _headers, body: jsonEncode(payload));
      final data = jsonDecode(res.body);
      return data['status'] == true;
    } catch (e) {
      print("createOrganization error: $e");
      return false;
    }
  }

  Future<bool> acceptInvite(String token) async {
    try {
      final url = Uri.parse('$baseUrl/$apiVersion/mobile/organization/accept-invite');
      final res = await http.post(url, headers: _headers, body: jsonEncode({"token": token}));
      final data = jsonDecode(res.body);
      return data['status'] == true;
    } catch (e) {
      print("acceptInvite error: $e");
      return false;
    }
  }

  Future<bool> updateBackendProfile({
    required String firstName,
    required String lastName,
    String? email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$apiVersion/mobile/users/me');
      final res = await http.put(
        url,
        headers: _headers,
        body: jsonEncode({"firstName": firstName, "lastName": lastName, "email": email}),
      );
      final data = jsonDecode(res.body);
      return data['status'] == true;
    } catch (e) {
      print("updateBackendProfile error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 Local Firestore User Data Sync
  // ---------------------------------------------------------------------------

  Future<void> _fetchUserData({String firstName = '', String lastName = ''}) async {
    if (_localId == null) return;
    try {
      final user = await _userRepository.getUserData(_localId!);
      if (user != null) {
        _userData = user;
      } else {
        final newUser = localRepo.UserModel.minimal(_localId!, _phoneNumber ?? '', firstName: firstName, lastName: lastName);
        await _userRepository.createUser(newUser);
        _userData = newUser;
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> refreshUserData() async {
    if (_localId != null) await _fetchUserData();
  }

  Future<void> _syncUserDataFromBackend(userModel.UserModel backendUser) async {
    try {
      final existing = await _userRepository.getUserData(backendUser.uid);
      final needsRegistration = backendUser.firstName.isEmpty || backendUser.lastName.isEmpty;

      final newUser = localRepo.UserModel(
        uid: backendUser.uid,
        phoneNumber: backendUser.phoneNumber,
        createdAt: DateTime.now(),
        firstName: backendUser.firstName,
        lastName: backendUser.lastName,
        customData: {
          'role': backendUser.role,
          'orgId': backendUser.orgId,
          'email': backendUser.email,
          'needsRegistration': needsRegistration,
        },
      );

      if (existing == null) {
        await _userRepository.createUser(newUser);
      } else {
        await _userRepository.updateUser(newUser);
      }

      _userData = newUser;
      notifyListeners();
    } catch (e) {
      print('Error syncing user data: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 Registration After OTP
  // ---------------------------------------------------------------------------
  Future<bool> registerNewUser({
    required String firstName,
    required String lastName,
    String? reraNumber,
    String? email,
  }) async {
    if (_localId == null) return false;

    try {
      final backend = backendUserRepo.UserRepository();
      await backend.updateProfile(
        firstName: firstName ?? '',
        lastName: lastName ?? '',
        email: email ?? '',
      );

      final existingUser = await _userRepository.getUserData(_localId!);
      if (existingUser == null) {
        final newUser = localRepo.UserModel(
          uid: _localId!,
          phoneNumber: _phoneNumber ?? '',
          createdAt: DateTime.now(),
          firstName: firstName,
          lastName: lastName,
          reraNumber: reraNumber,
          customData: {'email': email, 'needsRegistration': false},
        );
        final success = await _userRepository.createUser(newUser);
        if (success) {
          _userData = newUser;
          notifyListeners();
        }
        return success;
      } else {
        final updatedUser = existingUser.copyWith(
          firstName: firstName,
          lastName: lastName,
          reraNumber: reraNumber,
          customData: {
            ...existingUser.customData,
            'email': email,
            'needsRegistration': false,
          },
        );
        final success = await _userRepository.updateUser(updatedUser);
        if (success) {
          _userData = updatedUser;
          notifyListeners();
        }
        return success;
      }
    } catch (e) {
      print('❌ registerNewUser error: $e');
      return false;
    }
  }

  bool get needsRegistration {
    if (_userData == null) return true;
    return _userData!.firstName.isEmpty || _userData!.lastName.isEmpty;
  }

  // ---------------------------------------------------------------------------
  // 🔹 Logout + Timer
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    setLoading(true);
    try {
      await _auth.signOut();
      _localId = null;
      _phoneNumber = null;
      _verificationId = null;
      _isLoggedIn = false;
      _userData = null;
      await _saveLoginState(false);
    } catch (e) {
      print("signOut error: $e");
    } finally {
      setLoading(false);
    }
  }

  void _startResendTimer() {
    _canResend = false;
    _remainingSeconds = 30;
    notifyListeners();

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _canResend = true;
        _resendTimer?.cancel();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
