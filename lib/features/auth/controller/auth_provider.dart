import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taro_mobile/features/auth/model/users_model.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository = UserRepository();

  bool _isLoading = false;
  bool _canResend = true;
  int _remainingSeconds = 0;
  Timer? _resendTimer;
  String? _verificationId;
  bool _isLoggedIn = false;
  User? _currentUser;
  UserModel? _userData;
  bool _isInitialized = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  
  bool get isLoading => _isLoading;
  bool get canResend => _canResend;
  int get remainingSeconds => _remainingSeconds;
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  UserModel? get userData => _userData;
  bool get isInitialized => _isInitialized;
  Completer<void> get initializationCompleter => _initializationCompleter;

  AuthProvider() {
    
    _initializeAuth();
  }

  
  Future<void> _initializeAuth() async {
    try {
      
      _currentUser = _auth.currentUser;

      if (_currentUser != null) {
        
        _isLoggedIn = true;
        await _saveLoginState(true);
        await _fetchUserData();
      } else {
        
        final prefs = await SharedPreferences.getInstance();
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

        
        if (_isLoggedIn) {
          _isLoggedIn = false;
          await _saveLoginState(false);
        }
      }

      
      _auth.authStateChanges().listen((User? user) async {
        _currentUser = user;
        if (user != null) {
          _isLoggedIn = true;
          await _saveLoginState(true);
          await _fetchUserData();
        } else {
          _isLoggedIn = false;
          await _saveLoginState(false);
          _userData = null;
        }
        notifyListeners();
      });

      
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

    
    return _isLoggedIn && _auth.currentUser != null;
  }

  
  Future<void> _saveLoginState(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isLoggedIn);
    } catch (e) {
      print('Error saving login state: $e');
    }
  }

  
  
  
  
  
  

  
  
  
  
  
  
  
  
  
  

  
  
  

  
  
  
  
  
  

  Future<void> _fetchUserData({
    String firstName = '',
    String lastName = '',
  }) async {
    if (_currentUser != null) {
      try {
        final UserModel? user = await _userRepository.getUserData(
          _currentUser!.uid,
        );

        if (user != null) {
          _userData = user;
        } else {
          
          _userData = UserModel.minimal(
            _currentUser!.uid,
            _currentUser!.phoneNumber ?? '',
            firstName: firstName,
            lastName: lastName,
          );

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
    if (_currentUser != null) {
      return _fetchUserData();
    }
  }

  
  Future<void> saveUserData(Map<String, dynamic> data) async {
    if (_currentUser != null && _userData != null) {
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

  
  Future<bool> registerNewUser({
    required String firstName,
    required String lastName,
    String? reraNumber,
  }) async {
    if (_currentUser == null) {
      return false;
    }

    try {
      final newUser = UserModel(
        uid: _currentUser!.uid,
        phoneNumber: _currentUser!.phoneNumber ?? '',
        createdAt: DateTime.now(),
        firstName: firstName,
        lastName: lastName,
        reraNumber: reraNumber,
        customData: {},
      );

      final success = await _userRepository.createUser(newUser);
      if (success) {
        _userData = newUser;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error registering new user: $e');
      return false;
    }
  }

  
  Future<void> sendOTP(
    String phoneNumber,
    Function(String verificationId, int? resendToken) onCodeSent,
    Function(FirebaseAuthException e) onVerificationFailed,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;

          
          _startResendTimer();

          notifyListeners();
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  
  Future<UserCredential> verifyOTP(String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await _signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  
  Future<UserCredential> _signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      _isLoading = false;
      _isLoggedIn = true;
      
      
      notifyListeners();
      return userCredential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
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