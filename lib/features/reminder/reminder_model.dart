import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String? id;
  final String userId;
  final String? userEmail;
  final String reminderType;
  final String leadName;
  final String property;
  final String date;
  final String time;
  final String note;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReminderModel({
    this.id,
    required this.userId,
    this.userEmail,
    required this.reminderType,
    required this.leadName,
    required this.property,
    required this.date,
    required this.time,
    required this.note,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'reminderType': reminderType,
      'leadName': leadName,
      'property': property,
      'date': date,
      'time': time,
      'note': note,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  
  factory ReminderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReminderModel(
      id: documentId,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'],
      reminderType: map['reminderType'] ?? '',
      leadName: map['leadName'] ?? '',
      property: map['property'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      note: map['note'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  
  factory ReminderModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ReminderModel.fromMap(data, snapshot.id);
  }

  
  ReminderModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? reminderType,
    String? leadName,
    String? property,
    String? date,
    String? time,
    String? note,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      reminderType: reminderType ?? this.reminderType,
      leadName: leadName ?? this.leadName,
      property: property ?? this.property,
      date: date ?? this.date,
      time: time ?? this.time,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReminderModel(id: $id, userId: $userId, userEmail: $userEmail, reminderType: $reminderType, leadName: $leadName, property: $property, date: $date, time: $time, note: $note, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}