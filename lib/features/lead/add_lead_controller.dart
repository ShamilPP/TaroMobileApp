import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/features/home/controller/lead_controller.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:taro_mobile/features/lead/location_picker.dart';

class NewLeadProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LeadModel _leadModel = LeadModel(
    id: '',
    userId: '',
    name: '',
    gender: '',
    phoneNumber: '',
    leadType: '',
    propertyType: '',
  );

  BaseProperty? _currentProperty;
  String _selectedPropertyType = '';

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  LeadModel get leadModel => _leadModel;
  BaseProperty? get currentProperty => _currentProperty;
  String get selectedPropertyType => _selectedPropertyType;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;

  ResidentialProperty? get residentialProperty =>
      _currentProperty is ResidentialProperty
          ? _currentProperty as ResidentialProperty
          : null;
  CommercialProperty? get commercialProperty =>
      _currentProperty is CommercialProperty
          ? _currentProperty as CommercialProperty
          : null;

  LandProperty? get landProperty =>
      _currentProperty is LandProperty
          ? _currentProperty as LandProperty
          : null;

  void updateStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  String? get vegOrNonVeg => residentialProperty?.vegOrNonVeg;

  void updateVegOrNonVeg(String option) {
    if (residentialProperty != null) {
      residentialProperty!.vegOrNonVeg = option;
      notifyListeners();
    }
  }

  String? get workingProfessionals => residentialProperty?.workingProfessional;

  void updateWorkingProfessionals(String? option) {
    if (residentialProperty != null) {
      residentialProperty!.workingProfessional = option;
      notifyListeners();
    }
  }

  void updateCommercialFurnishingType(String type) {
    print(
      'Before update - Current furnished: ${commercialProperty?.furnished}',
    );

    if (commercialProperty == null) {
      print('Error: commercialProperty is null');
      return;
    }

    String? newFurnishedValue;

    if (commercialProperty!.furnished == type) {
      newFurnishedValue = null;
      print('Deselecting furnishing type');
    } else {
      newFurnishedValue = type;
      print('Setting furnishing type to: $type');
    }

    commercialProperty!.furnished = newFurnishedValue;
    commercialProperty!.updatedAt = DateTime.now();

    print('After update - New furnished: ${commercialProperty?.furnished}');

    notifyListeners();
  }

  String? selectedAreaUnit = 'Square Feet';

  void setSelectedAreaUnit(String unit) {
    selectedAreaUnit = unit;
    notifyListeners();
  }

  void selectPropertySubType(String subType) {
    print('Selecting property subtype: $subType');

    if (_currentProperty != null) {
      switch (_currentProperty.runtimeType) {
        case ResidentialProperty:
          _currentProperty = residentialProperty!.copyWith(
            propertySubType: subType,
          );
          print(
            'Updated Residential propertySubType: ${residentialProperty!.propertySubType}',
          );
          break;
        case CommercialProperty:
          _currentProperty = commercialProperty!.copyWith(
            propertySubType: subType,
          );
          print(
            'Updated Commercial propertySubType: ${commercialProperty!.propertySubType}',
          );
          break;
        case LandProperty:
          _currentProperty = landProperty!.copyWith(propertySubType: subType);
          print(
            'Updated Land propertySubType: ${landProperty!.propertySubType}',
          );
          break;
      }
      notifyListeners();
    } else {
      print('ERROR: _currentProperty is null when trying to select subtype');
    }
  }

  String get selectedSubType {
    if (_currentProperty == null) return '';

    switch (_currentProperty.runtimeType) {
      case ResidentialProperty:
        return residentialProperty?.propertySubType ?? '';
      case CommercialProperty:
        return commercialProperty?.propertySubType ?? '';
      case LandProperty:
        return landProperty?.propertySubType ?? '';
      default:
        return '';
    }
  }

  void updatePropertyType(String propertyType) {
    _selectedPropertyType = propertyType;

    String leadId = _currentProperty?.leadId ?? _leadModel.id ?? '';
    String propertyFor = _currentProperty?.propertyFor ?? '';

    String existingSubType = '';
    if (_currentProperty != null) {
      switch (_currentProperty.runtimeType) {
        case ResidentialProperty:
          existingSubType =
              (propertyType == 'Residential')
                  ? residentialProperty!.propertySubType
                  : '';
          break;
        case CommercialProperty:
          existingSubType =
              (propertyType == 'Commercial')
                  ? commercialProperty!.propertySubType
                  : '';
          break;
        case LandProperty:
          existingSubType =
              (propertyType == 'Plot') ? landProperty!.propertySubType : '';
          break;
      }
    }

    switch (propertyType) {
      case 'Residential':
        _currentProperty = ResidentialProperty(
          leadId: leadId,
          propertyFor: propertyFor,
          id: _currentProperty?.id,
          askingPrice: _currentProperty?.askingPrice,
          budgetRange: _currentProperty?.budgetRange,
          location: _currentProperty?.location,
          preferredLocation: _currentProperty?.preferredLocation,
          additionalNotes: _currentProperty?.additionalNotes,
          status: _currentProperty?.status ?? 'Available',
          propertySubType: existingSubType,
        );
        break;
      case 'Commercial':
        _currentProperty = CommercialProperty(
          leadId: leadId,
          propertyFor: propertyFor,
          id: _currentProperty?.id,
          askingPrice: _currentProperty?.askingPrice,
          budgetRange: _currentProperty?.budgetRange,
          location: _currentProperty?.location,
          preferredLocation: _currentProperty?.preferredLocation,
          additionalNotes: _currentProperty?.additionalNotes,
          status: _currentProperty?.status ?? 'Available',
          propertySubType: existingSubType,
        );
        break;
      case 'Plot':
        _currentProperty = LandProperty(
          leadId: leadId,
          propertyFor: propertyFor,
          id: _currentProperty?.id,
          askingPrice: _currentProperty?.askingPrice,
          budgetRange: _currentProperty?.budgetRange,
          location: _currentProperty?.location,
          preferredLocation: _currentProperty?.preferredLocation,
          additionalNotes: _currentProperty?.additionalNotes,
          status: _currentProperty?.status ?? 'Available',
          propertySubType: existingSubType,
        );
        break;
    }
    notifyListeners();
  }

  void updatePropertySubType(String subType) {
    print('Updating property subtype to: $subType');

    if (_currentProperty != null) {
      switch (_currentProperty.runtimeType) {
        case ResidentialProperty:
          _currentProperty = residentialProperty!.copyWith(
            propertySubType: subType,
          );
          print(
            'Updated Residential propertySubType: ${residentialProperty!.propertySubType}',
          );
          break;
        case CommercialProperty:
          _currentProperty = commercialProperty!.copyWith(
            propertySubType: subType,
          );
          print(
            'Updated Commercial propertySubType: ${commercialProperty!.propertySubType}',
          );
          break;
        case LandProperty:
          _currentProperty = landProperty!.copyWith(propertySubType: subType);
          print(
            'Updated Land propertySubType: ${landProperty!.propertySubType}',
          );
          break;
      }
      notifyListeners();
    } else {
      print('ERROR: _currentProperty is null when trying to update subtype');
    }
  }

  void updateName(String value) {
    _leadModel = _leadModel.copyWith(name: value);
    notifyListeners();
  }

  void updateStatus(String value) {
    _leadModel = _leadModel.copyWith(status: value);
    notifyListeners();
  }

  // void updateCommercialFacilities(String facilities) {
  //   if (commercialProperty != null) {
  //     commercialProperty!.facilities = facilities;
  //     notifyListeners();
  //   }
  // }

  void updateWashroomFacilities(String facilities) {
    if (commercialProperty != null) {
      commercialProperty!.washrooms = facilities;
      notifyListeners();
    }
  }

  void updateseatFacilities(String facilities) {
    if (commercialProperty != null) {
      commercialProperty!.noOfSeats = facilities;
      notifyListeners();
    }
  }

  void updateGender(String value) {
    _leadModel = _leadModel.copyWith(gender: value);
    notifyListeners();
  }

  void updatePhoneNumber(String value) {
    _leadModel = _leadModel.copyWith(phoneNumber: value);
    if (_leadModel.sameAsPhone == true) {
      _leadModel = _leadModel.copyWith(whatsappNumber: value);
    }
    notifyListeners();
  }

  void updateWhatsappNumber(String? number) {
    _leadModel = _leadModel.copyWith(whatsappNumber: number);
    notifyListeners();
  }

  void updateleadID(String? Id) {
    _leadModel = _leadModel.copyWith(id: Id);
    notifyListeners();
  }

  bool? get sameAsPhone => _leadModel.sameAsPhone;
  void updateSameAsPhone(bool value) {
    _leadModel = _leadModel.copyWith(sameAsPhone: value);
    if (value) {
      _leadModel = _leadModel.copyWith(whatsappNumber: _leadModel.phoneNumber);
    }

    notifyListeners();
  }

  void updateLeadType(String value) {
    _leadModel = _leadModel.copyWith(leadType: value);
    notifyListeners();
  }

  void updatePropertyTypeforLead(String value) {
    _leadModel = _leadModel.copyWith(leadType: value);
    notifyListeners();
  }

  void updateLeadNotes(String value) {
    _leadModel = _leadModel.copyWith(notes: value);
    notifyListeners();
  }

  void updateLeadSource(String value) {
    _leadModel = _leadModel.copyWith(source: value);
    notifyListeners();
  }

  void updateLeadStatus(String value) {
    _leadModel = _leadModel.copyWith(status: value);
    notifyListeners();
  }

  void updatePropertyFor(String value) {
    if (_currentProperty == null) {
      String propertyType =
          _selectedPropertyType.isEmpty ? 'Residential' : _selectedPropertyType;

      switch (propertyType) {
        case 'Residential':
          _currentProperty = ResidentialProperty(
            leadId: _leadModel.id ?? '',
            propertyFor: value,
            status: 'New Lead',
          );
          break;
        case 'Commercial':
          _currentProperty = CommercialProperty(
            leadId: _leadModel.id ?? '',
            propertyFor: value,
            status: 'New Lead',
          );
          break;
        case 'Plot':
          _currentProperty = LandProperty(
            leadId: _leadModel.id ?? '',
            propertyFor: value,
            status: 'New Lead',
          );
          break;
        default:
          _currentProperty = ResidentialProperty(
            leadId: _leadModel.id ?? '',
            propertyFor: value,
            status: '',
          );
      }
    } else {
      switch (_currentProperty.runtimeType) {
        case ResidentialProperty:
          _currentProperty = residentialProperty!.copyWith(propertyFor: value);
          break;
        case CommercialProperty:
          _currentProperty = commercialProperty!.copyWith(propertyFor: value);
          break;
        case LandProperty:
          _currentProperty = landProperty!.copyWith(propertyFor: value);
          break;
      }
    }

    notifyListeners();
  }

  void updateAskingPrice(String value) {
    if (_currentProperty != null) {
      switch (_currentProperty.runtimeType) {
        case ResidentialProperty:
          _currentProperty = residentialProperty!.copyWith(askingPrice: value);
          break;
        case CommercialProperty:
          _currentProperty = commercialProperty!.copyWith(askingPrice: value);
          break;

        case LandProperty:
          _currentProperty = landProperty!.copyWith(askingPrice: value);
          break;
      }
      notifyListeners();
    }
  }

  void updateLocation(LocationData? locationData) {
    if (_currentProperty != null) {
      String locationString = locationData?.address ?? '';

      switch (_currentProperty.runtimeType) {
        case ResidentialProperty:
          _currentProperty = (residentialProperty!).copyWith(
            location: locationString,
          );
          break;
        case CommercialProperty:
          _currentProperty = (commercialProperty!).copyWith(
            location: locationString,
          );
          break;

        case LandProperty:
          _currentProperty = (landProperty!).copyWith(location: locationString);
          break;
      }
      notifyListeners();
    }
  }

  LocationData? getLocationDataFromString(String? address) {
    if (address == null || address.isEmpty) return null;
    return LocationData(address: address, latitude: 0.0, longitude: 0.0);
  }

  void updatePreferredLocation(LocationData? locationData) {
    if (_currentProperty != null) {
      String locationString = locationData?.address ?? '';

      switch (_currentProperty.runtimeType) {
        case ResidentialProperty:
          _currentProperty = (residentialProperty!).copyWith(
            preferredLocation: locationString,
          );
          break;
        case CommercialProperty:
          _currentProperty = (commercialProperty!).copyWith(
            preferredLocation: locationString,
          );
          break;

        case LandProperty:
          _currentProperty = (landProperty!).copyWith(
            preferredLocation: locationString,
          );
          break;
      }
      notifyListeners();
    }
  }

  void updateAdditionalNotes(String value) {
    if (_currentProperty != null) {
      switch (_currentProperty.runtimeType) {
        case ResidentialProperty:
          _currentProperty = residentialProperty!.copyWith(
            additionalNotes: value,
          );
          break;
        case CommercialProperty:
          _currentProperty = commercialProperty!.copyWith(
            additionalNotes: value,
          );
          break;

        case LandProperty:
          _currentProperty = landProperty!.copyWith(additionalNotes: value);
          break;
      }
      notifyListeners();
    }
  }

  void updateSelectedBHK(String value) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(selectedBHK: value);
      notifyListeners();
    }
  }

  void updateSquareFeet(String value) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(squareFeet: value);
      notifyListeners();
    } else if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(squareFeet: value);
      notifyListeners();
    } else if (landProperty != null) {
      _currentProperty = landProperty!.copyWith(squareFeet: value);
      notifyListeners();
    }
  }

  void updateAcresAndCents(String acresValue, String centsValue) {
    if (landProperty != null) {
      _currentProperty = landProperty!.copyWith(
        acres: acresValue.isEmpty ? '0' : acresValue,
        cents: centsValue.isEmpty ? '0' : centsValue,
        squareFeet: '0',
      );
      notifyListeners();
    }
  }

  void updateAreaUnit(String? unit) {
    selectedAreaUnit = unit;

    if (unit == 'Square Feet') {
      clearAcreAndCentData();
    } else if (unit == 'Acre & Cent') {
      clearSquareFeetData();
    }

    notifyListeners();
  }

  void clearAcreAndCentData() {
    if (landProperty != null) {
      _currentProperty = landProperty!.copyWith(acres: '0', cents: '0');
      notifyListeners();
    }
  }

  void clearSquareFeetData() {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(squareFeet: '0');
      notifyListeners();
    } else if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(squareFeet: '0');
      notifyListeners();
    } else if (landProperty != null) {
      _currentProperty = landProperty!.copyWith(squareFeet: '0');
      notifyListeners();
    }
  }

  void updateFurnished(bool value) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(furnished: value);
      notifyListeners();
    }
  }

  void updateUnfurnished(bool value) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(unfurnished: value);
      notifyListeners();
    }
  }

  void updateSemiFinished(bool value) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(semiFinished: value);
      notifyListeners();
    }
  }

  void updatePreferFurnished(bool value) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(preferFurnished: value);
      notifyListeners();
    }
  }

  void updatePreferUnfurnished(bool value) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(
        preferUnfurnished: value,
      );
      notifyListeners();
    }
  }

  void updatePreferSemiFurnished(bool value) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(
        preferSemiFurnished: value,
      );
      notifyListeners();
    }
  }

  void addCustomFacility(String facility) {
    if (facility.trim().isEmpty) return;

    final trimmedFacility = facility.trim();
    final residential = residentialProperty;
    if (residential != null) {
      final currentFacilities = List<String>.from(residential.facilities ?? []);
      if (!currentFacilities.contains(trimmedFacility)) {
        currentFacilities.add(trimmedFacility);
        updateFacilities(currentFacilities);
      }
    }
  }

  void addCustomCommercialFacility(String facility) {
  if (facility.trim().isEmpty) return;

  final trimmedFacility = facility.trim();
  final commercial = commercialProperty;
  if (commercial != null) {
    final currentFacilities = List<String>.from(commercial.facilities ?? []);
    if (!currentFacilities.contains(trimmedFacility)) {
      currentFacilities.add(trimmedFacility);
      updateCommercialFacilities(currentFacilities);
    }
  }
}

// Method to toggle commercial facility selection
void toggleCommercialFacility(String facility) {
  if (commercialProperty != null) {
    List<String> currentFacilities = List<String>.from(
      commercialProperty!.facilities ?? [],
    );
    if (currentFacilities.contains(facility)) {
      currentFacilities.remove(facility);
    } else {
      currentFacilities.add(facility);
    }
    updateCommercialFacilities(currentFacilities);
  }
}

// Updated method to handle List<String> instead of String
void updateCommercialFacilities(List<String> facilities) {
  if (commercialProperty != null) {
    _currentProperty = commercialProperty!.copyWith(facilities: facilities);
    notifyListeners();
  }
}


  void addCustomPreference(String preference) {
    if (preference.trim().isEmpty) return;

    final trimmedPreference = preference.trim();
    final residential = residentialProperty;
    if (residential != null) {
      final currentPreferences = List<String>.from(
        residential.preferences ?? [],
      );
      if (!currentPreferences.contains(trimmedPreference)) {
        currentPreferences.add(trimmedPreference);
        updatePreferences(currentPreferences);
      }
    }
  }

  void updateFacilities(List<String> newFacilities) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(
        facilities: newFacilities,
      );
      notifyListeners();
    }
  }

  void updateDeposit(String deposit) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(deposit: deposit);
      notifyListeners();
    }
  }

  void updateMaintenance(String maintenance) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(
        maintenance: maintenance,
      );
      notifyListeners();
    }
  }

  void updateBathroomAttached(String bathroomAttached) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(
        bathroomAttached: bathroomAttached,
      );
      notifyListeners();
    }
  }

  void updateBathroomCommon(String bathroomCommon) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(
        bathroomCommon: bathroomCommon,
      );
      notifyListeners();
    }
  }

  void updateLeadCategory(String leadCategory) {
    _leadModel = _leadModel.copyWith(leadCategory: leadCategory);
    notifyListeners();
  }

  void updatePreferences(List<String> newPreferences) {
    if (residentialProperty != null) {
      _currentProperty = residentialProperty!.copyWith(
        preferences: newPreferences,
      );
      notifyListeners();
    }
  }

  void toggleFacility(String facility) {
    if (residentialProperty != null) {
      List<String> currentFacilities = List<String>.from(
        residentialProperty!.facilities,
      );
      if (currentFacilities.contains(facility)) {
        currentFacilities.remove(facility);
      } else {
        currentFacilities.add(facility);
      }
      _currentProperty = residentialProperty!.copyWith(
        facilities: currentFacilities,
      );
      notifyListeners();
    }
  }

  void togglePreference(String preference) {
    if (residentialProperty != null) {
      List<String> currentPreferences = List<String>.from(
        residentialProperty!.preferences,
      );
      if (currentPreferences.contains(preference)) {
        currentPreferences.remove(preference);
      } else {
        currentPreferences.add(preference);
      }
      _currentProperty = residentialProperty!.copyWith(
        preferences: currentPreferences,
      );
      notifyListeners();
    }
  }

  void updateRequiredSquareFeet(String value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(
        requiredSquareFeet: value,
      );
      notifyListeners();
    }
  }

  void updateOfficeSpace(bool value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(officeSpace: value);
      notifyListeners();
    }
  }

  void updateShop(bool value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(shop: value);
      notifyListeners();
    }
  }

  void updateRestaurant(bool value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(restaurant: value);
      notifyListeners();
    }
  }

  void updateOther(bool value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(other: value);
      notifyListeners();
    }
  }

  void updateBusinessType(String value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(businessType: value);
      notifyListeners();
    }
  }

  void updateRequiredFromDate(String value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(requiredFromDate: value);
      notifyListeners();
    }
  }

  void updateSpecialRequirements(String value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(additionalNotes: value);
      notifyListeners();
    }
  }

  String? leaseDuration = '/month';

  void updateLeaseDuration(String? duration) {
    leaseDuration = duration;
    notifyListeners();
  }

  void updateAdditionalRequirements(String value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(
        additionalRequirements: value,
      );
      notifyListeners();
    } else if (landProperty != null) {
      _currentProperty = landProperty!.copyWith(additionalRequirements: value);
      notifyListeners();
    }
  }

  void updateNeedOfficeSpace(bool value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(needOfficeSpace: value);
      notifyListeners();
    }
  }

  void updateNeedRetailSpace(bool value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(needRetailSpace: value);
      notifyListeners();
    }
  }

  void updateNeedRestaurantSpace(bool value) {
    if (commercialProperty != null) {
      _currentProperty = commercialProperty!.copyWith(
        needRestaurantSpace: value,
      );
      notifyListeners();
    }
  }

  String? _leadDuration;

  String? get leadDuration => _leadDuration;

  void updateLeadDuration(String? duration) {
    _leadDuration = duration;
    notifyListeners();
  }

  Future<void> updateLeead() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String currentPropertyType = _leadModel.propertyType ?? '';
      String currentCollectionName = '';
      switch (currentPropertyType) {
        case 'Residential':
          currentCollectionName = 'Residential';
          break;
        case 'Commercial':
          currentCollectionName = 'Commercial';
          break;
        case 'Plot':
          currentCollectionName = 'Plots';
          break;
      }

      String newPropertyType = _selectedPropertyType;
      String newCollectionName = '';
      switch (newPropertyType) {
        case 'Residential':
          newCollectionName = 'Residential';
          break;
        case 'Commercial':
          newCollectionName = 'Commercial';
          break;
        case 'Plot':
          newCollectionName = 'Plots';
          break;
      }

      bool propertyTypeChanged =
          currentPropertyType.isNotEmpty &&
          currentPropertyType != newPropertyType;

      print('🔍 DEBUG: Property type change check:');
      print(
        '- Current (from lead model): "$currentPropertyType" ($currentCollectionName)',
      );
      print('- New (selected): "$newPropertyType" ($newCollectionName)');
      print('- Changed: $propertyTypeChanged');

      _leadModel = _leadModel.copyWith(
        propertyType: newPropertyType,
        userId: user.uid,
        updatedAt: DateTime.now(),
      );

      String unifiedId = _leadModel.id!;

      print('Using unified ID: $unifiedId for both lead and property');

      if (propertyTypeChanged && currentCollectionName.isNotEmpty) {
        print(
          '🗑️ Attempting to delete old property document from $currentCollectionName collection with ID: $unifiedId',
        );

        await _firestore.runTransaction((transaction) async {
          DocumentReference oldPropertyRef = _firestore
              .collection(currentCollectionName)
              .doc(unifiedId);

          DocumentSnapshot docSnapshot = await transaction.get(oldPropertyRef);

          if (docSnapshot.exists) {
            transaction.delete(oldPropertyRef);
            print(
              '✅ Old property document marked for deletion from $currentCollectionName',
            );
          } else {
            print(
              'ℹ️ No existing document found in $currentCollectionName to delete',
            );
          }
        });

        await Future.delayed(Duration(milliseconds: 500));

        DocumentSnapshot verifySnapshot =
            await _firestore
                .collection(currentCollectionName)
                .doc(unifiedId)
                .get();

        if (verifySnapshot.exists) {
          print(
            '⚠️ Warning: Document still exists after deletion attempt, forcing delete...',
          );
          try {
            await _firestore
                .collection(currentCollectionName)
                .doc(unifiedId)
                .delete();
            print('✅ Force deletion completed');
          } catch (forceDeleteError) {
            print('❌ Force deletion failed: $forceDeleteError');

            throw Exception(
              'Failed to delete old property document: $forceDeleteError',
            );
          }
        } else {
          print('✅ Successfully verified deletion of old property document');
        }
      } else {
        print(
          'ℹ️ Property type not changed or no current collection. Current: "$currentPropertyType", New: "$newPropertyType"',
        );
      }

      Map<String, dynamic> leadData = _leadModel.toMap();

      Map<String, dynamic> leadDataForFirestore = Map<String, dynamic>.from(
        leadData,
      );
      leadDataForFirestore.remove('id');

      print('🔍 DEBUG: Lead data to be saved: $leadDataForFirestore');

      await _firestore
          .collection('leads')
          .doc(unifiedId)
          .set(leadDataForFirestore, SetOptions(merge: true));

      if (newPropertyType.isNotEmpty) {
        Map<String, dynamic> propertyData;

        switch (newPropertyType) {
          case 'Residential':
            ResidentialProperty propertyToSave;
            if (residentialProperty != null) {
              propertyToSave = residentialProperty!.copyWith(
                id: unifiedId,
                leadId: unifiedId,
                leadDuration: leaseDuration,
                updatedAt: DateTime.now(),
              );
            } else {
              propertyToSave = ResidentialProperty(
                id: unifiedId,
                leadId: unifiedId,
                propertyFor: residentialProperty?.propertyFor ?? '',
                leadDuration: leaseDuration,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }

            propertyData = propertyToSave.toMap();
            _currentProperty = propertyToSave;
            break;

          case 'Commercial':
            CommercialProperty propertyToSave;
            if (commercialProperty != null) {
              propertyToSave = commercialProperty!.copyWith(
                id: unifiedId,
                leadId: unifiedId,
                furnished: commercialProperty!.furnished,
                leadDuration: leaseDuration,
                updatedAt: DateTime.now(),
              );
            } else {
              propertyToSave = CommercialProperty(
                id: unifiedId,
                leadId: unifiedId,
                propertyFor: commercialProperty?.propertyFor ?? '',
                leadDuration: leaseDuration,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }

            propertyData = propertyToSave.toMap();
            _currentProperty = propertyToSave;
            break;

          case 'Plot':
            print('🔍 DEBUG: Creating/Updating LandProperty');

            LandProperty propertyToSave;
            if (landProperty != null) {
              print('Using existing landProperty: ${landProperty?.toMap()}');
              propertyToSave = landProperty!.copyWith(
                id: unifiedId,
                leadId: unifiedId,
                leadDuration: leaseDuration,
                updatedAt: DateTime.now(),
              );
            } else {
              print('Creating new LandProperty');

              propertyToSave = LandProperty(
                id: unifiedId,
                leadId: unifiedId,
                propertyFor: landProperty?.propertyFor ?? '',
                leadDuration: leaseDuration,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }

            print('Final propertyToSave: ${propertyToSave.toMap()}');
            propertyData = propertyToSave.toMap();
            _currentProperty = propertyToSave;
            break;

          default:
            throw Exception('Unknown property type: $newPropertyType');
        }

        Map<String, dynamic> propertyDataForFirestore =
            Map<String, dynamic>.from(propertyData);
        propertyDataForFirestore.remove('id');

        print(
          '🔍 DEBUG: Final propertyData to be saved: $propertyDataForFirestore',
        );
        print('🔍 DEBUG: Saving to collection: $newCollectionName');

        DocumentSnapshot existingDoc =
            await _firestore.collection(newCollectionName).doc(unifiedId).get();

        if (existingDoc.exists && propertyTypeChanged) {
          print(
            '⚠️ Warning: Document already exists in $newCollectionName, this should not happen!',
          );

          await _firestore
              .collection(newCollectionName)
              .doc(unifiedId)
              .delete();
          print('🗑️ Deleted conflicting document from $newCollectionName');

          await Future.delayed(Duration(milliseconds: 200));
        }

        await _firestore
            .collection(newCollectionName)
            .doc(unifiedId)
            .set(propertyDataForFirestore);

        print(
          '✅ Property saved successfully with unified ID: $unifiedId in $newCollectionName collection',
        );
      }

      print('✅ Lead updated successfully with unified ID: $unifiedId');
      _isSuccess = true;
      _errorMessage = null;
    } catch (e) {
      _isSuccess = false;
      _errorMessage = e.toString();
      print('❌ Error updating lead: $e');

      print('Debug Info:');
      print('- Lead ID: ${_leadModel.id}');
      print('- Selected Property Type: $_selectedPropertyType');
      print('- Lead Duration: $leaseDuration');
      print('- Current Property Type: ${_currentProperty?.runtimeType}');
      print('- Current Property ID: ${_currentProperty?.id}');
      print('- Stack trace: ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Color _getAvatarColor(String leadType, {String? uniqueId}) {
    // Use current timestamp or provided unique ID
    final seed = uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final combined = '$leadType-$seed';

    int hash = combined.hashCode.abs();
    double hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  // Add this method to update avatar color
  void updateAvatarColor(Color? color) {
    _leadModel = _leadModel.copyWith(avatarColor: color);
    notifyListeners();
  }

  // Update the saveLead method to include avatar color generation
  Future<void> saveLead(BuildContext context) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String unifiedId = _firestore.collection('leads').doc().id;

      String propertyType = '';
      if (_currentProperty != null) {
        switch (_currentProperty.runtimeType) {
          case ResidentialProperty:
            propertyType = 'Residential';
            break;
          case CommercialProperty:
            propertyType = 'Commercial';
            break;
          case LandProperty:
            propertyType = 'Plot';
            break;
          default:
            propertyType = _selectedPropertyType;
        }
      }

      // Generate avatar color if not already set
      Color avatarColor =
          _leadModel.avatarColor ??
          _getAvatarColor(_leadModel.leadType, uniqueId: unifiedId);

      _leadModel = _leadModel.copyWith(
        id: unifiedId,
        propertyType: propertyType,
        userId: user.uid,
        status: "New Lead",
        avatarColor: avatarColor, // Add avatar color
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('leads')
          .doc(unifiedId)
          .set(_leadModel.toMap());

      if (_currentProperty != null) {
        Map<String, dynamic> propertyData;
        String collectionName;

        switch (_currentProperty.runtimeType) {
          case ResidentialProperty:
            final updatedProperty = residentialProperty!.copyWith(
              id: unifiedId,
              leadId: unifiedId,
              leadDuration: leaseDuration,
              updatedAt: DateTime.now(),
            );
            propertyData = updatedProperty.toMap();
            collectionName = 'Residential';
            _currentProperty = updatedProperty;
            break;

          case CommercialProperty:
            print(
              'Saving Commercial Property - furnished: ${commercialProperty?.furnished}',
            );

            final updatedProperty = commercialProperty!.copyWith(
              id: unifiedId,
              leadId: unifiedId,
              facilities: commercialProperty!.facilities,
              furnished: commercialProperty!.furnished,
              leadDuration: leaseDuration,
              updatedAt: DateTime.now(),
            );
            propertyData = updatedProperty.toMap();
            collectionName = 'Commercial';
            _currentProperty = updatedProperty;
            break;

          case LandProperty:
            final updatedProperty = landProperty!.copyWith(
              id: unifiedId,
              leadId: unifiedId,
              leadDuration: leaseDuration,
              updatedAt: DateTime.now(),
            );
            propertyData = updatedProperty.toMap();
            collectionName = 'Plots';
            _currentProperty = updatedProperty;
            break;

          default:
            throw Exception('Unknown property type');
        }

        await _firestore
            .collection(collectionName)
            .doc(unifiedId)
            .set(propertyData);

        print('Property saved with unified ID: $unifiedId');
      }

      print(
        'Lead saved with unified ID: $unifiedId and avatar color: ${avatarColor.value}',
      );
      _isSuccess = true;
      _errorMessage = null;

      if (context.mounted) {
        await context.read<LeadProvider>().fetchLeads();
        clearForms();
      }
    } catch (e) {
      _isSuccess = false;
      _errorMessage = e.toString();
      print('Error saving lead: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update the updateLead method to preserve or generate avatar color
  Future<void> updateLead() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String currentPropertyType = _leadModel.propertyType ?? '';
      String currentCollectionName = '';
      switch (currentPropertyType) {
        case 'Residential':
          currentCollectionName = 'Residential';
          break;
        case 'Commercial':
          currentCollectionName = 'Commercial';
          break;
        case 'Plot':
          currentCollectionName = 'Plots';
          break;
      }

      String newPropertyType = _selectedPropertyType;
      String newCollectionName = '';
      switch (newPropertyType) {
        case 'Residential':
          newCollectionName = 'Residential';
          break;
        case 'Commercial':
          newCollectionName = 'Commercial';
          break;
        case 'Plot':
          newCollectionName = 'Plots';
          break;
      }

      bool propertyTypeChanged =
          currentPropertyType.isNotEmpty &&
          currentPropertyType != newPropertyType;

      // Generate avatar color if not already set, or if lead type changed
      Color avatarColor =
          _leadModel.avatarColor ??
          _getAvatarColor(_leadModel.leadType, uniqueId: _leadModel.id);

      _leadModel = _leadModel.copyWith(
        propertyType: newPropertyType,
        userId: user.uid,
        avatarColor: avatarColor, // Preserve or generate avatar color
        updatedAt: DateTime.now(),
      );

      String unifiedId = _leadModel.id!;

      print('Using unified ID: $unifiedId for both lead and property');

      // [Rest of the existing updateLead logic remains the same...]
      // ... (keep all the existing property type change logic)

      Map<String, dynamic> leadData = _leadModel.toMap();
      Map<String, dynamic> leadDataForFirestore = Map<String, dynamic>.from(
        leadData,
      );
      leadDataForFirestore.remove('id');

      print('🔍 DEBUG: Lead data to be saved: $leadDataForFirestore');
      print('🔍 DEBUG: Avatar color value: ${avatarColor.value}');

      await _firestore
          .collection('leads')
          .doc(unifiedId)
          .set(leadDataForFirestore, SetOptions(merge: true));

      // [Rest of the existing property saving logic...]

      print(
        '✅ Lead updated successfully with unified ID: $unifiedId and avatar color',
      );
      _isSuccess = true;
      _errorMessage = null;
    } catch (e) {
      _isSuccess = false;
      _errorMessage = e.toString();
      print('❌ Error updating lead: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update the updateLeadOnly method to preserve avatar color
  Future<void> updateLeadOnly() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (_leadModel.id == null || _leadModel.id!.isEmpty) {
        throw Exception('Lead ID is required for update');
      }

      // Generate avatar color if not already set
      Color avatarColor =
          _leadModel.avatarColor ??
          _getAvatarColor(_leadModel.leadType, uniqueId: _leadModel.id);

      _leadModel = _leadModel.copyWith(
        userId: FirebaseAuth.instance.currentUser!.uid,
        avatarColor: avatarColor, // Preserve or generate avatar color
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('leads')
          .doc(_leadModel.id)
          .update(_leadModel.toMap());

      print(
        'Lead updated with ID: ${_leadModel.id} and avatar color: ${avatarColor.value}',
      );
      _isSuccess = true;
      _errorMessage = null;
    } catch (e) {
      _isSuccess = false;
      _errorMessage = e.toString();
      print('Error updating lead only: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadExistingLeadDuration(BaseProperty? property) {
    if (property != null) {
      _leadDuration = property.leadDuration;
      notifyListeners();
    }
  }

  Future<void> updateLeaadOnly() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (_leadModel.id == null || _leadModel.id!.isEmpty) {
        throw Exception('Lead ID is required for update');
      }

      _leadModel = _leadModel.copyWith(
        userId: FirebaseAuth.instance.currentUser!.uid,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('leads')
          .doc(_leadModel.id)
          .update(_leadModel.toMap());

      print('Lead updated with ID: ${_leadModel.id}');
      _isSuccess = true;
      _errorMessage = null;
    } catch (e) {
      _isSuccess = false;
      _errorMessage = e.toString();
      print('Error updating lead only: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  Stream<List<LeadModel>> getUserLeads() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('leads')
        .where('status', isNotEqualTo: 'Inactive')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LeadModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<List<LeadModel>> getLeadsByType(String leadType) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('leads')
        .where('leadType', isEqualTo: leadType)
        .where('status', isNotEqualTo: 'Inactive')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LeadModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<List<BaseProperty>> getPropertiesForLead(String leadId) {
    return _firestore
        .collection('properties')
        .where('leadId', isEqualTo: leadId)
        .where('status', isNotEqualTo: 'Inactive')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            String propertyType = data['propertyType'] ?? '';

            switch (propertyType) {
              case 'Residential':
                return ResidentialProperty.fromMap(data, doc.id);
              case 'Commercial':
                return CommercialProperty.fromMap(data, doc.id);

              case 'Plot':
                return LandProperty.fromMap(data, doc.id);
              default:
                return ResidentialProperty.fromMap(data, doc.id);
            }
          }).toList();
        });
  }

  Stream<List<BaseProperty>> getPropertiesByType(String propertyType) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('properties')
        .where('propertyType', isEqualTo: propertyType)
        .where('status', isNotEqualTo: 'Inactive')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();

            switch (propertyType) {
              case 'Residential':
                return ResidentialProperty.fromMap(data, doc.id);
              case 'Commercial':
                return CommercialProperty.fromMap(data, doc.id);

              case 'Plot':
                return LandProperty.fromMap(data, doc.id);
              default:
                return ResidentialProperty.fromMap(data, doc.id);
            }
          }).toList();
        });
  }

  Future<LeadModel?> getLeadById(String leadId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('leads').doc(leadId).get();

      if (doc.exists) {
        return LeadModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting lead: $e');
      return null;
    }
  }

  void clearForms() {
    _leadModel = LeadModel(
      id: '',
      userId: '',
      name: '',
      gender: '',
      phoneNumber: '',
      leadType: '',
      propertyType: '',
    );

    _currentProperty = null;
    _leadDuration = null;

    _selectedPropertyType = '';

    _currentStep = 0;

    _isLoading = false;
    _isSuccess = false;
    _errorMessage = null;

    notifyListeners();
  }
}
