import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:taro_mobile/features/home/controller/filter_state.dart';

class LeadProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<LeadModel> _leads = [];
  List<LeadModel> _filteredLeads = [];
  List<BaseProperty> _properties = [];
  bool _isLoading = false;
  String _error = '';
  final Map<String, List<BaseProperty>> _leadPropertiesMap = {};

  String _selectedOwnerType = 'All';
  String _selectedPropertyFor = 'All';
  String _selectedPropertyType = 'All';
  String _searchQuery = '';
  Map<String, bool> _propertiesLoadingState = {};

  List<String> _selectedLocations = [];
  String _minPrice = '';
  String _maxPrice = '';
  List<String> _selectedBudgetRanges = [];
  String _selectedBHK = 'All';
  String _selectedFurnishingStatus = 'All';
  List<String> _selectedPropertySubtypes = [];
  List<String> _selectedTenantPreferences = [];
  List<String> selectedStatuses = [];
  List<String> selectedSources = [];
  DateTime? startDate;
  DateTime? endDate;

  UnifiedFilterState filterState = UnifiedFilterState();

  String phone = '';
  String whatsapp = '';
  String budget = '';
  String location = '';

  List<LeadModel> get leads => _filteredLeads;
  List<LeadModel> get allLeads => _leads;
  List<BaseProperty> get properties => _properties;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get selectedOwnerType => _selectedOwnerType;
  String get selectedPropertyFor => _selectedPropertyFor;
  String get selectedPropertyType => _selectedPropertyType;
  String get searchQuery => _searchQuery;
  List<String> get selectedLocations => _selectedLocations;
  String get minPrice => _minPrice;
  String get maxPrice => _maxPrice;
  List<String> get selectedBudgetRanges => _selectedBudgetRanges;
  String get selectedBHK => _selectedBHK;
  String get selectedFurnishingStatus => _selectedFurnishingStatus;
  List<String> get selectedPropertySubtypes => _selectedPropertySubtypes;
  List<String> get selectedTenantPreferences => _selectedTenantPreferences;

  void _applyFilters() {
    debugPrint('🔍 ===== APPLYING ENHANCED FILTERS =====');
    debugPrint('📊 Total leads before filtering: ${_leads.length}');
    debugPrint('💰 Budget filters:');
    debugPrint('  - Use slider budget: ${filterState.useSliderBudget}');
    debugPrint('  - Min price (text): "${_minPrice}"');
    debugPrint('  - Max price (text): "${_maxPrice}"');
    debugPrint(
      '  - Slider range: ₹${filterState.minBudgetSlider} - ₹${filterState.maxBudgetSlider}',
    );
    debugPrint('  - Selected budget ranges: $_selectedBudgetRanges');
    debugPrint('  - Owner Type: $_selectedOwnerType');
    debugPrint('  - Property For: $_selectedPropertyFor');
    debugPrint('  - Property Type: $_selectedPropertyType');
    debugPrint('  - BHK: $_selectedBHK');
    debugPrint('  - Furnishing Status: $_selectedFurnishingStatus');
    debugPrint('  - Property Subtypes: $_selectedPropertySubtypes');
    debugPrint('  - Selected Statuses: $selectedStatuses');
    debugPrint('  - Search Query: $_searchQuery');
    debugPrint('  - Selected Locations: $_selectedLocations');
    debugPrint('  - Selected Tenant Preferences: $_selectedTenantPreferences');

    bool hasBudgetFilters =
        filterState.useSliderBudget ||
        _minPrice.isNotEmpty ||
        _maxPrice.isNotEmpty ||
        _selectedBudgetRanges.isNotEmpty;

    debugPrint('💡 Has budget filters: $hasBudgetFilters');

    if (_selectedOwnerType == 'All' &&
        _selectedPropertyFor == 'All' &&
        _selectedPropertyType == 'All' &&
        _selectedBHK == 'All' &&
        _selectedFurnishingStatus == 'All' &&
        _selectedPropertySubtypes.isEmpty &&
        selectedStatuses.isEmpty &&
        _searchQuery.isEmpty &&
        _selectedLocations.isEmpty &&
        _selectedTenantPreferences.isEmpty &&
        !hasBudgetFilters) {
      debugPrint('No filters applied, showing all leads');
      _filteredLeads = List.from(_leads);
      debugPrint('Filtered leads count: ${_filteredLeads.length}');
      return;
    }

    _filteredLeads =
        _leads.where((lead) {
          debugPrint('\n🔍 Checking lead: ${lead.name} (${lead.id})');

          bool matchesOwnerType = true;
          if (_selectedOwnerType != 'All') {
            String leadTypeToCheck = lead.leadType.toLowerCase();
            String selectedTypeToCheck = _selectedOwnerType.toLowerCase();

            if (selectedTypeToCheck == 'buyer') {
              selectedTypeToCheck = 'tenant';
            }

            matchesOwnerType = leadTypeToCheck == selectedTypeToCheck;
            debugPrint(
              'Lead ${lead.name} - leadType: ${lead.leadType}, matches owner type: $matchesOwnerType',
            );
          }

          bool matchesStatus = true;
          if (selectedStatuses.isNotEmpty) {
            matchesStatus = selectedStatuses.contains(lead.status);
            debugPrint(
              'Lead ${lead.name} - status: ${lead.status}, matches status filter: $matchesStatus',
            );
          }

          bool matchesTenantPreferences = true;
          if (_selectedTenantPreferences.isNotEmpty) {
            Set<String> allLeadPreferences = <String>{};

            debugPrint('🔍 Checking tenant preferences for lead: ${lead.name}');
            debugPrint(
              'Selected tenant preferences: $_selectedTenantPreferences',
            );

            // STEP 1: Get preferences from lead category
            if (lead.leadCategory != null && lead.leadCategory!.isNotEmpty) {
              debugPrint('Lead category found: "${lead.leadCategory}"');

              List<String> categoryPrefs =
                  lead.leadCategory!.contains(',')
                      ? lead.leadCategory!
                          .split(',')
                          .map((e) => e.trim())
                          .toList()
                      : [lead.leadCategory!.trim()];

              debugPrint('Category preferences parsed: $categoryPrefs');

              for (String pref in categoryPrefs) {
                String trimmedPref = pref.trim();
                if (trimmedPref.isNotEmpty) {
                  allLeadPreferences.add(trimmedPref.toLowerCase());
                  debugPrint(
                    'Added lead category preference: "$trimmedPref" -> "${trimmedPref.toLowerCase()}"',
                  );
                }
              }
            } else {
              debugPrint('No lead category found');
            }

            // STEP 2: Get preferences from residential properties
            if (lead.id != null) {
              List<BaseProperty> leadProperties =
                  _leadPropertiesMap[lead.id!] ?? [];
              debugPrint('Found ${leadProperties.length} properties for lead');

              for (BaseProperty property in leadProperties) {
                if (property is ResidentialProperty &&
                    property.preferences != null) {
                  debugPrint(
                    'Property ${property.id} has preferences: ${property.preferences}',
                  );
                  for (String pref in property.preferences!) {
                    String trimmedPref = pref.trim();
                    if (trimmedPref.isNotEmpty) {
                      allLeadPreferences.add(trimmedPref.toLowerCase());
                      debugPrint(
                        'Added property preference: "$trimmedPref" -> "${trimmedPref.toLowerCase()}"',
                      );
                    }
                  }
                }
              }
            }

            debugPrint('All lead preferences collected: $allLeadPreferences');

            // STEP 3: Check if any selected preference matches any lead preference
            if (allLeadPreferences.isNotEmpty) {
              matchesTenantPreferences = _selectedTenantPreferences.any((
                selectedPref,
              ) {
                bool matches = allLeadPreferences.any((leadPref) {
                  bool containsMatch =
                      leadPref.contains(selectedPref.toLowerCase()) ||
                      selectedPref.toLowerCase().contains(leadPref);
                  debugPrint(
                    'Comparing "$selectedPref" with "$leadPref": $containsMatch',
                  );
                  return containsMatch;
                });
                debugPrint(
                  'Selected preference "$selectedPref" matches any lead preference: $matches',
                );
                return matches;
              });
            } else {
              matchesTenantPreferences = false;
              debugPrint(
                'No lead preferences found, setting matchesTenantPreferences to false',
              );
            }

            debugPrint(
              'Lead ${lead.name} - FINAL tenant preferences match: $matchesTenantPreferences',
            );
          }

          bool matchesSearch = true;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();

            bool matchesLeadFields =
                lead.name.toLowerCase().contains(query) ||
                lead.phoneNumber.toLowerCase().contains(query) ||
                (lead.whatsappNumber?.toLowerCase().contains(query) ?? false);

            bool matchesPropertyLocation = false;
            List<BaseProperty> leadProperties =
                _leadPropertiesMap[lead.id] ?? [];

            if (leadProperties.isNotEmpty) {
              matchesPropertyLocation = leadProperties.any((property) {
                return property.location?.toLowerCase().contains(query) ??
                    false;
              });
            }

            matchesSearch = matchesLeadFields || matchesPropertyLocation;
            debugPrint(
              'Lead ${lead.name} - matches search "$_searchQuery": $matchesSearch',
            );
          }

          List<BaseProperty> leadProperties = _leadPropertiesMap[lead.id] ?? [];
          debugPrint(
            'Lead ${lead.name} has ${leadProperties.length} cached properties',
          );

          if (leadProperties.isEmpty) {
            debugPrint(
              'Lead ${lead.name} - no cached properties, using lead-level filters only',
            );
            return matchesOwnerType &&
                matchesStatus &&
                matchesSearch &&
                matchesTenantPreferences;
          }

          bool matchesPropertyFor = true;
          if (_selectedPropertyFor != 'All') {
            matchesPropertyFor = leadProperties.any((property) {
              bool matches =
                  property.propertyFor.toLowerCase() ==
                  _selectedPropertyFor.toLowerCase();
              debugPrint(
                'Property ${property.id} - propertyFor: "${property.propertyFor}" vs filter: "$_selectedPropertyFor" = $matches',
              );
              return matches;
            });
            debugPrint(
              'Lead ${lead.name} - matches propertyFor filter: $matchesPropertyFor',
            );
          }

          bool matchesPropertyType = true;
          if (_selectedPropertyType != 'All') {
            matchesPropertyType = leadProperties.any((property) {
              String propertyTypeName = _getPropertyTypeName(property);
              bool matches = _comparePropertyType(
                propertyTypeName,
                _selectedPropertyType,
              );
              debugPrint(
                'Property ${property.id} - type: "$propertyTypeName" vs filter: "$_selectedPropertyType" = $matches',
              );
              return matches;
            });
            debugPrint(
              'Lead ${lead.name} - matches propertyType filter: $matchesPropertyType',
            );
          }

          bool matchesBHK = true;
          if (_selectedBHK != 'All') {
            matchesBHK = leadProperties.any((property) {
              return _checkBHKFilter(property);
            });
            debugPrint('Lead ${lead.name} - matches BHK filter: $matchesBHK');
          }

          bool matchesFurnishingStatus = true;
          if (_selectedFurnishingStatus != 'All') {
            matchesFurnishingStatus = leadProperties.any((property) {
              return _checkFurnishingStatusFilter(property);
            });
            debugPrint(
              'Lead ${lead.name} - matches furnishing status filter: $matchesFurnishingStatus',
            );
          }

          bool matchesPropertySubtype = true;
          if (_selectedPropertySubtypes.isNotEmpty) {
            matchesPropertySubtype = leadProperties.any((property) {
              return _checkPropertySubtype(property);
            });
            debugPrint(
              'Lead ${lead.name} - matches property subtype filter: $matchesPropertySubtype',
            );
          }

          bool matchesLocation = true;
          if (_selectedLocations.isNotEmpty) {
            matchesLocation = leadProperties.any((property) {
              if (property.location == null) return false;

              String propertyLocation = property.location!.toLowerCase();
              bool matches = _selectedLocations.any(
                (selectedLocation) =>
                    propertyLocation.contains(selectedLocation.toLowerCase()),
              );

              debugPrint(
                'Property ${property.id} - location: "${property.location}" matches location filter: $matches',
              );
              return matches;
            });
            debugPrint(
              'Lead ${lead.name} - matches location filter: $matchesLocation',
            );
          }

          bool matchesBudget = true;
          if (hasBudgetFilters) {
            matchesBudget = leadProperties.any((property) {
              return _checkBudgetFilter(property);
            });
            debugPrint(
              'Lead ${lead.name} - matches budget filter: $matchesBudget',
            );
          }

          final overallMatch =
              matchesOwnerType &&
              matchesStatus &&
              matchesSearch &&
              matchesTenantPreferences &&
              matchesPropertyFor &&
              matchesPropertyType &&
              matchesBHK &&
              matchesFurnishingStatus &&
              matchesPropertySubtype &&
              matchesLocation &&
              matchesBudget;

          debugPrint('Lead ${lead.name} - FINAL RESULT: $overallMatch');
          debugPrint('---');

          return overallMatch;
        }).toList();

    debugPrint('📊 Filtered leads count: ${_filteredLeads.length}');
    debugPrint('🔍 ===== FILTERING COMPLETE =====\n');
  }

  bool _checkBudgetFilter(BaseProperty property) {
    debugPrint('🔍 Checking budget filter for property ${property.id}');

    double? propertyPrice = _getPropertyPrice(property);
    if (propertyPrice == null) {
      debugPrint(
        '❌ Property ${property.id} has no valid price, skipping budget filter',
      );
      return true;
    }

    debugPrint('💰 Property ${property.id} price: ₹$propertyPrice');

    if (filterState.useSliderBudget) {
      return _checkSliderBudgetFilter(propertyPrice);
    }

    if (_minPrice.isNotEmpty || _maxPrice.isNotEmpty) {
      return _checkTextBudgetFilter(propertyPrice);
    }

    if (_selectedBudgetRanges.isNotEmpty) {
      return _checkBudgetRangeChips(propertyPrice);
    }

    return true;
  }

  double? _getPropertyPrice(BaseProperty property) {
    try {
      String? priceStr;

      if (property is ResidentialProperty) {
        priceStr = property.askingPrice;
      } else if (property is CommercialProperty) {
        priceStr = property.askingPrice;
      } else if (property is LandProperty) {
        priceStr = property.askingPrice;
      }

      if (priceStr == null || priceStr.isEmpty) return null;

      return _parsePrice(priceStr);
    } catch (e) {
      debugPrint('❌ Error parsing property price: $e');
      return null;
    }
  }

  double? _parsePrice(String priceStr) {
    if (priceStr.isEmpty) return null;

    try {
      String cleanPrice =
          priceStr
              .toLowerCase()
              .replaceAll('₹', '')
              .replaceAll(',', '')
              .replaceAll(' ', '')
              .trim();

      if (cleanPrice.isEmpty) return null;

      double multiplier = 1;
      double baseValue;

      if (cleanPrice.contains('cr') || cleanPrice.contains('crore')) {
        String numberPart = cleanPrice.replaceAll(RegExp(r'[^\d.]'), '');
        baseValue = double.parse(numberPart);
        multiplier = 10000000;
      } else if (cleanPrice.contains('l') || cleanPrice.contains('lakh')) {
        String numberPart = cleanPrice.replaceAll(RegExp(r'[^\d.]'), '');
        baseValue = double.parse(numberPart);
        multiplier = 100000;
      } else if (cleanPrice.contains('k') || cleanPrice.contains('thousand')) {
        String numberPart = cleanPrice.replaceAll(RegExp(r'[^\d.]'), '');
        baseValue = double.parse(numberPart);
        multiplier = 1000;
      } else {
        String numberPart = cleanPrice.replaceAll(RegExp(r'[^\d.]'), '');
        if (numberPart.isEmpty) return null;
        baseValue = double.parse(numberPart);
      }

      double finalPrice = baseValue * multiplier;
      debugPrint('📊 Parsed "$priceStr" -> ₹$finalPrice');
      return finalPrice;
    } catch (e) {
      debugPrint('❌ Error parsing price "$priceStr": $e');
      return null;
    }
  }

  bool _checkSliderBudgetFilter(double propertyPrice) {
    bool withinRange =
        propertyPrice >= filterState.minBudgetSlider &&
        propertyPrice <= filterState.maxBudgetSlider;

    debugPrint(
      '🎚️ Slider filter: ₹$propertyPrice between ₹${filterState.minBudgetSlider} and ₹${filterState.maxBudgetSlider} = $withinRange',
    );

    return withinRange;
  }

  bool _checkTextBudgetFilter(double propertyPrice) {
    bool passesMin = true;
    bool passesMax = true;

    if (_minPrice.isNotEmpty) {
      double? minValue = _parsePrice(_minPrice);
      if (minValue != null) {
        passesMin = propertyPrice >= minValue;
        debugPrint(
          '💰 Min price filter: ₹$propertyPrice >= ₹$minValue = $passesMin',
        );
      }
    }

    if (_maxPrice.isNotEmpty) {
      double? maxValue = _parsePrice(_maxPrice);
      if (maxValue != null) {
        passesMax = propertyPrice <= maxValue;
        debugPrint(
          '💰 Max price filter: ₹$propertyPrice <= ₹$maxValue = $passesMax',
        );
      }
    }

    return passesMin && passesMax;
  }

  bool _checkBudgetRangeChips(double propertyPrice) {
    for (String range in _selectedBudgetRanges) {
      if (_priceInRange(propertyPrice, range)) {
        debugPrint(
          '✅ Property price ₹$propertyPrice matches budget range: $range',
        );
        return true;
      }
    }
    debugPrint(
      '❌ Property price ₹$propertyPrice does not match any selected budget ranges',
    );
    return false;
  }

  bool _priceInRange(double price, String range) {
    try {
      String lowerRange = range.toLowerCase();

      if (lowerRange.contains('under')) {
        RegExp underPattern = RegExp(
          r'under\s+(\d+(?:\.\d+)?)\s*(k|l|cr|lakh|crore|thousand)?',
        );
        Match? match = underPattern.firstMatch(lowerRange);
        if (match != null) {
          double value = double.parse(match.group(1)!);
          String? unit = match.group(2);
          double threshold = _convertToActualValue(value, unit);
          return price < threshold;
        }
      }

      if (lowerRange.contains('above')) {
        RegExp abovePattern = RegExp(
          r'above\s+(\d+(?:\.\d+)?)\s*(k|l|cr|lakh|crore|thousand)?',
        );
        Match? match = abovePattern.firstMatch(lowerRange);
        if (match != null) {
          double value = double.parse(match.group(1)!);
          String? unit = match.group(2);
          double threshold = _convertToActualValue(value, unit);
          return price > threshold;
        }
      }

      if (lowerRange.contains('-')) {
        List<String> parts =
            lowerRange.split('-').map((s) => s.trim()).toList();
        if (parts.length == 2) {
          double? minValue = _parseRangePart(parts[0]);
          double? maxValue = _parseRangePart(parts[1]);

          if (minValue != null && maxValue != null) {
            return price >= minValue && price <= maxValue;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error parsing range $range: $e');
      return false;
    }
  }

  double? _parseRangePart(String part) {
    try {
      part = part.replaceAll('/month', '').trim();

      RegExp rangePattern = RegExp(
        r'(\d+(?:\.\d+)?)\s*(k|l|cr|lakh|crore|thousand)?',
      );
      Match? match = rangePattern.firstMatch(part);

      if (match != null) {
        double value = double.parse(match.group(1)!);
        String? unit = match.group(2);
        return _convertToActualValue(value, unit);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error parsing range part "$part": $e');
      return null;
    }
  }

  double _convertToActualValue(double value, String? unit) {
    if (unit == null) return value;

    switch (unit.toLowerCase()) {
      case 'cr':
      case 'crore':
        return value * 10000000;
      case 'l':
      case 'lakh':
        return value * 100000;
      case 'k':
      case 'thousand':
        return value * 1000;
      default:
        return value;
    }
  }

  bool _checkBHKFilter(BaseProperty property) {
    if (_selectedBHK == 'All') return true;

    if (property is ResidentialProperty) {
      bool matches = property.selectedBHK == _selectedBHK;
      debugPrint(
        'Property ${property.id} - BHK: "${property.selectedBHK}" vs filter: "$_selectedBHK" = $matches',
      );
      return matches;
    }

    return _selectedBHK == 'All';
  }

  bool _checkFurnishingStatusFilter(BaseProperty property) {
    if (_selectedFurnishingStatus == 'All') return true;

    String propertyFurnishingStatus = '';

    if (property is ResidentialProperty) {
      propertyFurnishingStatus = _getResidentialFurnishingStatus(property);
    } else if (property is CommercialProperty) {
      propertyFurnishingStatus = property.furnished ?? 'Unknown';
    } else {
      return _selectedFurnishingStatus == 'All';
    }

    bool matches = propertyFurnishingStatus == _selectedFurnishingStatus;
    debugPrint(
      'Property ${property.id} - Furnishing: "$propertyFurnishingStatus" vs filter: "$_selectedFurnishingStatus" = $matches',
    );
    return matches;
  }

  String _getResidentialFurnishingStatus(ResidentialProperty property) {
    if (property.furnished == true) return 'Furnished';
    if (property.unfurnished == true) return 'Unfurnished';
    if (property.semiFinished == true) return 'Semi-Furnished';
    return 'Unknown';
  }

  bool _checkPropertySubtype(BaseProperty property) {
    if (_selectedPropertySubtypes.isEmpty) {
      return true;
    }

    String? propertySubtype;

    if (property is CommercialProperty) {
      propertySubtype = property.propertySubType;
    } else if (property is ResidentialProperty) {
      propertySubtype = property.propertySubType;
    } else if (property is LandProperty) {
      propertySubtype = property.propertySubType;
    }

    debugPrint('Property ${property.id} subtype: "$propertySubtype"');

    if (propertySubtype == null || propertySubtype.isEmpty) {
      return false;
    }

    bool matches = _selectedPropertySubtypes.any((selectedSubtype) {
      String normalizedPropertySubtype = normalizePropertySubtype(
        propertySubtype!,
      );
      String normalizedSelectedSubtype = normalizePropertySubtype(
        selectedSubtype,
      );
      return normalizedPropertySubtype.toLowerCase() ==
          normalizedSelectedSubtype.toLowerCase();
    });

    return matches;
  }

  String normalizePropertySubtype(String subtype) {
    String normalized = subtype.trim().toLowerCase();

    Map<String, String> subtypeMapping = {
      'shop': 'shop/showroom',
      'showroom': 'shop/showroom',
      'shop/showroom': 'shop/showroom',
      'flat': 'flat/apartment',
      'apartment': 'flat/apartment',
      'flat/apartment': 'flat/apartment',
      'house': 'house/villa',
      'villa': 'house/villa',
      'house/villa': 'house/villa',
      'office': 'office space',
      'office space': 'office space',
      'godown': 'go down',
      'go down': 'go down',
      'warehouse': 'go down',
    };

    return subtypeMapping[normalized] ?? normalized;
  }

  String _getPropertyTypeName(BaseProperty property) {
    if (property is ResidentialProperty) return 'Residential';
    if (property is CommercialProperty) return 'Commercial';
    if (property is LandProperty) return 'Plots';
    return 'Unknown';
  }

  bool _comparePropertyType(String propertyTypeName, String selectedType) {
    return propertyTypeName.toLowerCase() == selectedType.toLowerCase();
  }

  void updatePhone(String value) {
    phone = value;
    notifyListeners();
  }

  void updateWhatsApp(String value) {
    whatsapp = value;
    notifyListeners();
  }

  void updateBudget(String value) {
    budget = value;
    notifyListeners();
  }

  void updateLocation(String value) {
    location = value;
    notifyListeners();
  }

  void updatePropertyType(String value) {
    notifyListeners();
  }

  void setBHKFilter(String bhk) {
    _selectedBHK = bhk;
    debugPrint('BHK filter set to: $bhk');
    _applyFilters();
    notifyListeners();
  }

  void clearBHKFilter() {
    _selectedBHK = 'All';
    _applyFilters();
    notifyListeners();
  }

  void setFurnishingStatusFilter(String furnishingStatus) {
    _selectedFurnishingStatus = furnishingStatus;
    debugPrint('Furnishing status filter set to: $furnishingStatus');
    _applyFilters();
    notifyListeners();
  }

  void clearFurnishingStatusFilter() {
    _selectedFurnishingStatus = 'All';
    _applyFilters();
    notifyListeners();
  }

  void setOwnerTypeFilter(String ownerType) {
    _selectedOwnerType = ownerType;
    debugPrint('Owner type filter set to: $ownerType');
    _applyFilters();
    notifyListeners();
  }

  void setPropertyForFilter(String propertyFor) {
    _selectedPropertyFor = propertyFor;
    debugPrint('Property for filter set to: $propertyFor');

    if (propertyFor == 'Sale' && _selectedOwnerType == 'Tenant') {
      _selectedOwnerType = 'Buyer';
    } else if ((propertyFor == 'Rent' || propertyFor == 'Lease') &&
        _selectedOwnerType == 'Buyer') {
      _selectedOwnerType = 'Tenant';
    }

    _applyFilters();
    notifyListeners();
  }

  void setPropertyTypeFilter(String propertyType) {
    _selectedPropertyType = propertyType;
    _selectedPropertySubtypes.clear();
    debugPrint('Property type filter set to: $propertyType');
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    debugPrint('Search query set to: $query');
    _applyFilters();
    notifyListeners();
  }

  void setLocationFilters(List<String> locations) {
    _selectedLocations = List.from(locations);
    debugPrint('Location filters set to: $_selectedLocations');
    _applyFilters();
    notifyListeners();
  }

  void toggleLocationFilter(String location) {
    if (_selectedLocations.contains(location)) {
      _selectedLocations.remove(location);
    } else {
      _selectedLocations.add(location);
    }
    debugPrint('Location filters updated: $_selectedLocations');
    _applyFilters();
    notifyListeners();
  }

  void clearLocationFilters() {
    _selectedLocations.clear();
    _applyFilters();
    notifyListeners();
  }

  void setBudgetRange(String minPrice, String maxPrice) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    debugPrint('Budget range set to: $_minPrice - $_maxPrice');
    _applyFilters();
    notifyListeners();
  }

  void setBudgetRanges(List<String> budgetRanges) {
    _selectedBudgetRanges = List.from(budgetRanges);
    debugPrint('Budget ranges set to: $_selectedBudgetRanges');
    _applyFilters();
    notifyListeners();
  }

  void toggleBudgetRange(String budgetRange) {
    if (_selectedBudgetRanges.contains(budgetRange)) {
      _selectedBudgetRanges.remove(budgetRange);
    } else {
      _selectedBudgetRanges.add(budgetRange);
    }
    debugPrint('Budget ranges updated: $_selectedBudgetRanges');
    _applyFilters();
    notifyListeners();
  }

  void clearBudgetFilters() {
    _selectedBudgetRanges.clear();
    _minPrice = '';
    _maxPrice = '';
    _applyFilters();
    notifyListeners();
  }

  void setTenantPreferencesFilter(List<String> preferences) {
    _selectedTenantPreferences = List.from(preferences);
    debugPrint(
      'Setting tenant preferences filter: $_selectedTenantPreferences',
    );
    _applyFilters();
    notifyListeners();
  }

  void toggleTenantPreferenceFilter(String preference) {
    if (_selectedTenantPreferences.contains(preference)) {
      _selectedTenantPreferences.remove(preference);
    } else {
      _selectedTenantPreferences.add(preference);
    }
    debugPrint(
      'Toggled tenant preference: $preference. Current: $_selectedTenantPreferences',
    );
    _applyFilters();
    notifyListeners();
  }

  void clearTenantPreferencesFilter() {
    _selectedTenantPreferences.clear();
    debugPrint('Cleared tenant preferences filter');
    _applyFilters();
    notifyListeners();
  }

  void toggleStatusFilter(String status) {
    if (selectedStatuses.contains(status)) {
      selectedStatuses.remove(status);
    } else {
      selectedStatuses.add(status);
    }
    _applyFilters();
    notifyListeners();
  }

  void toggleSourceFilter(String source) {
    if (selectedSources.contains(source)) {
      selectedSources.remove(source);
    } else {
      selectedSources.add(source);
    }
    _applyFilters();
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    startDate = date;
    _applyFilters();
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    endDate = date;
    _applyFilters();
    notifyListeners();
  }

  void applyFilters() {
    _applyFilters();
    notifyListeners();
  }

  void togglePropertySubtypeFilter(String subtype) {
    String normalizedSubtype = normalizePropertySubtype(subtype);

    if (_selectedPropertySubtypes.contains(normalizedSubtype)) {
      _selectedPropertySubtypes.remove(normalizedSubtype);
    } else {
      _selectedPropertySubtypes.add(normalizedSubtype);
    }

    debugPrint('Property subtypes after toggle: $_selectedPropertySubtypes');
    _applyFilters();
    notifyListeners();
  }

  void setPropertySubtypes(List<String> subtypes) {
    _selectedPropertySubtypes =
        subtypes.map((subtype) => normalizePropertySubtype(subtype)).toList();
    debugPrint('Property subtypes set to: $_selectedPropertySubtypes');
    _applyFilters();
    notifyListeners();
  }

  void searchLeads(String query) {
    setSearchQuery(query);
  }

  Future<void> fetchLeads() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final String currentUserId = user.uid;
      debugPrint('Fetching leads for user: ${user.uid}');

      final querySnapshot =
          await _firestore
              .collection('leads')
              .where('userId', isEqualTo: currentUserId)
              .where('status', isNotEqualTo: 'Inactive')
              .orderBy('status')
              .orderBy('createdAt', descending: true)
              .get();

      debugPrint('Found ${querySnapshot.docs.length} documents');

      _leads =
          querySnapshot.docs.map((doc) {
            debugPrint('Processing document: ${doc.id}');
            return LeadModel.fromMap(doc.data(), doc.id);
          }).toList();

      debugPrint('Processed ${_leads.length} leads');

      _leadPropertiesMap.clear();
      subscribeToProperties();
      _applyFilters();

      _isLoading = false;
      notifyListeners();
    } catch (e, stacktrace) {
      debugPrint('Error fetching leads: $e');
      debugPrint('Stacktrace: $stacktrace');
      _error = 'Failed to fetch leads: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProperties() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('properties')
              .where('status', isNotEqualTo: 'Inactive')
              .orderBy('status')
              .orderBy('createdAt', descending: true)
              .get();

      _properties =
          querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            String propertyType = data['propertyType'] ?? '';

            switch (propertyType) {
              case 'Residential':
                return ResidentialProperty.fromMap(data, doc.id);
              case 'Commercial':
                return CommercialProperty.fromMap(data, doc.id);
              case 'Land':
                return LandProperty.fromMap(data, doc.id);
              default:
                return ResidentialProperty.fromMap(data, doc.id);
            }
          }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    }
  }

  void subscribeToProperties() {
    debugPrint('=== SUBSCRIBING TO PROPERTIES ===');
    debugPrint('Number of leads to subscribe: ${_leads.length}');

    for (var lead in _leads) {
      if (lead.id != null) {
        debugPrint(
          'Subscribing to properties for lead: ${lead.id} (${lead.name})',
        );
        getPropertiesForLead(lead.id!).listen(
          (properties) {
            debugPrint(
              'Properties loaded for lead ${lead.id}: ${properties.length} properties',
            );
            _leadPropertiesMap[lead.id!] = properties;

            for (var prop in properties) {
              debugPrint(
                '  Property: ${prop.id}, Location: ${prop.location}, Price: ${prop.askingPrice}',
              );
            }

            _applyFilters();
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error loading properties for lead ${lead.id}: $error');
          },
        );
      } else {
        debugPrint('Lead has null ID, skipping: ${lead.name}');
      }
    }
    debugPrint('=== END SUBSCRIPTION SETUP ===');
  }

  Stream<List<BaseProperty>> getPropertiesForLead(String leadId) {
    if (leadId.isEmpty) return Stream.value([]);

    debugPrint('Fetching properties for leadId: $leadId');

    List<Stream<List<BaseProperty>>> propertyStreams = [];

    propertyStreams.add(
      FirebaseFirestore.instance
          .collection('Residential')
          .where('leadId', isEqualTo: leadId)
          .where('status', isNotEqualTo: 'Inactive')
          .snapshots()
          .map((snapshot) {
            final list =
                snapshot.docs
                    .map((doc) {
                      debugPrint(
                        'Found Residential Property: ${doc.id} for leadId: $leadId',
                      );
                      return ResidentialProperty.fromMap(doc.data(), doc.id);
                    })
                    .cast<BaseProperty>()
                    .toList();

            debugPrint(
              'Total Residential Properties for $leadId: ${list.length}',
            );
            return list;
          }),
    );

    propertyStreams.add(
      FirebaseFirestore.instance
          .collection('Commercial')
          .where('leadId', isEqualTo: leadId)
          .where('status', isNotEqualTo: 'Inactive')
          .snapshots()
          .map((snapshot) {
            final list =
                snapshot.docs
                    .map((doc) {
                      debugPrint(
                        'Found Commercial Property: ${doc.id} for leadId: $leadId',
                      );
                      return CommercialProperty.fromMap(doc.data(), doc.id);
                    })
                    .cast<BaseProperty>()
                    .toList();

            debugPrint(
              'Total Commercial Properties for $leadId: ${list.length}',
            );
            return list;
          }),
    );

    propertyStreams.add(
      FirebaseFirestore.instance
          .collection('Plots')
          .where('leadId', isEqualTo: leadId)
          .where('status', isNotEqualTo: 'Inactive')
          .snapshots()
          .map((snapshot) {
            final list =
                snapshot.docs
                    .map((doc) {
                      debugPrint(
                        'Found Plot Property: ${doc.id} for leadId: $leadId',
                      );
                      return LandProperty.fromMap(doc.data(), doc.id);
                    })
                    .cast<BaseProperty>()
                    .toList();

            debugPrint('Total Plot Properties for $leadId: ${list.length}');
            return list;
          }),
    );

    return CombineLatestStream.list(propertyStreams).map((listOfLists) {
      List<BaseProperty> allProperties = [];
      for (List<BaseProperty> propertyList in listOfLists) {
        allProperties.addAll(propertyList);
      }

      debugPrint(
        'Total Properties found for leadId $leadId: ${allProperties.length}',
      );
      return allProperties;
    });
  }

  List<String> getAvailableLocations() {
    Set<String> locations = {};

    for (var leadWithProps in _leadPropertiesMap.entries) {
      for (var property in leadWithProps.value) {
        if (property.location?.isNotEmpty == true) {
          locations.add(property.location!);
        }
      }
    }

    if (locations.isEmpty) {
      locations.addAll([
        'Kochi',
        'Ernakulam',
        'Kakkanad',
        'Edapally',
        'Aluva',
        'Thrissur',
        'Calicut',
        'Trivandrum',
        'Kollam',
        'Kottayam',
      ]);
    }

    return locations.toList()..sort();
  }

  String normalizePreference(String pref) {
    String normalized = pref.trim().toLowerCase();

    switch (normalized) {
      case 'bachelor (m)':
        return 'bachelor(m)';
      case 'bachelor (f)':
      case 'bachelor(women)':
        return 'bachelor(f)';
      case 'any':
        return '';
      default:
        return normalized;
    }
  }

  String getDisplayName(String normalizedPref) {
    switch (normalizedPref) {
      case 'bachelor(m)':
        return 'Bachelor M';
      case 'bachelor(f)':
        return 'Bachelor F';
      case 'family':
        return 'Family';
      case 'vegetarian':
        return 'Vegetarian';
      case 'working women':
        return 'Working Women';
      case 'working professionals':
        return 'Working Professionals';
      case 'married couples':
        return 'Married Couples';
      case 'unmarried couples':
        return 'Unmarried Couples';
      default:
        return normalizedPref
            .split(' ')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? word[0].toUpperCase() + word.substring(1)
                      : word,
            )
            .join(' ');
    }
  }

  List<String> getAvailableTenantPreferencesWithDebug() {
    Set<String> normalizedPreferences = <String>{};
    Map<String, int> preferenceCount = <String, int>{};
    int residentialCount = 0;
    int preferencesFound = 0;
    int leadCategoryPrefs = 0;
    int propertyPrefs = 0;

    for (LeadModel lead in _leads) {
      if (lead.leadCategory != null && lead.leadCategory!.isNotEmpty) {
        List<String> categoryPrefs =
            lead.leadCategory!.contains(',')
                ? lead.leadCategory!.split(',').map((e) => e.trim()).toList()
                : [lead.leadCategory!.trim()];

        for (String pref in categoryPrefs) {
          if (pref.isNotEmpty) {
            String normalizedPref = normalizePreference(pref);
            if (normalizedPref.isNotEmpty) {
              normalizedPreferences.add(normalizedPref);
              preferenceCount[normalizedPref] =
                  (preferenceCount[normalizedPref] ?? 0) + 1;
              preferencesFound++;
              leadCategoryPrefs++;
            }
          }
        }
      }

      if (lead.id != null) {
        List<BaseProperty> leadProperties = _leadPropertiesMap[lead.id!] ?? [];
        for (BaseProperty property in leadProperties) {
          if (property is ResidentialProperty) {
            residentialCount++;
            if (property.preferences != null &&
                property.preferences!.isNotEmpty) {
              for (String pref in property.preferences!) {
                String trimmedPref = pref.trim();
                if (trimmedPref.isNotEmpty) {
                  String normalizedPref = normalizePreference(trimmedPref);
                  if (normalizedPref.isNotEmpty) {
                    normalizedPreferences.add(normalizedPref);
                    preferenceCount[normalizedPref] =
                        (preferenceCount[normalizedPref] ?? 0) + 1;
                    preferencesFound++;
                    propertyPrefs++;
                  }
                }
              }
            }
          }
        }
      }
    }

    print('=== TENANT PREFERENCES DEBUG ===');
    print('Found $residentialCount residential properties');
    print('Found $preferencesFound total preference entries');
    print('Found $leadCategoryPrefs preferences from lead categories');
    print('Found $propertyPrefs preferences from properties');
    print('Unique normalized preferences: ${normalizedPreferences.length}');

    print('Preference frequency:');
    preferenceCount.forEach((pref, count) {
      print('  $pref: $count occurrences');
    });

    List<String> sortedNormalizedPrefs = normalizedPreferences.toList()..sort();
    print('Final unique preferences: $sortedNormalizedPrefs');

    List<String> displayPreferences =
        sortedNormalizedPrefs.map((pref) => getDisplayName(pref)).toList();

    print('Display preferences: $displayPreferences');
    print('=== END DEBUG ===');

    return displayPreferences;
  }

  List<String> getBudgetRangesForPropertyType(String propertyFor) {
    switch (propertyFor.toLowerCase()) {
      case 'rent':
      case 'lease':
        return [
          'Under 5K/month',
          '5K - 10K/month',
          '10K - 25K/month',
          '25K - 50K/month',
          '50K - 1L/month',
          'Above 1L/month',
        ];
      case 'sale':
        return [
          'Under 10L',
          '10L - 25L',
          '25L - 50L',
          '50L - 1Cr',
          '1Cr - 2Cr',
          '2Cr - 5Cr',
          'Above 5Cr',
        ];
      default:
        return [
          'Under 10L',
          '10L - 25L',
          '25L - 50L',
          '50L - 1Cr',
          '1Cr - 2Cr',
          '2Cr - 5Cr',
          'Above 5Cr',
        ];
    }
  }

  int get totalLeadsCount => _leads.length;
  int get filteredLeadsCount => _filteredLeads.length;

  int getLeadsCountByType(String leadType) {
    return _leads
        .where((lead) => lead.leadType.toLowerCase() == leadType.toLowerCase())
        .length;
  }

  List<BaseProperty> getFilteredProperties() {
    List<BaseProperty> allFilteredProperties = [];

    for (var lead in _filteredLeads) {
      if (lead.id != null) {
        List<BaseProperty> leadProperties = _leadPropertiesMap[lead.id!] ?? [];
        allFilteredProperties.addAll(leadProperties);
      }
    }

    return allFilteredProperties;
  }

  List<BaseProperty> getPropertiesForLeadSync(String leadId) {
    return _leadPropertiesMap[leadId] ?? [];
  }

  Future<void> updateLeadStatus(String leadId, String status) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('leads').doc(leadId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      int index = _leads.indexWhere((lead) => lead.id == leadId);
      if (index != -1) {
        _leads[index] = _leads[index].copyWith(status: status);
        _applyFilters();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update lead status: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating lead status: $e');
    }
  }


  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> refreshData() async {
    await Future.wait([fetchLeads(), fetchProperties()]);
  }
}
