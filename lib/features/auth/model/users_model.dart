import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final DateTime createdAt;
  final String firstName;
  final String lastName;
  final String? reraNumber;
  final Map<String, dynamic> customData;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.createdAt,
    required this.firstName,
    required this.lastName,
    this.reraNumber,
    required this.customData,
  });

  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.parse(data['createdAt']))
              : DateTime.now(),
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      reraNumber: data['reraNumber'],
      customData: data['customData'] ?? {},
    );
  }

factory UserModel.minimal(
  String uid,
  String phoneNumber, {
  String firstName = '',
  String lastName = '',
}) {
  return UserModel(
    uid: uid,
    phoneNumber: phoneNumber,
    createdAt: DateTime.now(),
    firstName: firstName,
    lastName: lastName,
    reraNumber: null,
    customData: {},
  );
}

  
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'firstName': firstName,
      'lastName': lastName,
      'reraNumber': reraNumber,
      'customData': customData,
    };
  }

  
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? reraNumber,
    Map<String, dynamic>? customData,
  }) {
    return UserModel(
      uid: this.uid,
      phoneNumber: this.phoneNumber,
      createdAt: this.createdAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      reraNumber: reraNumber ?? this.reraNumber,
      customData: customData ?? this.customData,
    );
  }
}

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<bool> userExists(String phoneNumber) async {
    try {
      final formattedPhone =
          phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      print('Checking user existence for: $formattedPhone');

      final result =
          await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: formattedPhone)
              .limit(1)
              .get();

      print('User found: ${result.docs.isNotEmpty}');
      if (result.docs.isNotEmpty) {
        print('Document: ${result.docs.first.data()}');
      }

      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  
  Future<UserModel?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      final formattedPhone =
          phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      final QuerySnapshot result =
          await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: formattedPhone)
              .limit(1)
              .get();

      if (result.docs.isNotEmpty) {
        return UserModel.fromFirestore(result.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by phone: $e');
      return null;
    }
  }

  
  Future<bool> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  
  Future<bool> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }


}