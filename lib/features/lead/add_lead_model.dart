import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

class LeadModel {
  String? id;
  String name;
  String userId;
  String gender;
  String phoneNumber;
  String? whatsappNumber;
  bool? sameAsPhone;
  String leadType;
  String leadCategory;
  String propertyType;
  DateTime createdAt;
  DateTime updatedAt;
  String status;
  String? notes;
  String? source;
  Color? avatarColor; // New field for avatar color

  LeadModel({
    this.id,
    required this.name,
    required this.userId,
    required this.gender,
    required this.phoneNumber,
    this.whatsappNumber,
    this.sameAsPhone,
    required this.leadType,
    this.leadCategory = '',
    required this.propertyType,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = 'New Lead',
    this.notes,
    this.source,
    this.avatarColor, // Add to constructor
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'sameAsPhone': sameAsPhone,
      'leadType': leadType,
      'leadCategory': leadCategory,
      'propertyType': propertyType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'notes': notes,
      'source': source,
      'avatarColor': avatarColor?.value, // Store color as int
    };
  }

  factory LeadModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LeadModel(
      id: documentId,
      name: map['name'] ?? '',
      userId: map['userId'] ?? '',
      gender: map['gender'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      whatsappNumber: map['whatsappNumber'],
      sameAsPhone: map['sameAsPhone'],
      leadType: map['leadType'] ?? '',
      leadCategory: map['leadCategory'] ?? '',
      propertyType: map['propertyType'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'Active',
      notes: map['notes'],
      source: map['source'],
      avatarColor:
          map['avatarColor'] != null
              ? Color(map['avatarColor'])
              : null, // Parse color from int
    );
  }

  get selectedBHK => null;

  LeadModel copyWith({
    String? id,
    String? name,
    String? userId,
    String? gender,
    String? phoneNumber,
    String? whatsappNumber,
    bool? sameAsPhone,
    String? leadType,
    String? leadCategory,
    String? propertyType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? notes,
    String? source,
    Color? avatarColor, // Add to copyWith method
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      sameAsPhone: sameAsPhone ?? this.sameAsPhone,
      leadType: leadType ?? this.leadType,
      leadCategory: leadCategory ?? this.leadCategory,
      propertyType: propertyType ?? this.propertyType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      avatarColor: avatarColor ?? this.avatarColor, // Add to copyWith
    );
  }
}

abstract class BaseProperty {
  String? id;
  String leadId;
  String propertyFor;
  String? askingPrice;
  String? budgetRange;
  String? location;
  String? preferredLocation;
  String? additionalNotes;
  String? leadDuration;
  DateTime createdAt;
  DateTime updatedAt;
  String status;
  String selectedSubType = '';

  BaseProperty({
    this.id,
    required this.leadId,
    required this.propertyFor,
    this.askingPrice,
    this.budgetRange,
    this.location,
    this.preferredLocation,
    this.additionalNotes,
    this.leadDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = 'Available',
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  get propertyType => null;

  Map<String, dynamic> toMap();
}

class ResidentialProperty extends BaseProperty {
  String propertySubType;
  String? selectedBHK;
  String? squareFeet;
  bool furnished;
  bool unfurnished;
  bool semiFinished;
  List<String> facilities;
  List<String> preferences;
  bool preferFurnished;
  bool preferUnfurnished;
  bool preferSemiFurnished;
  String? workingProfessional;

  String? deposit;
  String? vegOrNonVeg;
  String? maintenance;
  String? bathroomAttached;
  String? bathroomCommon;

  ResidentialProperty({
    super.id,
    required super.leadId,
    required super.propertyFor,
    super.askingPrice,
    super.budgetRange,
    super.location,
    super.preferredLocation,
    super.additionalNotes,
    super.leadDuration,
    super.createdAt,
    super.updatedAt,
    super.status,
    this.propertySubType = '',
    this.selectedBHK,
    this.squareFeet,
    this.furnished = false,
    this.unfurnished = false,
    this.semiFinished = false,
    this.facilities = const [],
    this.preferences = const [],
    this.preferFurnished = false,
    this.preferUnfurnished = false,
    this.preferSemiFurnished = false,

    this.deposit,
    this.vegOrNonVeg,
    this.workingProfessional,
    this.maintenance,
    this.bathroomAttached,
    this.bathroomCommon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'leadId': leadId,
      'propertyFor': propertyFor,
      'propertyType': 'Residential',
      'askingPrice': askingPrice,
      'budgetRange': budgetRange,
      'location': location,
      'preferredLocation': preferredLocation,
      'additionalNotes': additionalNotes,
      'leadDuration': leadDuration,
      'propertySubType': propertySubType,
      'selectedBHK': selectedBHK,
      'squareFeet': squareFeet,
      'furnished': furnished,
      'unfurnished': unfurnished,
      'semiFinished': semiFinished,
      'facilities': facilities,
      'preferences': preferences,
      'preferFurnished': preferFurnished,
      'preferUnfurnished': preferUnfurnished,
      'preferSemiFurnished': preferSemiFurnished,

      'deposit': deposit,
      'vegOrNonVeg': vegOrNonVeg,
      'workingProfessional': workingProfessional,
      'maintenance': maintenance,
      'bathroomAttached': bathroomAttached,
      'bathroomCommon': bathroomCommon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  factory ResidentialProperty.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ResidentialProperty(
      id: documentId,
      leadId: map['leadId'] ?? '',
      propertyFor: map['propertyFor'] ?? '',
      askingPrice: map['askingPrice'],
      budgetRange: map['budgetRange'],
      location: map['location'],
      preferredLocation: map['preferredLocation'],
      additionalNotes: map['additionalNotes'],
      leadDuration: map['leadDuration'],
      propertySubType: map['propertySubType'] ?? '',
      selectedBHK: map['selectedBHK'],
      squareFeet: map['squareFeet'],
      furnished: map['furnished'] ?? false,
      unfurnished: map['unfurnished'] ?? false,
      semiFinished: map['semiFinished'] ?? false,
      facilities: List<String>.from(map['facilities'] ?? []),
      preferences: List<String>.from(map['preferences'] ?? []),
      preferFurnished: map['preferFurnished'] ?? false,
      preferUnfurnished: map['preferUnfurnished'] ?? false,
      preferSemiFurnished: map['preferSemiFurnished'] ?? false,
      workingProfessional: map['workingProfessional'],

      deposit: map['deposit'],
      vegOrNonVeg: map['vegOrNonVeg'],
      maintenance: map['maintenance'],
      bathroomAttached: map['bathroomAttached'],
      bathroomCommon: map['bathroomCommon'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'New Lead',
    );
  }

  ResidentialProperty copyWith({
    String? id,
    String? leadId,
    String? propertyFor,
    String? askingPrice,
    String? budgetRange,
    String? location,
    String? preferredLocation,
    String? additionalNotes,
    String? leadDuration,
    String? propertySubType,
    String? selectedBHK,
    String? squareFeet,
    bool? furnished,
    bool? unfurnished,
    bool? semiFinished,
    List<String>? facilities,
    List<String>? preferences,
    bool? preferFurnished,
    bool? preferUnfurnished,
    bool? preferSemiFurnished,
    String? workingProfessional,

    String? deposit,
    String? vegOrNonVeg,
    String? maintenance,
    String? bathroomAttached,
    String? bathroomCommon,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return ResidentialProperty(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      propertyFor: propertyFor ?? this.propertyFor,
      askingPrice: askingPrice ?? this.askingPrice,
      budgetRange: budgetRange ?? this.budgetRange,
      location: location ?? this.location,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      leadDuration: leadDuration ?? this.leadDuration,
      propertySubType: propertySubType ?? this.propertySubType,
      selectedBHK: selectedBHK ?? this.selectedBHK,
      squareFeet: squareFeet ?? this.squareFeet,
      furnished: furnished ?? this.furnished,
      unfurnished: unfurnished ?? this.unfurnished,
      semiFinished: semiFinished ?? this.semiFinished,
      facilities: facilities ?? this.facilities,
      preferences: preferences ?? this.preferences,
      preferFurnished: preferFurnished ?? this.preferFurnished,
      preferUnfurnished: preferUnfurnished ?? this.preferUnfurnished,
      preferSemiFurnished: preferSemiFurnished ?? this.preferSemiFurnished,
      workingProfessional: workingProfessional ?? this.workingProfessional,

      deposit: deposit ?? this.deposit,
      vegOrNonVeg: vegOrNonVeg ?? this.vegOrNonVeg,
      maintenance: maintenance ?? this.maintenance,
      bathroomAttached: bathroomAttached ?? this.bathroomAttached,
      bathroomCommon: bathroomCommon ?? this.bathroomCommon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status,
    );
  }
}

class CommercialProperty extends BaseProperty {
  String propertySubType;
  String? squareFeet;
  String? requiredSquareFeet;
  String? furnished;
  String? requiredFromDate;
  String? noOfSeats;
  String? washrooms;
  List<String>? facilities; // Changed from String? to List<String>?

  CommercialProperty({
    super.id,
    required super.leadId,
    required super.propertyFor,
    super.askingPrice,
    super.budgetRange,
    super.location,
    super.preferredLocation,
    super.additionalNotes,
    super.leadDuration,
    super.createdAt,
    super.updatedAt,
    super.status,
    this.propertySubType = '',
    this.squareFeet,
    this.requiredSquareFeet,
    this.facilities,
    this.furnished,
    this.requiredFromDate,
    this.noOfSeats,
    this.washrooms,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'leadId': leadId,
      'propertyFor': propertyFor,
      'propertyType': 'Commercial',
      'askingPrice': askingPrice,
      'budgetRange': budgetRange,
      'location': location,
      'preferredLocation': preferredLocation,
      'additionalNotes': additionalNotes,
      'leadDuration': leadDuration,
      'propertySubType': propertySubType,
      'squareFeet': squareFeet,
      'requiredSquareFeet': requiredSquareFeet,
      'furnished': furnished,
      'requiredFromDate': requiredFromDate,
      'facilities': facilities, // Now stores as List<String>
      'washrooms': washrooms,
      'noOfSeats': noOfSeats,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  factory CommercialProperty.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return CommercialProperty(
      id: documentId,
      leadId: map['leadId'] ?? '',
      propertyFor: map['propertyFor'] ?? '',
      askingPrice: map['askingPrice'],
      budgetRange: map['budgetRange'],
      location: map['location'],
      preferredLocation: map['preferredLocation'],
      additionalNotes: map['additionalNotes'],
      leadDuration: map['leadDuration'],
      propertySubType: map['propertySubType'] ?? '',
      squareFeet: map['squareFeet'],
      requiredSquareFeet: map['requiredSquareFeet'],
      noOfSeats: map['noOfSeats'],
      furnished: map['furnished'],
      requiredFromDate: map['requiredFromDate'],
      // Handle both List<String> and String formats for backward compatibility
      facilities:
          map['facilities'] is List
              ? List<String>.from(map['facilities'])
              : (map['facilities'] is String && map['facilities'].isNotEmpty)
              ? map['facilities'].split(',').map((e) => e.trim()).toList()
              : null,
      washrooms: map['washrooms'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'Available',
    );
  }

  CommercialProperty copyWith({
    String? id,
    String? leadId,
    String? propertyFor,
    String? askingPrice,
    String? budgetRange,
    String? location,
    String? preferredLocation,
    String? additionalNotes,
    String? leadDuration,
    String? propertySubType,
    String? squareFeet,
    String? requiredSquareFeet,
    bool? officeSpace,
    bool? shop,
    bool? restaurant,
    bool? other,
    String? businessType,
    String? requiredFromDate,
    List<String>? facilities, // Changed from String? to List<String>?
    String? furnished,
    String? noOfSeats,
    String? additionalRequirements,
    bool? needOfficeSpace,
    bool? needRetailSpace,
    bool? needRestaurantSpace,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? washrooms,
  }) {
    return CommercialProperty(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      propertyFor: propertyFor ?? this.propertyFor,
      askingPrice: askingPrice ?? this.askingPrice,
      budgetRange: budgetRange ?? this.budgetRange,
      location: location ?? this.location,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      leadDuration: leadDuration ?? this.leadDuration,
      propertySubType: propertySubType ?? this.propertySubType,
      squareFeet: squareFeet ?? this.squareFeet,
      requiredSquareFeet: requiredSquareFeet ?? this.requiredSquareFeet,
      noOfSeats: noOfSeats ?? this.noOfSeats,
      requiredFromDate: requiredFromDate ?? this.requiredFromDate,
      facilities: facilities ?? this.facilities,
      washrooms: washrooms ?? this.washrooms,
      furnished: furnished ?? this.furnished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status,
    );
  }
}

class LandProperty extends BaseProperty {
  String propertySubType;
  String? squareFeet;
  String? acres;
  String? cents;
  String? inputUnit;
  String? additionalRequirements;

  LandProperty({
    super.id,
    required super.leadId,
    required super.propertyFor,
    super.askingPrice,
    super.budgetRange,
    super.location,
    super.preferredLocation,
    super.additionalNotes,
    super.leadDuration,
    super.createdAt,
    super.updatedAt,
    super.status,
    this.propertySubType = '',
    this.squareFeet,
    this.acres,
    this.cents,
    this.inputUnit,
    this.additionalRequirements,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'leadId': leadId,
      'propertyFor': propertyFor,
      'propertyType': 'Land',
      'askingPrice': askingPrice,
      'budgetRange': budgetRange,
      'location': location,
      'preferredLocation': preferredLocation,
      'additionalNotes': additionalNotes,
      'leadDuration': leadDuration,
      'propertySubType': propertySubType,
      'squareFeet': squareFeet,
      'acres': acres,
      'cents': cents,
      'inputUnit': inputUnit,
      'additionalRequirements': additionalRequirements,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  factory LandProperty.fromMap(Map<String, dynamic> map, String documentId) {
    return LandProperty(
      id: documentId,
      leadId: map['leadId'] ?? '',
      propertyFor: map['propertyFor'] ?? '',
      askingPrice: map['askingPrice'],
      budgetRange: map['budgetRange'],
      location: map['location'],
      preferredLocation: map['preferredLocation'],
      additionalNotes: map['additionalNotes'],
      leadDuration: map['leadDuration'],
      propertySubType: map['propertySubType'] ?? '',
      squareFeet: map['squareFeet'],
      acres: map['acres'],
      cents: map['cents'],
      inputUnit: map['inputUnit'],
      additionalRequirements: map['additionalRequirements'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'Available',
    );
  }

  LandProperty copyWith({
    String? id,
    String? leadId,
    String? propertyFor,
    String? askingPrice,
    String? budgetRange,
    String? location,
    String? preferredLocation,
    String? additionalNotes,
    String? leadDuration,
    String? propertySubType,
    String? squareFeet,
    String? acres,
    String? cents,
    String? inputUnit,
    String? additionalRequirements,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return LandProperty(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      propertyFor: propertyFor ?? this.propertyFor,
      askingPrice: askingPrice ?? this.askingPrice,
      budgetRange: budgetRange ?? this.budgetRange,
      location: location ?? this.location,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      leadDuration: leadDuration ?? this.leadDuration,
      propertySubType: propertySubType ?? this.propertySubType,
      squareFeet: squareFeet ?? this.squareFeet,
      acres: acres ?? this.acres,
      cents: cents ?? this.cents,
      inputUnit: inputUnit ?? this.inputUnit,
      additionalRequirements:
          additionalRequirements ?? this.additionalRequirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status,
    );
  }
}

extension ResidentialPropertyFirestore on ResidentialProperty {
  static ResidentialProperty fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ResidentialProperty.fromMap(data, doc.id);
  }
}

extension CommercialPropertyFirestore on CommercialProperty {
  static CommercialProperty fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommercialProperty.fromMap(data, doc.id);
  }
}

extension LandPropertyFirestore on LandProperty {
  static LandProperty fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LandProperty.fromMap(data, doc.id);
  }
}
