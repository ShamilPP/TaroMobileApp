import 'package:flutter/material.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/controller/filter_state.dart';

class GlobalFilterSheet extends StatefulWidget {
  final UnifiedFilterState initialFilterState;
  final Function(UnifiedFilterState) onApplyFilters;
  final List<String> availableLocations;
  final List<String> availableTenantPreferences;
  final List<String> availableBudgetRanges;

  const GlobalFilterSheet({
    Key? key,
    required this.initialFilterState,
    required this.onApplyFilters,
    this.availableLocations = const [],
    this.availableTenantPreferences = const [],
    this.availableBudgetRanges = const [],
  }) : super(key: key);

  @override
  State<GlobalFilterSheet> createState() => _GlobalFilterSheetState();
}

class _GlobalFilterSheetState extends State<GlobalFilterSheet> {
  late UnifiedFilterState filterState;
  final TextEditingController _locationController = TextEditingController();

  int currentMinBudgetIndex = 0;
  int currentMaxBudgetIndex = 0;

  List<Map<String, dynamic>> get leaseValues => [
    {'display': '₹5K', 'value': 5000},
    {'display': '₹10K', 'value': 10000},
    {'display': '₹20K', 'value': 20000},
    {'display': '₹30K', 'value': 30000},
    {'display': '₹40K', 'value': 40000},
    {'display': '₹50K', 'value': 50000},
    {'display': '₹60K', 'value': 60000},
    {'display': '₹70K', 'value': 70000},
    {'display': '₹80K', 'value': 80000},
    {'display': '₹90K', 'value': 90000},
    {'display': '₹1L', 'value': 100000},
    {'display': '₹1.5L', 'value': 150000},
    {'display': '₹2L', 'value': 200000},
    {'display': '₹4L', 'value': 400000},
    {'display': '₹7L', 'value': 700000},
    {'display': '₹10L', 'value': 1000000},
    {'display': '₹20L', 'value': 2000000},
    {'display': '₹30L', 'value': 3000000},
    {'display': '₹30L+', 'value': 3000001},
  ];

  List<Map<String, dynamic>> get rentValues => [
    {'display': '₹5K', 'value': 5000},
    {'display': '₹10K', 'value': 10000},
    {'display': '₹20K', 'value': 20000},
    {'display': '₹30K', 'value': 30000},
    {'display': '₹40K', 'value': 40000},
    {'display': '₹50K', 'value': 50000},
    {'display': '₹60K', 'value': 60000},
    {'display': '₹70K', 'value': 70000},
    {'display': '₹80K', 'value': 80000},
    {'display': '₹90K', 'value': 90000},
    {'display': '₹1L', 'value': 100000},
    {'display': '₹1.5L', 'value': 150000},
    {'display': '₹2L', 'value': 200000},
    {'display': '₹4L', 'value': 400000},
    {'display': '₹7L', 'value': 700000},
    {'display': '₹10L', 'value': 1000000},
    {'display': '₹10L+', 'value': 1000001},
  ];

  List<Map<String, dynamic>> get saleValues => [
    {'display': '₹50K', 'value': 50000},
    {'display': '₹1L', 'value': 100000},
    {'display': '₹2L', 'value': 200000},
    {'display': '₹3L', 'value': 300000},
    {'display': '₹5L', 'value': 500000},
    {'display': '₹7.5L', 'value': 750000},
    {'display': '₹10L', 'value': 1000000},
    {'display': '₹15L', 'value': 1500000},
    {'display': '₹20L', 'value': 2000000},
    {'display': '₹25L', 'value': 2500000},
    {'display': '₹30L', 'value': 3000000},
    {'display': '₹40L', 'value': 4000000},
    {'display': '₹50L', 'value': 5000000},
    {'display': '₹75L', 'value': 7500000},
    {'display': '₹1Cr', 'value': 10000000},
    {'display': '₹1.5Cr', 'value': 15000000},
    {'display': '₹2Cr', 'value': 20000000},
    {'display': '₹2.5Cr', 'value': 25000000},
    {'display': '₹3Cr', 'value': 30000000},
    {'display': '₹3.5Cr', 'value': 35000000},
    {'display': '₹4Cr', 'value': 40000000},
    {'display': '₹4.5Cr', 'value': 45000000},
    {'display': '₹5Cr', 'value': 50000000},
    {'display': '₹10Cr', 'value': 100000000},
    {'display': '₹15Cr', 'value': 150000000},
    {'display': '₹20Cr', 'value': 200000000},
    {'display': '₹20Cr+', 'value': 200000001},
  ];

  List<Map<String, dynamic>> get currentValues {
    if (filterState.selectedTransactionType == 'Rent') {
      return rentValues;
    } else if (filterState.selectedTransactionType == 'Lease') {
      return leaseValues;
    } else {
      return saleValues;
    }
  }

  String get selectedMinPrice {
    return currentValues[currentMinBudgetIndex]['display'];
  }

  String get selectedMaxPrice {
    return currentValues[currentMaxBudgetIndex]['display'];
  }

  String formatPrice(double value) {
    if (value >= 10000000) {
      double crores = value / 10000000;
      if (crores % 1 == 0) {
        return '₹${crores.toInt()}Cr';
      } else {
        return '₹${crores.toStringAsFixed(1)}Cr';
      }
    } else if (value >= 100000) {
      double lakhs = value / 100000;
      if (lakhs % 1 == 0) {
        return '₹${lakhs.toInt()}L';
      } else {
        return '₹${lakhs.toStringAsFixed(1)}L';
      }
    } else if (value >= 1000) {
      double thousands = value / 1000;
      if (thousands % 1 == 0) {
        return '₹${thousands.toInt()}K';
      } else {
        return '₹${thousands.toStringAsFixed(1)}K';
      }
    } else {
      return '₹${value.toInt()}';
    }
  }

  @override
  void initState() {
    super.initState();
    filterState = widget.initialFilterState.copyWith();

    _resetSliderForTransactionType();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _resetSliderForTransactionType() {
    List<Map<String, dynamic>> values = currentValues;

    currentMinBudgetIndex = 0;
    currentMaxBudgetIndex = values.length - 2;

    if (filterState.useSliderBudget) {
      filterState.minBudgetSlider =
          values[currentMinBudgetIndex]['value'].toDouble();
      filterState.maxBudgetSlider =
          values[currentMaxBudgetIndex]['value'].toDouble();
      filterState.minPrice = selectedMinPrice;
      filterState.maxPrice = selectedMaxPrice;
    } else {
      filterState.minBudgetSlider = 0;
      filterState.maxBudgetSlider = 0;
      filterState.minPrice = "";
      filterState.maxPrice = "";
    }

    filterState.useSliderBudget = filterState.useSliderBudget ?? false;
  }

  String _getBudgetRangeFromSlider() {
    List<Map<String, dynamic>> values = currentValues;

    if (!filterState.useSliderBudget) {
      if (filterState.selectedTransactionType == 'Rent' ||
          filterState.selectedTransactionType == 'Lease') {
        return 'No Rent Budget Filter';
      } else {
        return 'No Sale Budget Filter';
      }
    }

    if (currentMinBudgetIndex == 0 &&
        currentMaxBudgetIndex == values.length - 2) {
      if (filterState.selectedTransactionType == 'Rent' ||
          filterState.selectedTransactionType == 'Lease') {
        return 'All Rent Budgets';
      } else {
        return 'All Sale Budgets';
      }
    }

    String minDisplay = values[currentMinBudgetIndex]['display'];
    String maxDisplay = values[currentMaxBudgetIndex]['display'];

    return '$minDisplay - $maxDisplay';
  }

  void _onTransactionTypeChanged(String newType) {
    setState(() {
      String previousType = filterState.selectedTransactionType;
      filterState.selectedTransactionType = newType;
      filterState.selectedPropertyFor = newType;

      if (previousType != newType) {
        _resetSliderForTransactionType();
      }
    });
  }

  void _updateSliderFromDropdown(String? minPrice, String? maxPrice) {
    List<Map<String, dynamic>> values = currentValues;

    if (minPrice != null) {
      int minIndex = values.indexWhere((item) => item['display'] == minPrice);
      if (minIndex != -1) {
        currentMinBudgetIndex = minIndex;
      }
    }

    if (maxPrice != null) {
      int maxIndex = values.indexWhere((item) => item['display'] == maxPrice);
      if (maxIndex != -1) {
        currentMaxBudgetIndex = maxIndex;
      }
    }

    if (currentMaxBudgetIndex < currentMinBudgetIndex) {
      currentMaxBudgetIndex = currentMinBudgetIndex;
    }

    filterState.minBudgetSlider =
        values[currentMinBudgetIndex]['value'].toDouble();
    filterState.maxBudgetSlider =
        values[currentMaxBudgetIndex]['value'].toDouble();
    filterState.minPrice = values[currentMinBudgetIndex]['display'];
    filterState.maxPrice = values[currentMaxBudgetIndex]['display'];

    filterState.useSliderBudget = true;
  }

  Widget _applyButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (!filterState.useSliderBudget) {
              filterState.minBudgetSlider = 0;
              filterState.maxBudgetSlider = 0;
              filterState.minPrice = "";
              filterState.maxPrice = "";
            }

            widget.onApplyFilters(filterState);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Apply Filters',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    setState(() {
                      filterState.clearFilters();
                      _locationController.clear();
                      _resetSliderForTransactionType();
                    });
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildTransactionTypeSection(),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildLeadTypeSection(),

                    _buildPropertyTypeSection(),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocationSection(),
                          const SizedBox(height: 24),

                          _buildSynchronizedBudgetSection(),
                          const SizedBox(height: 24),

                          _buildConditionalPropertySubtypeSection(),
                          const SizedBox(height: 24),

                          if (filterState.selectedPropertyType == 'Residential')
                            _buildBHKSection(),
                          if (filterState.selectedPropertyType == 'Residential')
                            const SizedBox(height: 24),

                          if (filterState.selectedPropertyType != 'Plots')
                            _buildFurnishingStatusSection(),
                          const SizedBox(height: 24),

                          if (filterState.selectedPropertyType == 'Residential')
                            _buildTenantPreferencesSection(),
                          if (filterState.selectedPropertyType == 'Residential')
                            const SizedBox(height: 24),

                          _buildStatusSection(),

                          _applyButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeSection() {
    return Container(
      width: double.infinity,
      color: AppColors.primaryGreen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildTransactionTypeChip('Sale'),
          const SizedBox(width: 8),
          _buildTransactionTypeChip('Rent'),
          const SizedBox(width: 8),
          _buildTransactionTypeChip('Lease'),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeChip(String type) {
    final isActive = filterState.selectedTransactionType == type;
    return GestureDetector(
      onTap: () => _onTransactionTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isActive ? AppColors.textColor : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSynchronizedBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '💰 Budget Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E3A59),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                filterState.useSliderBudget
                    ? AppColors.textColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  filterState.useSliderBudget
                      ? AppColors.textColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.currency_rupee,
                size: 16,
                color:
                    filterState.useSliderBudget
                        ? Color(0xFF2E3A59)
                        : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _getBudgetRangeFromSlider(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      filterState.useSliderBudget
                          ? Color(0xFF2E3A59)
                          : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildPriceDropdowns(),
        const SizedBox(height: 16),

        _buildBudgetSlider(),
      ],
    );
  }

  Widget _buildPriceDropdowns() {
    List<Map<String, dynamic>> values = currentValues;
    List<String> dropdownOptions =
        values.map((item) => item['display'] as String).toList();

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: filterState.useSliderBudget ? selectedMinPrice : null,
              hint: const Text('Min Price'),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items:
                  dropdownOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _updateSliderFromDropdown(
                    newValue,
                    filterState.useSliderBudget ? selectedMaxPrice : null,
                  );
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text('to', style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 12),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: filterState.useSliderBudget ? selectedMaxPrice : null,
              hint: const Text('Max Price'),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items:
                  dropdownOptions
                      .map((String value) {
                        int minIndex = currentMinBudgetIndex;
                        int currentIndex = dropdownOptions.indexOf(value);
                        if (currentIndex < minIndex) {
                          return null;
                        }
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      })
                      .where((item) => item != null)
                      .cast<DropdownMenuItem<String>>()
                      .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _updateSliderFromDropdown(
                    filterState.useSliderBudget ? selectedMinPrice : null,
                    newValue,
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSlider() {
    List<Map<String, dynamic>> values = currentValues;

    return Column(
      children: [
        RangeSlider(
          values: RangeValues(
            currentMinBudgetIndex.toDouble(),
            currentMaxBudgetIndex.toDouble(),
          ),
          min: 0,
          max: (values.length - 2).toDouble(),
          divisions: values.length - 2,
          activeColor: AppColors.textColor,
          inactiveColor: Colors.grey[300],
          labels: RangeLabels(
            values[currentMinBudgetIndex]['display'],
            values[currentMaxBudgetIndex]['display'],
          ),
          onChanged: (RangeValues rangeValues) {
            setState(() {
              currentMinBudgetIndex = rangeValues.start.round();
              currentMaxBudgetIndex = rangeValues.end.round();

              if (currentMaxBudgetIndex < currentMinBudgetIndex) {
                currentMaxBudgetIndex = currentMinBudgetIndex;
              }

              filterState.minBudgetSlider =
                  values[currentMinBudgetIndex]['value'].toDouble();
              filterState.maxBudgetSlider =
                  values[currentMaxBudgetIndex]['value'].toDouble();
              filterState.minPrice = values[currentMinBudgetIndex]['display'];
              filterState.maxPrice = values[currentMaxBudgetIndex]['display'];
              filterState.useSliderBudget = true;
            });
          },
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${values[currentMinBudgetIndex]['display']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Max: ${values[currentMaxBudgetIndex]['display']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          filterState.useSliderBudget
              ? (filterState.selectedTransactionType == 'Rent' ||
                      filterState.selectedTransactionType == 'Lease'
                  ? 'Active rent filter: ₹5K to ₹10L+'
                  : 'Active sale filter: ₹50K to ₹5Cr+')
              : (filterState.selectedTransactionType == 'Rent' ||
                      filterState.selectedTransactionType == 'Lease'
                  ? 'Move slider or select dropdown to filter rent'
                  : 'Move slider or select dropdown to filter sale'),
          style: TextStyle(
            fontSize: 11,
            color:
                filterState.useSliderBudget
                    ? AppColors.textColor.withOpacity(0.7)
                    : Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConditionalPropertySubtypeSection() {
    if (filterState.selectedPropertyType == 'All') {
      return const SizedBox.shrink();
    }

    List<Map<String, dynamic>> propertySubtypes = [];
    String sectionTitle = '';

    switch (filterState.selectedPropertyType) {
      case 'Residential':
        sectionTitle = '🏠 Residential Property Types';
        propertySubtypes = [
          {'name': 'Flat/Apartment', 'icon': Icons.apartment},
          {'name': 'House/Villa', 'icon': Icons.house},
        ];
        break;
      case 'Commercial':
        sectionTitle = '🏢 Commercial Property Types';
        propertySubtypes = [
          {'name': 'Office Space', 'icon': Icons.business},
          {'name': 'Shop/Showroom', 'icon': Icons.store},
          {'name': 'Go down', 'icon': Icons.warehouse},
        ];
        break;
      case 'Plots':
        sectionTitle = '📍 Plot Types';
        propertySubtypes = [
          {'name': 'Agricultural', 'icon': Icons.grass},
          {'name': 'Residential', 'icon': Icons.home},
          {'name': 'Commercial', 'icon': Icons.business_center},
        ];
        break;
    }

    if (propertySubtypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3A59),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: propertySubtypes.length,
            itemBuilder: (context, index) {
              final propertyType = propertySubtypes[index];
              final propertyName = propertyType['name'] as String;

              final isSelected = filterState.selectedSubtypes.contains(
                propertyName,
              );

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (filterState.selectedSubtypes.contains(propertyName)) {
                      filterState.selectedSubtypes.remove(propertyName);
                    } else {
                      filterState.selectedSubtypes.add(propertyName);
                    }

                    if (filterState.selectedSubtypes.isNotEmpty) {
                      filterState.selectedSpecificPropertyType =
                          filterState.selectedSubtypes.first;
                    } else {
                      filterState.selectedSpecificPropertyType = 'All';
                    }
                  });
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textColor : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.textColor : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: AppColors.textColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        propertyType['icon'] as IconData,
                        size: 28,
                        color: isSelected ? Colors.white : AppColors.textColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        propertyName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.textColor,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (filterState.selectedSubtypes.length > 1 && isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (filterState.selectedSubtypes.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${filterState.selectedSubtypes.length} subtypes selected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeadTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const Text(
            '👤 Lead Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E3A59),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLeadTypeChip('Owner'),
            _buildLeadTypeChip('Tenant'),
            _buildLeadTypeChip('Buyer'),
          ],
        ),
      ],
    );
  }

  Widget _buildLeadTypeChip(String type) {
    final isActive = filterState.selectedLeadType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          // Clear selected statuses when changing lead type since they're different
          if (filterState.selectedLeadType != type) {
            filterState.selectedStatuses.clear();
          }
          filterState.selectedLeadType = type;
          filterState.selectedOwnerType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.textColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.textColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBHKSection() {
    const bhkOptions = ['1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '4+ BHK'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏠 BHK Configuration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3A59),
          ),
        ),
        const SizedBox(height: 12),
        _buildChipRow(bhkOptions, filterState.selectedBHK, (String value) {
          setState(() {
            filterState.selectedBHK = value;
          });
        }),
      ],
    );
  }

  Widget _buildFurnishingStatusSection() {
    const furnishingOptions = ['Furnished', 'Semi-Furnished', 'Unfurnished'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🪑 Furnishing Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3A59),
          ),
        ),
        const SizedBox(height: 12),
        _buildChipRow(furnishingOptions, filterState.selectedFurnishingStatus, (
          String value,
        ) {
          setState(() {
            filterState.selectedFurnishingStatus = value;
          });
        }),
      ],
    );
  }

  Widget _buildPropertyTypeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏠 Property Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPropertyTypeChip('Residential'),
              _buildPropertyTypeChip('Commercial'),
              _buildPropertyTypeChip('Plots'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeChip(String type) {
    final isActive = filterState.selectedPropertyType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          filterState.selectedPropertyType = type;
          filterState.selectedSubtypes.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.textColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.textColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📍 Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3A59),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _locationController,
            onSubmitted: (value) {
              if (value.isNotEmpty &&
                  !filterState.selectedLocations.contains(value)) {
                setState(() {
                  filterState.selectedLocations.add(value);
                  _locationController.clear();
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter location and press Enter',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (filterState.selectedLocations.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                filterState.selectedLocations.map((location) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          location,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              filterState.selectedLocations.remove(location);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildTenantPreferencesSection() {
    List<String> preferences =
        widget.availableTenantPreferences.isNotEmpty
            ? widget.availableTenantPreferences
            : [''];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👨‍👩‍👧‍👦 Preferences ${widget.availableTenantPreferences.isNotEmpty ? "(${widget.availableTenantPreferences.length} available)" : ""}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3A59),
          ),
        ),
        const SizedBox(height: 12),
        _buildMultiSelectChips(
          preferences,
          filterState.selectedTenantPreferences,
          (selectedList) {
            setState(() {
              filterState.selectedTenantPreferences = selectedList;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    // Define statuses based on lead type
    List<String> statuses;
    Map<String, String> statusEmojis;

    if (filterState.selectedLeadType == 'Owner') {
      statuses = [
        'New Lead',
        'Details Collected',
        'Listing Live',
        'Advance Received',
        'Agreement',
        'Payment Complete',
        'Closed',
        'Archived',
        'Lost',
      ];

      statusEmojis = {
        'New Lead': '🆕',
        'Details Collected': '📝',
        'Listing Live': '🔴',
        'Advance Received': '💰',
        'Agreement': '📑',
        'Payment Complete': '💳',
        'Closed': '✅',
        'Archived': '📦',
        'Lost': '❌',
      };
    } else {
      // For Buyer/Tenant
      statuses = [
        'New Lead',
        'Details Shared',
        'Site Visit',
        'Negotiation',
        'Advance Paid',
        'Agreement',
        'Payment Complete',
        'Closed',
        'Archived',
        'Lost',
      ];

      statusEmojis = {
        'New Lead': '🆕',
        'Details Shared': '📤',
        'Site Visit': '📍',
        'Negotiation': '🤝',
        'Advance Paid': '💸',
        'Agreement': '📑',
        'Payment Complete': '💳',
        'Closed': '✅',
        'Archived': '📦',
        'Lost': '❌',
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📊 Status (${filterState.selectedLeadType})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E3A59),
              ),
            ),
            if (filterState.selectedStatuses.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    filterState.selectedStatuses.clear();
                  });
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatusSquareGrid(statuses, statusEmojis, (String status) {
          setState(() {
            if (filterState.selectedStatuses.contains(status)) {
              filterState.selectedStatuses.remove(status);
            } else {
              filterState.selectedStatuses.add(status);
            }
          });
        }),
      ],
    );
  }

  Widget _buildStatusSquareGrid(
    List<String> statuses,
    Map<String, String> emojiMap,
    Function(String) onChanged,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        final isSelected = filterState.selectedStatuses.contains(status);
        final emoji = emojiMap[status] ?? '';

        return GestureDetector(
          onTap: () => onChanged(status),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textColor : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.textColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: AppColors.textColor.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: isSelected ? 20 : 18)),
                const SizedBox(height: 4),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChipRow(
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          options.map((option) {
            final isSelected = selectedValue == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.textColor : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildMultiSelectChips(
    List<String> options,
    List<String> selectedValues,
    Function(List<String>) onChanged, {
    Map<String, String>? emojiMap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          options.map((option) {
            final isSelected = selectedValues.contains(option);
            final emoji = emojiMap?[option] ?? '';

            return GestureDetector(
              onTap: () {
                List<String> newSelection = List.from(selectedValues);
                if (isSelected) {
                  newSelection.remove(option);
                } else {
                  newSelection.add(option);
                }
                onChanged(newSelection);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.textColor : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  emoji.isEmpty ? option : '$emoji $option',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

void showGlobalFilterSheet({
  required BuildContext context,
  required UnifiedFilterState currentFilterState,
  required Function(UnifiedFilterState) onApplyFilters,
  List<String> availableLocations = const [],
  List<String> availableBudgetRanges = const [],
  List<String> availableTenantPreferences = const [],
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => GlobalFilterSheet(
          initialFilterState: currentFilterState,
          onApplyFilters: onApplyFilters,
          availableLocations: availableLocations,
          availableBudgetRanges: availableBudgetRanges,
          availableTenantPreferences: availableTenantPreferences,
        ),
  );
}
