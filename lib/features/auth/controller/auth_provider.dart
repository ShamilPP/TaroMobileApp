import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taro_mobile/features/auth/model/users_model.dart';
import 'package:taro_mobile/features/auth/repository/auth_repository.dart';
import 'package:taro_mobile/features/auth/repository/user_repository.dart' as backendUserRepo;
import 'package:taro_mobile/core/models/api_models.dart' as userModel;
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _canResend = true;
  int _remainingSeconds = 0;
  Timer? _resendTimer;
  String? _verificationId; // Firebase verification ID instead of sessionInfo
  int? _resendToken; // Used for resending OTP
  String? _localId;
  String? _phoneNumber;
  bool _isLoggedIn = false;
  UserModel? _userData;
  bool _isInitialized = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  bool get isLoading => _isLoading;
  bool get canResend => _canResend;
  int get remainingSeconds => _remainingSeconds;
  bool get isLoggedIn => _isLoggedIn;
  String? get localId => _localId;
  String? get phoneNumber => _phoneNumber;
  UserModel? get userData => _userData;
  bool get isInitialized => _isInitialized;
  Completer<void> get initializationCompleter => _initializationCompleter;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Check Firebase Auth state
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // User is authenticated with Firebase
        _localId = currentUser.uid;
        _phoneNumber = currentUser.phoneNumber;
        _isLoggedIn = true;

        // Validate user is still authenticated by checking token
        try {
          await currentUser.getIdToken();
          await _saveLoginState(true);
        } catch (e) {
          print('Error getting ID token: $e');
          // If token fetch fails, user might be signed out
          await _auth.signOut();
          _isLoggedIn = false;
          await _saveLoginState(false);
          _userData = null;
          _localId = null;
          _phoneNumber = null;
        }

        if (_isLoggedIn && _localId != null) {
          await _fetchUserData();
        }
      } else {
        // No user signed in
        _isLoggedIn = false;
        await _saveLoginState(false);
        _userData = null;
        _localId = null;
        _phoneNumber = null;
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

  Future<bool> isAuthenticated() async {
    if (!_isInitialized) {
      try {
        await _initializationCompleter.future;
      } catch (e) {
        print('Error waiting for initialization: $e');
        return false;
      }
    }

    return _isLoggedIn && _localId != null;
  }

  Future<void> _saveLoginState(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isLoggedIn);

      if (isLoggedIn) {
        // Store minimal state - Firebase Auth manages tokens
        if (_localId != null) await prefs.setString('localId', _localId!);
        if (_phoneNumber != null) await prefs.setString('phoneNumber', _phoneNumber!);
        // ID token will be fetched from Firebase when needed
      } else {
        await prefs.remove('localId');
        await prefs.remove('phoneNumber');
      }
    } catch (e) {
      print('Error saving login state: $e');
    }
  }

  Future<void> _fetchUserData({String firstName = '', String lastName = ''}) async {
    if (_localId != null) {
      try {
        final UserModel? user = await _userRepository.getUserData(_localId!);

        if (user != null) {
          _userData = user;
        } else {
          _userData = UserModel.minimal(_localId!, _phoneNumber ?? '', firstName: firstName, lastName: lastName);

          await _userRepository.createUser(_userData!);
        }

        notifyListeners();
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<bool> userExistsByPhone(String phoneNumber) async {
    try {
      return await _userRepository.userExists(phoneNumber);
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      return await _userRepository.getUserByPhone(phoneNumber);
    } catch (e) {
      print('Error getting user by phone: $e');
      return null;
    }
  }

  Future<void> refreshUserData() async {
    if (_localId != null) {
      return _fetchUserData();
    }
  }

  Future<void> saveUserData(Map<String, dynamic> data) async {
    if (_localId != null && _userData != null) {
      try {
        final updatedUser = _userData!.copyWith(
          firstName: data['firstName'],
          lastName: data['lastName'],
          email: data['email'],
          reraNumber: data['reraNumber'],
          customData: data['customData'] ?? _userData!.customData,
        );

        _userData = updatedUser;
        notifyListeners();

        await _userRepository.updateUser(updatedUser);
      } catch (e) {
        print('Error saving user data: $e');

        await _fetchUserData();
        throw e;
      }
    }
  }

  Future<bool> registerNewUser({required String firstName, required String lastName, String? reraNumber, String? email}) async {
    if (_localId == null) {
      return false;
    }

    try {
      // First update backend profile
      final backendRepo = backendUserRepo.UserRepository();
      try {
        await backendRepo.updateProfile(firstName: firstName, lastName: lastName, email: email);
      } catch (e) {
        print('Error updating backend profile: $e');
        // Continue with Firestore update even if backend fails
      }

      // Then update/create Firestore user
      final existingUser = await _userRepository.getUserData(_localId!);

      if (existingUser == null) {
        final newUser = UserModel(
          uid: _localId!,
          phoneNumber: _phoneNumber ?? '',
          createdAt: DateTime.now(),
          firstName: firstName,
          lastName: lastName,
          reraNumber: reraNumber,
          customData: {'email': email},
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
          customData: {...existingUser.customData, 'email': email, 'needsRegistration': false},
        );
        final success = await _userRepository.updateUser(updatedUser);
        if (success) {
          _userData = updatedUser;
          notifyListeners();
        }
        return success;
      }
    } catch (e) {
      print('Error registering new user: $e');
      return false;
    }
  }

  Future<void> sendOTP(String phoneNumber, Function(String verificationId, int? resendToken) onCodeSent, Function(dynamic e) onVerificationFailed) async {
    _isLoading = true;
    notifyListeners();

    try {
      final formattedPhone = phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      await _authRepository.sendVerificationCode(
        phoneNumber: formattedPhone,
        onCodeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _phoneNumber = formattedPhone;
          _isLoading = false;

          _startResendTimer();

          notifyListeners();
          onCodeSent(verificationId, resendToken);
        },
        onVerificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          onVerificationFailed(e);
        },
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android)
          try {
            await verifyCredential(credential);
          } catch (e) {
            onVerificationFailed(e);
          }
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onVerificationFailed(e);
    }
  }

  Future<void> verifyOTP(String otp) async {
    if (_verificationId == null) {
      throw Exception('Verification ID not found. Please request OTP again.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Step 1: Sign in with Firebase to get idToken
      final firebaseResponse = await _authRepository.signInWithPhoneNumber(verificationId: _verificationId!, code: otp);

      if (!firebaseResponse.success) {
        throw Exception('Invalid OTP');
      }

      // Step 2: Verify phone with backend API to sync user data
      final verifyResponse = await _authRepository.verifyPhone(idToken: firebaseResponse.idToken);

      if (verifyResponse.success) {
        _localId = verifyResponse.user.uid; // Use backend user UID
        _phoneNumber = verifyResponse.user.phoneNumber;
        _isLoggedIn = true;

        await _saveLoginState(true);

        // Sync with Firestore user data
        await _syncUserDataFromBackend(verifyResponse.user);

        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Failed to verify phone with backend');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Helper method to verify credential (used for auto-verification)
  Future<void> verifyCredential(PhoneAuthCredential credential) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign in with credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in');
      }

      // Get ID token
      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      // Step 2: Verify phone with backend API to sync user data
      final verifyResponse = await _authRepository.verifyPhone(idToken: idToken);

      if (verifyResponse.success) {
        _localId = verifyResponse.user.uid;
        _phoneNumber = verifyResponse.user.phoneNumber;
        _isLoggedIn = true;

        await _saveLoginState(true);

        // Sync with Firestore user data
        await _syncUserDataFromBackend(verifyResponse.user);

        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Failed to verify phone with backend');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _syncUserDataFromBackend(userModel.UserModel backendUser) async {
    try {
      // Check if user exists in Firestore
      final existingUser = await _userRepository.getUserData(backendUser.uid);

      // Check if user needs registration (firstName is just phone number or empty)
      final needsRegistration = backendUser.firstName.isEmpty || backendUser.firstName == backendUser.phoneNumber.replaceAll(RegExp(r'[^\d]'), '') || backendUser.lastName.isEmpty;

      if (existingUser == null) {
        // Create new user in Firestore
        final newUser = UserModel(
          uid: backendUser.uid,
          phoneNumber: backendUser.phoneNumber,
          createdAt: DateTime.now(),
          firstName: backendUser.firstName.isNotEmpty && !needsRegistration ? backendUser.firstName : '',
          lastName: backendUser.lastName.isNotEmpty && !needsRegistration ? backendUser.lastName : '',
          reraNumber: null,
          customData: {'role': backendUser.role, 'orgId': backendUser.orgId, 'email': backendUser.email, 'needsRegistration': needsRegistration},
        );
        await _userRepository.createUser(newUser);
        _userData = newUser;
      } else {
        // Update existing user data
        final updatedUser = existingUser.copyWith(
          firstName: backendUser.firstName.isNotEmpty && !needsRegistration ? backendUser.firstName : existingUser.firstName,
          lastName: backendUser.lastName.isNotEmpty && !needsRegistration ? backendUser.lastName : existingUser.lastName,
          email: backendUser.email ?? existingUser.customData['email'],
          customData: {...existingUser.customData, 'role': backendUser.role, 'orgId': backendUser.orgId, 'email': backendUser.email, 'needsRegistration': needsRegistration},
        );
        await _userRepository.updateUser(updatedUser);
        _userData = updatedUser;
      }
    } catch (e) {
      print('Error syncing user data from backend: $e');
      // Continue even if sync fails
    }
  }

  bool get needsRegistration {
    if (_userData == null) return true;

    // Check if firstName is empty or just phone number
    final firstName = _userData!.firstName.trim();
    final phoneDigits = _phoneNumber?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

    return firstName.isEmpty || firstName == phoneDigits || _userData!.lastName.trim().isEmpty;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out from Firebase
      await _auth.signOut();

      _localId = null;
      _phoneNumber = null;
      _verificationId = null;
      _resendToken = null;
      _isLoggedIn = false;
      _userData = null;
      await _saveLoginState(false);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void _startResendTimer() {
    _canResend = false;
    _remainingSeconds = 30;
    notifyListeners();

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
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

  String formatTime(int seconds) {
    return '${seconds}s';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
