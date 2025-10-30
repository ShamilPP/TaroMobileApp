import '../../lead/add_lead_model.dart';

class UnifiedFilterState {
  
  String selectedLeadType = 'All';
  String selectedOwnerType = 'All';
  
  
  String selectedPropertyFor = 'All';
  String selectedPropertyType = 'All';
  String selectedSpecificPropertyType = 'All';
  String selectedTransactionType = 'All';
  String selectedBHK = 'All';
  String selectedFurnishingStatus = 'All';
  
  
  List<String> selectedStatuses = [];
  List<String> selectedSubtypes = [];
  List<String> selectedLocations = [];
  List<String> selectedBudgetRanges = [];
  List<String> selectedTenantPreferences = [];
  
  
  String minPrice = '';
  String maxPrice = '';
  
  
  double minBudgetSlider = 0.0; 
  double maxBudgetSlider = 500.0; 
  bool useSliderBudget = false; 

  bool get isAllSelected =>
      selectedLeadType == 'All' &&
      selectedOwnerType == 'All' &&
      selectedPropertyFor == 'All' &&
      selectedPropertyType == 'All' &&
      selectedSpecificPropertyType == 'All' &&
      selectedTransactionType == 'All' &&
      selectedBHK == 'All' &&
      selectedFurnishingStatus == 'All' &&
      selectedStatuses.isEmpty &&
      selectedSubtypes.isEmpty &&
      selectedLocations.isEmpty &&
      minPrice.isEmpty &&
      maxPrice.isEmpty &&
      selectedBudgetRanges.isEmpty &&
      selectedTenantPreferences.isEmpty &&
      !useSliderBudget;

  void clearFilters() {
    selectedLeadType = 'All';
    selectedOwnerType = 'All';
    selectedPropertyFor = 'All';
    selectedPropertyType = 'All';
    selectedSpecificPropertyType = 'All';
    selectedTransactionType = 'All';
    selectedBHK = 'All';
    selectedFurnishingStatus = 'All';
    selectedStatuses.clear();
    selectedSubtypes.clear();
    selectedLocations.clear();
    minPrice = '';
    maxPrice = '';
    selectedBudgetRanges.clear();
    selectedTenantPreferences.clear();
    minBudgetSlider = 0.0;
    maxBudgetSlider = 500.0;
    useSliderBudget = false;
  }

  UnifiedFilterState copyWith({
    String? selectedLeadType,
    String? selectedOwnerType,
    String? selectedPropertyFor,
    String? selectedPropertyType,
    String? selectedSpecificPropertyType,
    String? selectedTransactionType,
    String? selectedBHK,
    String? selectedFurnishingStatus,
    List<String>? selectedStatuses,
    List<String>? selectedSubtypes,
    List<String>? selectedLocations,
    String? minPrice,
    String? maxPrice,
    List<String>? selectedBudgetRanges,
    List<String>? selectedTenantPreferences,
    double? minBudgetSlider,
    double? maxBudgetSlider,
    bool? useSliderBudget,
  }) {
    return UnifiedFilterState()
      ..selectedLeadType = selectedLeadType ?? this.selectedLeadType
      ..selectedOwnerType = selectedOwnerType ?? this.selectedOwnerType
      ..selectedPropertyFor = selectedPropertyFor ?? this.selectedPropertyFor
      ..selectedPropertyType = selectedPropertyType ?? this.selectedPropertyType
      ..selectedSpecificPropertyType = selectedSpecificPropertyType ?? this.selectedSpecificPropertyType
      ..selectedTransactionType = selectedTransactionType ?? this.selectedTransactionType
      ..selectedBHK = selectedBHK ?? this.selectedBHK
      ..selectedFurnishingStatus = selectedFurnishingStatus ?? this.selectedFurnishingStatus
      ..selectedStatuses = selectedStatuses ?? List.from(this.selectedStatuses)
      ..selectedSubtypes = selectedSubtypes ?? List.from(this.selectedSubtypes)
      ..selectedLocations = selectedLocations ?? List.from(this.selectedLocations)
      ..minPrice = minPrice ?? this.minPrice
      ..maxPrice = maxPrice ?? this.maxPrice
      ..selectedBudgetRanges = selectedBudgetRanges ?? List.from(this.selectedBudgetRanges)
      ..selectedTenantPreferences = selectedTenantPreferences ?? List.from(this.selectedTenantPreferences)
      ..minBudgetSlider = minBudgetSlider ?? this.minBudgetSlider
      ..maxBudgetSlider = maxBudgetSlider ?? this.maxBudgetSlider
      ..useSliderBudget = useSliderBudget ?? this.useSliderBudget;
  }

  
  bool matchesFilters(LeadModel lead, List<BaseProperty> properties) {
    print('🔍 Filtering Lead: ${lead.name} (${lead.leadType})');
    
    
    if (selectedLeadType != 'All' && lead.leadType != selectedLeadType) {
      print('❌ Lead type mismatch: ${lead.leadType} != $selectedLeadType');
      return false;
    }

    
    if (selectedOwnerType != 'All' && lead.leadType != selectedOwnerType) {
      print('❌ Owner type mismatch: ${lead.leadType} != $selectedOwnerType');
      return false;
    }

    
    if (selectedStatuses.isNotEmpty) {
      if (!selectedStatuses.contains(lead.status)) {
        print('❌ Status mismatch: ${lead.status} not in $selectedStatuses');
        return false;
      }
    } else {
      
      if (lead.status == 'Archived') {
        print('❌ Archived lead hidden by default');
        return false;
      }
    }

    
    if (selectedTenantPreferences.isNotEmpty && lead.leadType == 'Tenant') {
      if (lead.leadCategory.isEmpty || !selectedTenantPreferences.contains(lead.leadCategory)) {
        print('❌ Tenant preference mismatch: ${lead.leadCategory} not in $selectedTenantPreferences');
        return false;
      }
    }

    
    if (_hasPropertyFilters()) {
      if (properties.isEmpty) {
        print('❌ No properties found for property-based filters');
        return false;
      }

      bool hasMatchingProperty = false;
      for (BaseProperty property in properties) {
        if (_propertyMatchesFilters(property)) {
          hasMatchingProperty = true;
          print('✅ Found matching property: ${property.runtimeType}');
          break;
        }
      }

      if (!hasMatchingProperty) {
        print('❌ No properties match the filters');
        return false;
      }
    }

    print('✅ Lead ${lead.name} passes all filters');
    return true;
  }

  
  bool _hasPropertyFilters() {
    return selectedPropertyFor != 'All' ||
           selectedPropertyType != 'All' ||
           selectedSpecificPropertyType != 'All' ||
           selectedTransactionType != 'All' ||
           selectedBHK != 'All' ||
           selectedFurnishingStatus != 'All' ||
           selectedLocations.isNotEmpty ||
           selectedBudgetRanges.isNotEmpty ||
           minPrice.isNotEmpty ||
           maxPrice.isNotEmpty ||
           useSliderBudget ||
           selectedSubtypes.isNotEmpty;
  }

  
  bool _propertyMatchesFilters(BaseProperty property) {
    
    if (selectedPropertyFor != 'All' && property.propertyFor != selectedPropertyFor) {
      return false;
    }

    
    if (selectedTransactionType != 'All' && property.propertyFor != selectedTransactionType) {
      return false;
    }

    
    if (selectedPropertyType != 'All') {
      String propertyType = _getPropertyType(property);
      if (propertyType != selectedPropertyType) {
        return false;
      }
    }

    
    if (selectedSpecificPropertyType != 'All') {
      if (!_matchesSpecificPropertyType(property, selectedSpecificPropertyType)) {
        return false;
      }
    }

    
    if (selectedBHK != 'All' && property is ResidentialProperty) {
      if (property.selectedBHK != selectedBHK) {
        return false;
      }
    }

    
    if (selectedFurnishingStatus != 'All' && property is ResidentialProperty) {
      String furnishingStatus = _getFurnishingStatus(property);
      if (furnishingStatus != selectedFurnishingStatus) {
        return false;
      }
    }

    
    if (selectedLocations.isNotEmpty) {
      if (!_matchesLocation(property.location, selectedLocations)) {
        return false;
      }
    }

    
    if (!_matchesPriceFilter(property)) {
      return false;
    }

    
    if (selectedSubtypes.isNotEmpty) {
      if (property.selectedSubType == null || 
          !selectedSubtypes.contains(property.selectedSubType)) {
        return false;
      }
    }

    return true;
  }

  
  String _getPropertyType(BaseProperty property) {
    if (property is ResidentialProperty) return 'Residential';
    if (property is CommercialProperty) return 'Commercial';
    if (property is LandProperty) return 'Plots';
    return 'Unknown';
  }

  
  bool _matchesSpecificPropertyType(BaseProperty property, String specificType) {
    switch (specificType) {
      case 'Flat/Apartment':
        return property is ResidentialProperty && 
               (property.propertySubType?.toLowerCase().contains('flat') == true ||
                property.propertySubType?.toLowerCase().contains('apartment') == true);
      case 'House/Villa':
        return property is ResidentialProperty && 
               (property.propertySubType?.toLowerCase().contains('house') == true ||
                property.propertySubType?.toLowerCase().contains('villa') == true);
      case 'Shop/Showroom':
        return property is CommercialProperty && 
               (property.propertySubType?.toLowerCase().contains('shop') == true ||
                property.propertySubType?.toLowerCase().contains('showroom') == true);
      case 'Office Space':
        return property is CommercialProperty && 
               property.propertySubType?.toLowerCase().contains('office') == true;
      default:
        return true; 
    }
  }

  
  String _getFurnishingStatus(ResidentialProperty property) {
    if (property.furnished == true) return 'Furnished';
    if (property.unfurnished == true) return 'Unfurnished';
    if (property.semiFinished == true) return 'Semi-Furnished';
    return 'Unknown';
  }

  
  bool _matchesLocation(String? propertyLocation, List<String> selectedLocations) {
    if (propertyLocation == null || propertyLocation.isEmpty) return false;
    
    String location = propertyLocation.toLowerCase();
    for (String selectedLocation in selectedLocations) {
      if (location.contains(selectedLocation.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  
  bool _matchesPriceFilter(BaseProperty property) {
    String? priceStr = property.askingPrice;
    if (priceStr == null || priceStr.isEmpty) {
      
      return !_hasPriceFilters();
    }

    
    double? propertyPrice = _extractPrice(priceStr);
    if (propertyPrice == null) {
      return !_hasPriceFilters();
    }

    
    if (useSliderBudget) {
      double minBudgetRupees = minBudgetSlider * 100000; 
      double maxBudgetRupees = maxBudgetSlider * 100000;
      
      if (minBudgetSlider > 0 && propertyPrice < minBudgetRupees) return false;
      if (maxBudgetSlider < 500 && propertyPrice > maxBudgetRupees) return false;
    }

    
    if (minPrice.isNotEmpty) {
      double? minPriceValue = _extractPrice(minPrice);
      if (minPriceValue != null && propertyPrice < minPriceValue) return false;
    }

    if (maxPrice.isNotEmpty) {
      double? maxPriceValue = _extractPrice(maxPrice);
      if (maxPriceValue != null && propertyPrice > maxPriceValue) return false;
    }

    
    if (selectedBudgetRanges.isNotEmpty) {
      return _matchesBudgetRange(propertyPrice, selectedBudgetRanges);
    }

    return true;
  }

  
  bool _hasPriceFilters() {
    return useSliderBudget ||
           minPrice.isNotEmpty ||
           maxPrice.isNotEmpty ||
           selectedBudgetRanges.isNotEmpty;
  }

  
  double? _extractPrice(String priceStr) {
    
    String cleanPrice = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanPrice);
  }

  
  bool _matchesBudgetRange(double propertyPrice, List<String> budgetRanges) {
    for (String range in budgetRanges) {
      if (_priceInRange(propertyPrice, range)) {
        return true;
      }
    }
    return false;
  }

  
  bool _priceInRange(double price, String range) {
    
    double priceInLakhs = price / 100000;
    
    switch (range) {
      case 'Under 10L':
        return priceInLakhs < 10;
      case '10L - 20L':
        return priceInLakhs >= 10 && priceInLakhs <= 20;
      case '20L - 50L':
        return priceInLakhs > 20 && priceInLakhs <= 50;
      case '50L - 1Cr':
        return priceInLakhs > 50 && priceInLakhs <= 100;
      case '1Cr - 2Cr':
        return priceInLakhs > 100 && priceInLakhs <= 200;
      case '2Cr - 5Cr':
        return priceInLakhs > 200 && priceInLakhs <= 500;
      case 'Above 5Cr':
        return priceInLakhs > 500;
      default:
        return true;
    }
  }
}