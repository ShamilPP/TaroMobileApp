import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/controller/lead_controller.dart';
import 'package:taro_mobile/features/home/view/home_sreen.dart' as nav;
import 'package:taro_mobile/features/lead/add_lead_controller.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:taro_mobile/features/lead/location_picker.dart';
import 'package:taro_mobile/core/widgets/chip_widget.dart';
import 'package:taro_mobile/core/widgets/custom_radio_button.dart';
import 'package:taro_mobile/core/widgets/number_budget_textfield.dart';

class LeadDetailsScreen extends StatefulWidget {
  final LeadModel? existingLead;
  final bool isEditMode;

  const LeadDetailsScreen({
    super.key,
    this.existingLead,
    this.isEditMode = false,
  });

  @override
  State<LeadDetailsScreen> createState() => _NewLeadFormScreenState();
}

class _NewLeadFormScreenState extends State<LeadDetailsScreen> {
  final PageController _pageController = PageController();
  LocationData? homeLocation;
  List<BaseProperty> leadProperties = [];
  bool isLoadingProperties = false;
  final NumberFormat _indianFormat = NumberFormat.decimalPattern('en_IN');

  late TextEditingController facilitiesController;
  late TextEditingController preferencesController;
  late TextEditingController askingPriceController;
  late TextEditingController budgetRangeController;
  late TextEditingController squareFeetController;
  late TextEditingController additionalNotesController;
  late TextEditingController requiredSquareFeetController;
  late TextEditingController businessTypeController;
  late TextEditingController specialRequirementsController;
  late TextEditingController additionalRequirementsController;
  late TextEditingController locationController;
  late TextEditingController nameController;
  late TextEditingController washroomsController;
  late TextEditingController seatsController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController acresController;
  late TextEditingController centsController;
  late TextEditingController maintainenceController;
  late TextEditingController depositController;
  late TextEditingController commonBathroomController;
  late TextEditingController attachedBathroomController;
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    if (widget.isEditMode && widget.existingLead != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLeadData();
      });
    }
  }

  void _initializeControllers() {
    facilitiesController = TextEditingController();
    preferencesController = TextEditingController();
    askingPriceController = TextEditingController();
    budgetRangeController = TextEditingController();
    squareFeetController = TextEditingController();
    additionalNotesController = TextEditingController();
    requiredSquareFeetController = TextEditingController();
    businessTypeController = TextEditingController();
    specialRequirementsController = TextEditingController();
    additionalRequirementsController = TextEditingController();
    locationController = TextEditingController();
    washroomsController = TextEditingController();
    seatsController = TextEditingController();
    nameController = TextEditingController();
    _phoneController = TextEditingController();
    _whatsappController = TextEditingController();
    acresController = TextEditingController();
    centsController = TextEditingController();
    maintainenceController = TextEditingController();
    depositController = TextEditingController();
    commonBathroomController = TextEditingController();
    attachedBathroomController = TextEditingController();

    _phoneController.addListener(() {
      final provider = context.read<NewLeadProvider>();
      if (provider.sameAsPhone == true) {
        _whatsappController.text = _phoneController.text;
        provider.updateWhatsappNumber(_phoneController.text);
      }
    });
  }

  void _loadLeadData() {
    setState(() {
      isLoadingProperties = true;
    });

    _prefillBasicLeadData();
    _loadLeadProperties();
  }

  void _prefillBasicLeadData() {
    final provider = context.read<NewLeadProvider>();
    final lead = widget.existingLead!;

    provider.updateName(lead.name ?? '');
    nameController.text = lead.name ?? '';

    provider.updatePhoneNumber(lead.phoneNumber ?? '');
    _phoneController.text = lead.phoneNumber ?? '';

    provider.updateWhatsappNumber(lead.whatsappNumber ?? '');
    _whatsappController.text = lead.whatsappNumber ?? '';

    if (lead.leadType != null) {
      provider.updateLeadType(lead.leadType!);
    }

    if (lead.gender != null) {
      provider.updateGender(lead.gender!);
    }

    if (lead.leadCategory != null) {
      provider.updateLeadCategory(lead.leadCategory!);
    }

    if (lead.id != null) {
      provider.updateleadID(lead.id!);
    }
  }

  void _loadLeadProperties() {
    final leadController = Provider.of<LeadProvider>(context, listen: false);
    leadController.getPropertiesForLead(widget.existingLead!.id ?? '').listen((
      properties,
    ) {
      setState(() {
        leadProperties = properties;
        isLoadingProperties = false;
        if (properties.isNotEmpty) {
          _populateFieldsFromProperties(properties);
        }
      });
    });
  }

  void _populateFieldsFromProperties(List<BaseProperty> properties) {
    if (properties.isEmpty) return;

    final provider = context.read<NewLeadProvider>();
    _clearPropertyFields();

    final residentialProperties =
        properties.whereType<ResidentialProperty>().toList();
    final commercialProperties =
        properties.whereType<CommercialProperty>().toList();
    final landProperties = properties.whereType<LandProperty>().toList();

    if (properties.isNotEmpty) {
      BaseProperty firstProperty = properties.first;

      if (firstProperty is ResidentialProperty) {
        provider.updatePropertyType('Residential');
        _populateResidentialFields(residentialProperties.first, provider);
      } else if (firstProperty is CommercialProperty) {
        provider.updatePropertyType('Commercial');
        _populateCommercialFields(commercialProperties.first, provider);
      } else if (firstProperty is LandProperty) {
        provider.updatePropertyType('Plot');
        _populateLandFields(landProperties.first, provider);
      }
    }
  }

  void _clearPropertyFields() {
    askingPriceController.clear();
    budgetRangeController.clear();
    squareFeetController.clear();
    facilitiesController.clear();
    preferencesController.clear();
    additionalNotesController.clear();
    requiredSquareFeetController.clear();
    businessTypeController.clear();
    specialRequirementsController.clear();
    additionalRequirementsController.clear();
    locationController.clear();
  }

  void _populateResidentialFields(
    ResidentialProperty property,
    NewLeadProvider provider,
  ) {
    if (property.propertyFor != null) {
      provider.updatePropertyFor(property.propertyFor!);
    }

    if (property.propertySubType != null) {
      provider.selectPropertySubType(property.propertySubType!);
    }

    if (property.selectedBHK != null) {
      provider.updateSelectedBHK(property.selectedBHK!);
    }

    _setFurnishingFromBooleans(property, provider);

    if (widget.existingLead!.leadType == 'Owner') {
      if (property.askingPrice != null) {
        provider.updateAskingPrice(property.askingPrice!);
        askingPriceController.text = property.askingPrice!;
      }

      if (property.facilities != null) {
        provider.updateFacilities(property.facilities!);
        facilitiesController.text = property.facilities!.join(', ');
      }
      if (property.maintenance != null) {
        provider.updateMaintenance(property.maintenance!);
        maintainenceController.text = property.maintenance!;
      }
      if (property.deposit != null) {
        provider.updateDeposit(property.deposit!);
        depositController.text = property.deposit!;
      }
      if (property.bathroomAttached != null) {
        provider.updateBathroomAttached(property.bathroomAttached!);
        attachedBathroomController.text = property.bathroomAttached!;
      }
      if (property.bathroomCommon != null) {
        provider.updateBathroomCommon(property.bathroomCommon!);
        commonBathroomController.text = property.bathroomCommon!;
      }

      if (property.preferences != null) {
        provider.updatePreferences(property.preferences!);
        preferencesController.text = property.preferences!.join(', ');
      }

      if (property.additionalNotes != null) {
        provider.updateAdditionalNotes(property.additionalNotes!);
        additionalNotesController.text = property.additionalNotes!;
      }
    } else if (widget.existingLead!.leadType == 'Tenant' ||
        widget.existingLead!.leadType == 'Buyer') {
      if (property.askingPrice != null) {
        provider.updateAskingPrice(property.askingPrice!);
        askingPriceController.text = property.askingPrice!;
      }

      if (property.maintenance != null) {
        provider.updateMaintenance(property.maintenance!);
        maintainenceController.text = property.maintenance!;
      }

      if (property.workingProfessional != null) {
        provider.updateWorkingProfessionals(property.workingProfessional!);
      }

      // Prefill veg or non-veg
      if (property.vegOrNonVeg != null) {
        provider.updateVegOrNonVeg(property.vegOrNonVeg!);
      }

      if (property.deposit != null) {
        provider.updateDeposit(property.deposit!);
        depositController.text = property.deposit!;
      }
      if (property.bathroomAttached != null) {
        provider.updateBathroomAttached(property.bathroomAttached!);
        attachedBathroomController.text = property.bathroomAttached!;
      }
      if (property.bathroomCommon != null) {
        provider.updateBathroomCommon(property.bathroomCommon!);
        commonBathroomController.text = property.bathroomCommon!;
      }
      if (property.facilities != null) {
        provider.updateFacilities(property.facilities!);
        facilitiesController.text = property.facilities!.join(', ');
      }
      if (property.preferences != null) {
        provider.updatePreferences(property.preferences!);
        preferencesController.text = property.preferences!.join(', ');
      }

      if (property.additionalNotes != null) {
        provider.updateAdditionalNotes(property.additionalNotes!);
        additionalNotesController.text = property.additionalNotes!;
      }
    }

    if (property.location != null) {
      locationController.text = property.location!;
      print("1234567${property.location}");
    }
    if (property.location != null) {
      locationController.text = property.location!;

      final locationData = LocationData(
        address: property.location!,
        latitude: 0.0,
        longitude: 0.0,
      );
      provider.updateLocation(locationData);
    }
  }

  void _populateCommercialFields(
    CommercialProperty property,
    NewLeadProvider provider,
  ) {
    if (property.propertyFor != null) {
      provider.updatePropertyFor(property.propertyFor!);
    }

    if (property.propertySubType != null) {
      provider.selectPropertySubType(property.propertySubType!);
    }

    _setCommercialSubTypes(property, provider);

    if (widget.existingLead!.leadType == 'Owner') {
      if (property.askingPrice != null) {
        String askingPriceStr = property.askingPrice!.toString();
        provider.updateAskingPrice(askingPriceStr);
        askingPriceController.text = askingPriceStr;
      }

      if (property.squareFeet != null) {
        provider.updateSquareFeet(property.squareFeet!.toString());
        squareFeetController.text = property.squareFeet!.toString();
      }

      if (property.facilities != null && property.facilities!.isNotEmpty) {
        provider.updateCommercialFacilities(property.facilities!);
        facilitiesController.text = property.facilities!.join(', ');
      }

      if (property.washrooms != null) {
        provider.updateWashroomFacilities(property.washrooms!);
        washroomsController.text = property.washrooms!;
      }

      if (property.noOfSeats != null) {
        provider.updateseatFacilities(property.noOfSeats!);
        seatsController.text = property.noOfSeats!;
      }

      if (property.additionalNotes != null) {
        provider.updateAdditionalNotes(property.additionalNotes!);
        additionalNotesController.text = property.additionalNotes!;
      }

      if (property.furnished != null && property.furnished!.isNotEmpty) {
        print('Setting Owner furnished state: ${property.furnished}');
        provider.updateCommercialFurnishingType(property.furnished!);
      }
    } else if (widget.existingLead!.leadType == 'Tenant' ||
        widget.existingLead!.leadType == 'Buyer') {
      if (property.askingPrice != null) {
        print("Tenant/Buyer askingPrice: ${property.askingPrice}");
        provider.updateAskingPrice(property.askingPrice!);
        askingPriceController.text = property.askingPrice!;
      }

      if (property.squareFeet != null) {
        provider.updateSquareFeet(property.squareFeet!.toString());
        squareFeetController.text = property.squareFeet!.toString();
      }

      if (property.facilities != null && property.facilities!.isNotEmpty) {
        provider.updateCommercialFacilities(property.facilities!);
        facilitiesController.text = property.facilities!.join(', ');
      }
      if (property.washrooms != null) {
        provider.updateWashroomFacilities(property.washrooms!);
        washroomsController.text = property.washrooms!;
      }

      if (property.noOfSeats != null) {
        provider.updateseatFacilities(property.noOfSeats!);
        seatsController.text = property.noOfSeats!;
      }

      if (property.additionalNotes != null) {
        provider.updateSpecialRequirements(property.additionalNotes!);
        specialRequirementsController.text = property.additionalNotes!;
      }

      if (property.furnished != null && property.furnished!.isNotEmpty) {
        print('Setting Tenant/Buyer furnished state: ${property.furnished}');
        provider.updateCommercialFurnishingType(property.furnished!);
      }
    }

    if (property.location != null && property.location!.isNotEmpty) {
      print("Setting location: ${property.location}");
      locationController.text = property.location!;

      final locationData = LocationData(
        address: property.location!,
        latitude: 0.0,
        longitude: 0.0,
      );
      provider.updateLocation(locationData);
    }
  }

  void _populateLandFields(LandProperty property, NewLeadProvider provider) {
    if (property.propertyFor != null) {
      provider.updatePropertyFor(property.propertyFor!);
    }

    if (property.propertySubType != null) {
      provider.selectPropertySubType(property.propertySubType!);
    }

    if (property.askingPrice != null) {
      provider.updateAskingPrice(property.askingPrice!);
      askingPriceController.text = property.askingPrice!;
    }

    if (property.squareFeet != null) {
      provider.updateSquareFeet(property.squareFeet!);
      squareFeetController.text = property.squareFeet!;
    }

    if (property.squareFeet != null && property.squareFeet!.isNotEmpty) {
      provider.updateSquareFeet(property.squareFeet!);
      squareFeetController.text = property.squareFeet!;
    }
    _prefillAreaData(provider);
    if (property.acres != null && property.acres!.isNotEmpty) {
      final acres = property.acres!;
      final cents = property.cents ?? '0';
      provider.updateAcresAndCents(acres, cents);
      acresController.text = acres;
      centsController.text = cents;
    }
    if (property.additionalNotes != null) {
      provider.updateAdditionalNotes(property.additionalNotes!);
      additionalNotesController.text = property.additionalNotes!;
    }

    if (property.location != null) {
      locationController.text = property.location!;
    }

    if (property.location != null) {
      locationController.text = property.location!;

      final locationData = LocationData(
        address: property.location!,
        latitude: 0.0,
        longitude: 0.0,
      );
      provider.updateLocation(locationData);
    }
  }

  void _setFurnishingFromBooleans(
    ResidentialProperty property,
    NewLeadProvider provider,
  ) {
    if (property.furnished == true) {
      provider.updateFurnished(true);
    } else if (property.semiFinished == true) {
      provider.updateSemiFinished(true);
    } else if (property.unfurnished == true) {
      provider.updateUnfurnished(true);
    }
  }

  void _setCommercialSubTypes(
    CommercialProperty property,
    NewLeadProvider provider,
  ) {
    List<String> subTypes = [];

    if (subTypes.isNotEmpty) {
      provider.updatePropertyFor(subTypes.first);
    }
  }

  @override
  void dispose() {
    facilitiesController.dispose();
    preferencesController.dispose();
    askingPriceController.dispose();
    budgetRangeController.dispose();
    squareFeetController.dispose();
    additionalNotesController.dispose();
    requiredSquareFeetController.dispose();
    businessTypeController.dispose();
    specialRequirementsController.dispose();
    additionalRequirementsController.dispose();
    locationController.dispose();
    nameController.dispose();
    washroomsController.dispose();
    seatsController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _pageController.dispose();
    acresController.dispose();
    centsController.dispose();
    depositController.dispose();
    maintainenceController.dispose();
    commonBathroomController.dispose();
    attachedBathroomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_pageController.page != null && _pageController.page! > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              if (isLoadingProperties && widget.isEditMode)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: Consumer<NewLeadProvider>(
                    builder: (context, provider, child) {
                      return PageView(
                        controller: _pageController,
                        physics: NeverScrollableScrollPhysics(),

                        onPageChanged: (index) {
                          provider.updateStep(index);
                        },
                        children: _getPageBasedOnSelections(context, provider),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _getPageBasedOnSelections(
    BuildContext context,
    NewLeadProvider provider,
  ) {
    List<Widget> pages = [_buildRegisterFormStep(context)];

    if (provider.leadModel.leadType == 'Owner') {
      if (provider.selectedPropertyType == 'Residential') {
        pages.add(_buildOwnerResidentialStep(context));
      } else if (provider.selectedPropertyType == 'Commercial') {
        pages.add(_buildOwnerCommercialStep(context));
      } else if (provider.selectedPropertyType == 'Plot') {
        pages.add(_buildOwnerLandStep(context));
      }
    } else if (provider.leadModel.leadType == 'Tenant') {
      if (provider.selectedPropertyType == 'Residential') {
        pages.add(_buildTenantResidentialStep(context));
      } else if (provider.selectedPropertyType == 'Commercial') {
        pages.add(_buildTenantCommercialStep(context));
      } else if (provider.selectedPropertyType == 'Plot') {
        pages.add(_buildTenantLandStep(context));
      }
    } else if (provider.leadModel.leadType == 'Buyer') {
      if (provider.selectedPropertyType == 'Residential') {
        pages.add(_buildTenantResidentialStep(context));
      } else if (provider.selectedPropertyType == 'Commercial') {
        pages.add(_buildTenantCommercialStep(context));
      } else if (provider.selectedPropertyType == 'Plot') {
        pages.add(_buildTenantLandStep(context));
      }
    }

    return pages;
  }

  Widget _buildRegisterFormStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: () {
                          if (provider.leadModel.avatarColor != null) {
                            return provider.leadModel.avatarColor!;
                          } else {
                            // Generate color manually
                            final color = AvatarColorUtils.getAvatarColor(
                              provider.leadModel.leadType,
                              uniqueId: provider.leadModel.id,
                            );
                            print('Debug - Generated color: $color');
                            return color;
                          }
                        }(),
                      ),
                      child: Center(
                        child: Text(
                          (provider.leadModel?.name?.isNotEmpty ?? false)
                              ? provider.leadModel!.name![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      provider.leadModel?.name ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    _buildTextField(
                      'Name',
                      nameController,
                      provider.updateName,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 55,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('+91', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberTextFieldphonr(
                            'Phone Number',
                            _phoneController,
                            (value) => provider.updatePhoneNumber(value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSameAsPhoneToggle(provider),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 55,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('+91', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberTextFieldphonr(
                            'WhatsApp Number',
                            _whatsappController,
                            (value) => provider.updateWhatsappNumber(value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRentSaleLeaseOptions(provider),
                    const SizedBox(height: 16),
                    _buildLeadTypeDropdown(provider),
                    const SizedBox(height: 16),
                    _buildPropertyTypeDropdown(provider),
                    const SizedBox(height: 16),
                    if (provider.selectedPropertyType.toLowerCase() ==
                            'residential' &&
                        provider.leadModel.leadType.toLowerCase() ==
                            'tenant') ...[
                      _buildLeadCategoryDropdown(provider),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 24),

                    _buildPropertySubTypeOptions(provider),
                    const SizedBox(height: 24),
                    _buildNextButton(context, provider),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkingProfDropdownField(
    String label,
    String? selectedValue,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    const List<String> validValues = ['Yes', 'No'];

    // Ensure selectedValue is valid or null
    String? validatedValue =
        validValues.contains(selectedValue) ? selectedValue : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: validatedValue,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon:
                  icon != null
                      ? Icon(icon, size: 20, color: Colors.grey[600])
                      : null,
            ),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            items: const [
              DropdownMenuItem<String>(value: 'Yes', child: Text('Yes')),
              DropdownMenuItem<String>(value: 'No', child: Text('No')),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Updated widget using existing provider (corrected version)
  Widget _buildVegorNonOptions(NewLeadProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: CustomSquareRadioOption(
                text: "Vegetarian",
                isSelected:
                    provider.residentialProperty?.vegOrNonVeg == 'Vegetarian',
                onTap: () => provider.updateVegOrNonVeg('Vegetarian'),
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomSquareRadioOption(
                text: "Non Vegetarian",
                isSelected:
                    provider.residentialProperty?.vegOrNonVeg ==
                    'Non Vegetarian',
                onTap: () => provider.updateVegOrNonVeg('Non Vegetarian'),
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeadCategoryDropdown(NewLeadProvider provider) {
    final List<String> leadCategoryOptions = [
      'Bachelor(M)',
      'Bachelor(F)',
      'Unmarried couples',
      'Family',
    ];

    bool isCurrentSelectionValid = leadCategoryOptions.contains(
      provider.leadModel.leadCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:
                      (provider.leadModel.leadCategory.isEmpty ||
                              !isCurrentSelectionValid)
                          ? null
                          : provider.leadModel.leadCategory,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down),
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  hint: Text(
                    'Select Lead Category',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  items:
                      leadCategoryOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      provider.updateLeadCategory(value);
                    }
                  },
                ),
              ),
            ),
            Positioned(
              top: 5,
              left: 20,
              child: Text(
                'Lead Category',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Consumer<NewLeadProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    margin: const EdgeInsets.only(top: 0.0, left: 5, bottom: 0),
                    child: NeumorphicButton(
                      onPressed: () {
                        if (_pageController.hasClients &&
                            _pageController.page != null &&
                            _pageController.page! > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: const NeumorphicStyle(
                        shape: NeumorphicShape.convex,
                        boxShape: NeumorphicBoxShape.circle(),
                        depth: 4,
                        intensity: 0.8,
                        lightSource: LightSource.topLeft,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textColor,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen,
                        width: 1.0,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:
                            selectedValue ??
                            widget.existingLead?.status ??
                            'New Lead',
                        onChanged: (String? newValue) async {
                          if (newValue != null) {
                            setState(() {
                              selectedValue = newValue;
                              if (widget.existingLead != null) {
                                widget.existingLead!.status = newValue;
                              }
                            });

                            await _updateLeadStatusInFirestore(newValue);
                          }
                        },
                        items: _getStatusDropdownItems(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 14,
                        ),
                        isDense: true,
                        dropdownColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  // Helper method to generate dropdown items based on lead type
  List<DropdownMenuItem<String>> _getStatusDropdownItems() {
    List<String> statuses;

    // Determine lead type - adjust this based on your data structure
    String leadType =
        widget.existingLead?.leadType ??
        widget.existingLead?.leadType ??
        widget.existingLead?.leadType ??
        'Buyer'; // default fallback

    if (leadType == 'Owner') {
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
    }

    return statuses.map((String status) {
      return DropdownMenuItem<String>(value: status, child: Text(status));
    }).toList();
  }

  Future _updateLeadStatusInFirestore(String newStatus) async {
    try {
      if (widget.existingLead?.id != null) {
        final docRef = FirebaseFirestore.instance
            .collection('leads')
            .doc(widget.existingLead?.id);

        if (newStatus.toLowerCase() == 'archived') {
          await docRef.delete();
          print('Lead archived and deleted successfully');
        } else {
          await docRef.update({'status': newStatus});
          print('Lead status updated successfully');
        }
      } else {
        print('No lead ID found to update or delete');
      }
    } catch (e) {
      print('Error updating lead status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildOwnerResidentialStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        final residential = provider.residentialProperty;
        if (residential == null) return Container();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final newFacilitiesText = residential.facilities?.join(', ') ?? '';
          final newPreferencesText = residential.preferences?.join(', ') ?? '';

          if (facilitiesController.text != newFacilitiesText) {
            facilitiesController.text = newFacilitiesText;
          }
          if (preferencesController.text != newPreferencesText) {
            preferencesController.text = newPreferencesText;
          }
        });

        return SingleChildScrollView(
          child: _buildStepContainer([
            _buildBHKSection(provider),
            const SizedBox(height: 20),

            provider.currentProperty?.propertyFor == 'Lease'
                ? _buildPriceFieldCompactResidential(provider)
                : _buildNumberTextField(
                  provider.currentProperty?.propertyFor == 'Rent'
                      ? 'Asking Price (per month)'
                      : 'Asking Price',
                  askingPriceController,
                  provider.updateAskingPrice,
                ),

            const SizedBox(height: 16),

            if (provider.currentProperty?.propertyFor == 'Rent') ...[
              buildFormattedPriceTextField(
                label: 'Security Deposit',
                initialValue: residential.deposit ?? '',
                onChanged: provider.updateDeposit,
              ),
              const SizedBox(height: 16),

              buildFormattedPriceTextField(
                label: 'Maintenance (per month)',
                initialValue: residential.maintenance ?? '',
                onChanged: provider.updateMaintenance,
              ),
            ],

            const SizedBox(height: 16),

            _buildBathroomSection(provider),

            const SizedBox(height: 16),
            _buildFurnishingOptions(provider),
            const SizedBox(height: 16),

            LocationSearchTextField(
              initialValue: locationController.text,
              hintText: 'Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );
                provider.updateLocation(locationData);

                locationController.text = locationMap['address'] ?? '';
              },
              controller: locationController,
            ),

            const SizedBox(height: 16),
            ChipInputField(
              label: 'Facilities',
              selectedItems: residential.facilities ?? [],
              onAdd: (facility) => provider.addCustomFacility(facility),
              onRemove: (facility) => provider.toggleFacility(facility),
              hintText: 'Add facilities (separate with commas)',
            ),
            const SizedBox(height: 16),
            ChipRow(
              options: const [
                'Car Parking',
                'Security 24x7',
                'Gated Society',
                'Power Backup',
                'Lift',
                'Club House',
                'Waste Management',
                'Gym',
              ],
              selectedOptions: residential.facilities ?? [],
              onToggle: (facility) => provider.toggleFacility(facility),
              onAddNew: (facility) => provider.addCustomFacility(facility),
            ),
            const SizedBox(height: 16),
            ChipInputField(
              label: 'Preferences',
              selectedItems: residential.preferences ?? [],
              onAdd: (preference) => provider.addCustomPreference(preference),
              onRemove: (preference) => provider.togglePreference(preference),
              hintText: 'Add preferences (separate with commas)',
            ),
            const SizedBox(height: 16),
            ChipRow(
              options: const [
                'Family',
                'Vegetarian',
                'Working Women',
                'Bachelor(M)',
                'Bachelor(F)',
                'Working Professionals',
                'Married Couples',
                'Unmarried Couples',
              ],
              selectedOptions: residential.preferences ?? [],
              onToggle: (preference) => provider.togglePreference(preference),
              onAddNew:
                  (preference) => provider.addCustomPreference(preference),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Additional Notes',
              additionalNotesController,
              provider.updateAdditionalNotes,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildCompleteButton(context, provider),
            const SizedBox(height: 16),
          ]),
        );
      },
    );
  }

  Widget _buildPriceFieldCompactResidential(NewLeadProvider provider) {
    final residential = provider.residentialProperty;
    if (residential == null) return Container();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildNumberTextField(
            'Asking Price',
            askingPriceController,
            provider.updateAskingPrice,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 55,
          width: 90,
          child: DropdownButtonFormField<String>(
            value: provider.leaseDuration ?? '/month',
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            items: const [
              DropdownMenuItem(
                value: '/month',
                child: Text('/month', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem(
                value: '/year',
                child: Text('/year', style: TextStyle(fontSize: 14)),
              ),
            ],
            onChanged: provider.updateLeaseDuration,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerCommercialStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        final commercial = provider.commercialProperty;
        if (commercial == null) return Container();

        return SingleChildScrollView(
          child: _buildStepContainer([
            provider.currentProperty?.propertyFor == 'Lease'
                ? _buildPriceFieldCompactCommercial(provider)
                : _buildNumberTextField(
                  provider.currentProperty?.propertyFor == 'Rent'
                      ? 'Asking Price (per month)'
                      : 'Asking Price',
                  askingPriceController,
                  (value) {
                    provider.updateAskingPrice(value);
                  },
                ),
            const SizedBox(height: 16),

            _buildTextField(
              'Square Feet',
              squareFeetController,
              provider.updateSquareFeet,
            ),
            const SizedBox(height: 16),

            LocationSearchTextField(
              initialValue: locationController.text,
              hintText: 'Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );
                provider.updateLocation(locationData);

                locationController.text = locationMap['address'] ?? '';
              },
              controller: locationController,
            ),
            const SizedBox(height: 16),

            ChipInputField(
              label: '🛠️ Facilities',
              selectedItems: commercial.facilities ?? [],
              onAdd:
                  (facility) => provider.addCustomCommercialFacility(facility),
              onRemove:
                  (facility) => provider.toggleCommercialFacility(facility),
              hintText: 'Add facilities (separate with commas)',
            ),
            const SizedBox(height: 16),

            ChipRow(
              options: const [
                'Car Parking',
                'Security 24x7',
                'Gated Society',
                'Power Backup',
                'Lift',
                'Club House',
                'Waste Management',
                'Gym',
              ],
              selectedOptions: commercial.facilities ?? [],
              onToggle:
                  (facility) => provider.toggleCommercialFacility(facility),
              onAddNew:
                  (facility) => provider.addCustomCommercialFacility(facility),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 16),

            _buildTextField(
              'No of Washrooms',
              washroomsController,
              provider.updateWashroomFacilities,
            ),
            SizedBox(height: 16),

            _buildCommercialFurnishingOptions(provider),

            SizedBox(height: 16),
            _buildTextField(
              'Number of Seats',
              seatsController,
              provider.updateseatFacilities,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Additional Notes',
              additionalNotesController,
              provider.updateAdditionalNotes,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildCompleteButton(context, provider),
            const SizedBox(height: 16),
          ]),
        );
      },
    );
  }

  Widget _buildPriceFieldCompactCommercial(NewLeadProvider provider) {
    final commercial = provider.commercialProperty;
    if (commercial == null) return Container();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildNumberTextField('Asking Price', askingPriceController, (
            value,
          ) {
            provider.updateAskingPrice(value);
          }),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 55,
          width: 90,
          child: DropdownButtonFormField<String>(
            value: provider.leaseDuration ?? '/month',
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            items: const [
              DropdownMenuItem(
                value: '/month',
                child: Text('/month', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem(
                value: '/year',
                child: Text('/year', style: TextStyle(fontSize: 14)),
              ),
            ],
            onChanged: provider.updateLeaseDuration,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerLandStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        final land = provider.landProperty;
        if (land == null) return Container();

        return SingleChildScrollView(
          child: _buildStepContainer([
            provider.currentProperty?.propertyFor == 'Lease'
                ? _buildPriceFieldCompact(provider)
                : _buildNumberTextField(
                  provider.currentProperty?.propertyFor == 'Rent'
                      ? 'Asking Price (per month)'
                      : 'Asking Price',
                  askingPriceController,
                  provider.updateAskingPrice,
                ),

            SizedBox(height: 16),
            _buildAreaTextField(provider),
            SizedBox(height: 16),
            LocationSearchTextField(
              initialValue: locationController.text,
              hintText: 'Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );
                provider.updateLocation(locationData);

                locationController.text = locationMap['address'] ?? '';
              },
              controller: locationController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Additional Notes',
              additionalNotesController,
              provider.updateAdditionalNotes,
              maxLines: 3,
            ),
            SizedBox(height: 24),
            _buildCompleteButton(context, provider),
            SizedBox(height: 16),
          ]),
        );
      },
    );
  }

  Widget _buildPriceFieldCompact(NewLeadProvider provider) {
    final land = provider.landProperty;
    if (land == null) return Container();

    final isLease = provider.currentProperty?.propertyFor == 'Lease';

    return isLease
        ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildNumberTextField(
                'Asking Price',
                askingPriceController,
                provider.updateAskingPrice,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 55,
              width: 90,
              child: DropdownButtonFormField<String>(
                value: provider.leaseDuration ?? '/month',
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                items: const [
                  DropdownMenuItem(
                    value: '/month',
                    child: Text('/month', style: TextStyle(fontSize: 14)),
                  ),
                  DropdownMenuItem(
                    value: '/year',
                    child: Text('/year', style: TextStyle(fontSize: 14)),
                  ),
                ],
                onChanged: provider.updateLeaseDuration,
              ),
            ),
          ],
        )
        : _buildTextField(
          provider.currentProperty?.propertyFor == 'Rent'
              ? 'Asking Price(Per Month)'
              : 'Asking Price',
          askingPriceController,
          provider.updateAskingPrice,
        );
  }

  Widget _buildTenantResidentialStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        final residential = provider.residentialProperty;
        if (residential == null) return Container();

        return SingleChildScrollView(
          child: _buildStepContainer([
            _buildBHKSection(provider),
            SizedBox(height: 16),
            provider.currentProperty?.propertyFor == 'Lease'
                ? _buildBudgetFieldCompactResidential(provider)
                : _buildNumberTextField(
                  (provider.currentProperty?.propertyFor == 'Sale' &&
                          provider.leadModel.leadType == 'Buyer')
                      ? 'Budget'
                      : provider.currentProperty?.propertyFor == 'Rent'
                      ? 'Budget (per month)'
                      : 'Budget',
                  askingPriceController,
                  provider.updateAskingPrice,
                ),

            SizedBox(height: 16),
            _buildFurnishingOptions(provider),
            SizedBox(height: 16),
            LocationSearchTextField(
              initialValue: locationController.text,
              hintText: 'Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );
                provider.updateLocation(locationData);

                locationController.text = locationMap['address'] ?? '';
              },
              controller: locationController,
            ),

            if (provider.leadModel.leadType == 'Tenant') ...[
              SizedBox(height: 25),

              _buildVegorNonOptions(provider),
              SizedBox(height: 25),
              _buildWorkingProfDropdownField(
                'Working Professionals',
                provider.workingProfessionals ?? '',
                (value) => provider.updateWorkingProfessionals(value),
              ),
            ],

            SizedBox(height: 16),

            ChipInputField(
              label: 'Facilities',
              selectedItems: residential.facilities ?? [],
              onAdd: (facility) => provider.addCustomFacility(facility),
              onRemove: (facility) => provider.toggleFacility(facility),

              hintText: 'Add facilities (separate with commas)',
            ),
            const SizedBox(height: 16),

            ChipRow(
              options: const [
                'Car Parking',
                'Security 24x7',
                'Gated Society',
                'Power Backup',
                'Lift',
                'Club House',
                'Waste Management',
                'Gym',
              ],
              selectedOptions: residential.facilities ?? [],
              onToggle: (facility) => provider.toggleFacility(facility),
              onAddNew: (facility) => provider.addCustomFacility(facility),
            ),

            SizedBox(height: 16),
            _buildTextField(
              'Additional Requirements',
              additionalNotesController,
              provider.updateAdditionalRequirements,
              maxLines: 3,
            ),
            SizedBox(height: 24),
            _buildCompleteButton(context, provider),
            SizedBox(height: 16),
          ]),
        );
      },
    );
  }

  Widget _buildBudgetFieldCompactResidential(NewLeadProvider provider) {
    final residential = provider.residentialProperty;
    if (residential == null) return Container();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildNumberTextField(
            'Budget',
            askingPriceController,
            provider.updateAskingPrice,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 55,
          width: 90,
          child: DropdownButtonFormField<String>(
            value: provider.leaseDuration ?? '/month',
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            items: const [
              DropdownMenuItem(
                value: '/month',
                child: Text('/month', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem(
                value: '/year',
                child: Text('/year', style: TextStyle(fontSize: 14)),
              ),
            ],
            onChanged: provider.updateLeaseDuration,
          ),
        ),
      ],
    );
  }

  Widget _buildTenantCommercialStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        final commercial = provider.commercialProperty;
        if (commercial == null) return Container();

        return SingleChildScrollView(
          child: _buildStepContainer([
            provider.currentProperty?.propertyFor == 'Lease'
                ? _buildBudgetFieldCompactCommercial(provider)
                : _buildNumberTextField(
                  (provider.currentProperty?.propertyFor == 'Sale' &&
                          provider.leadModel.leadType == 'Buyer')
                      ? 'Budget'
                      : provider.currentProperty?.propertyFor == 'Rent'
                      ? 'Budget (per month)'
                      : 'Budget',
                  askingPriceController,
                  provider.updateAskingPrice,
                ),
            SizedBox(height: 16),
            _buildTextField(
              'Sq Ft',
              squareFeetController,
              provider.updateSquareFeet,
            ),
            LocationSearchTextField(
              initialValue: locationController.text,
              hintText: 'Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );
                provider.updateLocation(locationData);

                locationController.text = locationMap['address'] ?? '';
              },
              controller: locationController,
            ),
            const SizedBox(height: 16),
            SizedBox(height: 16),

            _buildTextField(
              'No of Washrooms',
              washroomsController,
              provider.updateWashroomFacilities,
            ),
            SizedBox(height: 16),

            _buildCommercialFurnishingOptions(provider),

            SizedBox(height: 16),
            _buildTextField(
              'Number of Seats',
              seatsController,
              provider.updateseatFacilities,
            ),
            SizedBox(height: 16),
            ChipInputField(
              label: '🛠️ Facilities',
              selectedItems: commercial.facilities ?? [],
              onAdd:
                  (facility) => provider.addCustomCommercialFacility(facility),
              onRemove:
                  (facility) => provider.toggleCommercialFacility(facility),
              hintText: 'Add facilities (separate with commas)',
            ),
            const SizedBox(height: 16),

            ChipRow(
              options: const [
                'Lift',
                'Power Backup',
                'Car Parking',
                '24x7 Security',
                'CCTV Surveillance',
                'Furnished',
                'Gym',
                'Swimming Pool',
                'Children Play Area',
                'Gated Community',
              ],
              selectedOptions: commercial.facilities ?? [],
              onToggle:
                  (facility) => provider.toggleCommercialFacility(facility),
              onAddNew:
                  (facility) => provider.addCustomCommercialFacility(facility),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 16),
            _buildTextField(
              'Additional Notes',
              specialRequirementsController,
              provider.updateSpecialRequirements,
              maxLines: 3,
            ),
            SizedBox(height: 24),
            _buildCompleteButton(context, provider),
            SizedBox(height: 16),
          ]),
        );
      },
    );
  }

  Widget _buildBudgetFieldCompactCommercial(NewLeadProvider provider) {
    final commercial = provider.commercialProperty;
    if (commercial == null) return Container();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildNumberTextField(
            'Budget',
            askingPriceController,
            provider.updateAskingPrice,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 55,
          width: 90,
          child: DropdownButtonFormField<String>(
            value: provider.leaseDuration ?? '/month',
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            items: const [
              DropdownMenuItem(
                value: '/month',
                child: Text('/month', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem(
                value: '/year',
                child: Text('/year', style: TextStyle(fontSize: 14)),
              ),
            ],
            onChanged: provider.updateLeaseDuration,
          ),
        ),
      ],
    );
  }

  Widget _buildTenantLandStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        final land = provider.landProperty;
        if (land == null) return Container();

        return SingleChildScrollView(
          child: _buildStepContainer([
            provider.currentProperty?.propertyFor == 'Lease'
                ? _buildBudgetFieldCompactLand(provider)
                : _buildNumberTextField(
                  provider.currentProperty?.propertyFor == 'Rent'
                      ? 'Budget (per month)'
                      : 'Budget',
                  askingPriceController,
                  provider.updateAskingPrice,
                ),

            SizedBox(height: 16),

            _buildAreaTextField(provider),

            SizedBox(height: 16),

            LocationSearchTextField(
              initialValue: locationController.text,
              hintText: 'Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );
                provider.updateLocation(locationData);

                locationController.text = locationMap['address'] ?? '';
              },
              controller: locationController,
            ),
            SizedBox(height: 16),

            _buildTextField(
              'Additional Requirements',
              additionalNotesController,
              provider.updateAdditionalNotes,
              maxLines: 3,
            ),
            SizedBox(height: 24),
            _buildCompleteButton(context, provider),
            SizedBox(height: 16),
          ]),
        );
      },
    );
  }

  Widget _buildBudgetFieldCompactLand(NewLeadProvider provider) {
    final land = provider.landProperty;
    if (land == null) return Container();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildNumberTextField(
            'Budget',
            askingPriceController,
            provider.updateAskingPrice,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 55,
          width: 90,
          child: DropdownButtonFormField<String>(
            value: provider.leaseDuration ?? '/month',
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            items: const [
              DropdownMenuItem(
                value: '/month',
                child: Text('/month', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem(
                value: '/year',
                child: Text('/year', style: TextStyle(fontSize: 14)),
              ),
            ],
            onChanged: provider.updateLeaseDuration,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaTextField(NewLeadProvider provider) {
    String selectedUnit =
        provider.selectedAreaUnit ?? _determineInitialUnit(provider);

    final currentSqft =
        double.tryParse(provider.landProperty?.squareFeet ?? '0') ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
          'Area Unit',
          selectedUnit,
          ['Square Feet', 'Acre & Cent'],
          (value) {
            provider.updateAreaUnit(value);

            if (value == 'Square Feet') {
              provider.clearAcreAndCentData();
            } else {
              provider.clearSquareFeetData();
            }
          },
          icon: Icons.straighten,
        ),

        if (selectedUnit == 'Square Feet')
          _buildSquareFeetField(provider, currentSqft)
        else if (selectedUnit == 'Acre & Cent')
          _buildAcreAndCentFields(provider, currentSqft),
      ],
    );
  }

  String _determineInitialUnit(NewLeadProvider provider) {
    final property = provider.landProperty;

    if (property?.acres != null && property!.acres!.isNotEmpty) {
      return 'Acre & Cent';
    }

    if (property?.squareFeet != null && property!.squareFeet!.isNotEmpty) {
      return 'Square Feet';
    }

    return 'Square Feet';
  }

  void _prefillAreaData(NewLeadProvider provider) {
    final property = provider.landProperty;

    if (property != null) {
      if (property.squareFeet != null && property.squareFeet!.isNotEmpty) {
        provider.updateSquareFeet(property.squareFeet!);
        squareFeetController.text = property.squareFeet!;
      }

      if (property.acres != null && property.acres!.isNotEmpty) {
        final acres = property.acres!;
        final cents = property.cents ?? '0';
        provider.updateAcresAndCents(acres, cents);
        acresController.text = acres;
        centsController.text = cents;
      }

      final initialUnit = _determineInitialUnit(provider);
      provider.updateAreaUnit(initialUnit);
    }
  }

  String _formatNumber(double number) {
    if (number == number.roundToDouble()) {
      return number.round().toString();
    } else {
      return number.toStringAsFixed(2);
    }
  }

  Widget _buildSquareFeetField(NewLeadProvider provider, double currentSqft) {
    if (squareFeetController.text.isEmpty && currentSqft > 0) {
      squareFeetController.text = _formatNumber(currentSqft);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: squareFeetController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: 'Square Feet',
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: Icon(Icons.area_chart, size: 20, color: Colors.grey[600]),
        ),
        onChanged: (value) {
          provider.updateSquareFeet(value);
        },
      ),
    );
  }

  Widget _buildAcreAndCentFields(NewLeadProvider provider, double currentSqft) {
    final currentAcres = provider.landProperty?.acres ?? '';
    final currentCents = provider.landProperty?.cents ?? '';

    if (acresController.text.isEmpty && currentAcres != '') {
      acresController.text = currentAcres;
    }
    if (centsController.text.isEmpty && currentCents != '') {
      centsController.text = currentCents;
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              controller: acresController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Acres',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: Icon(
                  Icons.landscape,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
              onChanged: (acresValue) {
                final centsValue =
                    centsController.text.isEmpty ? '0' : centsController.text;
                provider.updateAcresAndCents(acresValue, centsValue);
              },
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              controller: centsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Cents',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: Icon(
                  Icons.square_foot,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
              onChanged: (centsValue) {
                final acresValue =
                    acresController.text.isEmpty ? '0' : acresController.text;
                provider.updateAcresAndCents(acresValue, centsValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContainer(List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildNumberTextFieldphonr(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: maxLines > 1 ? null : 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 10, // Limit to 10 digits
            onChanged: (value) {
              // Filter only digits
              String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits != value) {
                controller.value = TextEditingValue(
                  text: digits,
                  selection: TextSelection.collapsed(offset: digits.length),
                );
              }
              onChanged(digits);
            },
            maxLines: maxLines,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              counterText: '', // Hide counter
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon:
                  icon != null
                      ? Icon(icon, size: 20, color: Colors.grey[600])
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: maxLines > 1 ? null : 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            keyboardType:
                label.contains('number') ? TextInputType.number : null,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon:
                  icon != null
                      ? Icon(icon, size: 20, color: Colors.grey[600])
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNumberTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    int maxLines = 1,
    IconData? icon,
    TextInputType keyboardType = TextInputType.number,
    bool enabled = true,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: maxLines > 1 ? null : 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            validator: validator,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            onChanged: (value) {
              String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
              if (digitsOnly.isEmpty) {
                controller.text = '';
                return;
              }

              String formatted = _indianFormat.format(int.parse(digitsOnly));
              controller.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );

              onChanged(formatted);
            },
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText,
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon:
                  icon != null
                      ? Icon(icon, size: 20, color: Colors.grey[600])
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBHKSection(NewLeadProvider provider) {
    final bhkOptions = ['1RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5 BHK'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 3;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children:
              bhkOptions.map((bhk) {
                return SizedBox(
                  width: itemWidth,
                  child: CustomSquareRadioOption(
                    size: 24,
                    text: bhk,
                    isSelected:
                        provider.residentialProperty?.selectedBHK == bhk,
                    onTap: () => provider.updateSelectedBHK(bhk),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildFurnishingOptions(NewLeadProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: CustomSquareRadioOption(
                text: "Furnished",
                isSelected: provider.residentialProperty?.furnished ?? false,
                size: 22,
                onTap: () {
                  provider.updateUnfurnished(false);
                  provider.updateSemiFinished(false);
                  provider.updateFurnished(
                    !(provider.residentialProperty?.furnished ?? false),
                  );
                },
              ),
            ),
            Expanded(
              child: CustomSquareRadioOption(
                text: "Unfurnished",
                isSelected: provider.residentialProperty?.unfurnished ?? false,
                size: 22,
                onTap: () {
                  provider.updateFurnished(false);
                  provider.updateSemiFinished(false);
                  provider.updateUnfurnished(
                    !(provider.residentialProperty?.unfurnished ?? false),
                  );
                },
              ),
            ),
            Expanded(
              child: CustomSquareRadioOption(
                text: "Semi-Furnished",
                isSelected: provider.residentialProperty?.semiFinished ?? false,
                size: 22,
                onTap: () {
                  provider.updateFurnished(false);
                  provider.updateUnfurnished(false);
                  provider.updateSemiFinished(
                    !(provider.residentialProperty?.semiFinished ?? false),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommercialFurnishingOptions(NewLeadProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: CustomSquareRadioOption(
                text: "Furnished",
                isSelected:
                    provider.commercialProperty?.furnished == "Furnished",
                size: 22,
                onTap: () {
                  provider.updateCommercialFurnishingType("Furnished");
                },
              ),
            ),
            Expanded(
              child: CustomSquareRadioOption(
                text: "Unfurnished",
                isSelected:
                    provider.commercialProperty?.furnished == "Unfurnished",
                size: 22,
                onTap: () {
                  provider.updateCommercialFurnishingType("Unfurnished");
                },
              ),
            ),
            Expanded(
              child: CustomSquareRadioOption(
                text: "Semi-Furnished",
                isSelected:
                    provider.commercialProperty?.furnished == "Semi-Furnished",
                size: 22,
                onTap: () {
                  provider.updateCommercialFurnishingType("Semi-Furnished");
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderSelection(NewLeadProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildGenderOption(
          'Male',
          provider.leadModel.gender == 'Male',
          () => provider.updateGender('Male'),
        ),
        SizedBox(width: 20),
        _buildGenderOption(
          'Female',
          provider.leadModel.gender == 'Female',
          () => provider.updateGender('Female'),
        ),
        SizedBox(width: 20),
        _buildGenderOption(
          'Other',
          provider.leadModel.gender == 'Other',
          () => provider.updateGender('Other'),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.textColor : Colors.grey.shade400,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child:
                isSelected
                    ? Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.textColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                    : null,
          ),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 25),
        ],
      ),
    );
  }

  Widget _buildSameAsPhoneToggle(NewLeadProvider provider) {
    final isOn = provider.leadModel.sameAsPhone ?? false;

    return Row(
      children: [
        Text(
          'Same as Phone Number',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        SizedBox(width: 20),
        GestureDetector(
          onTap: () {
            final newValue = !isOn;

            provider.updateSameAsPhone(newValue);
          },
          child: Container(
            width: 50,
            height: 24,
            alignment: Alignment.center,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 35,
                    height: 15,
                    decoration: BoxDecoration(
                      color:
                          isOn
                              ? const Color.fromARGB(255, 58, 102, 131)
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                AnimatedAlign(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment:
                      isOn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: isOn ? AppColors.textColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isOn ? AppColors.textColor : Colors.grey.shade400,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child:
                        isOn
                            ? Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: value?.isEmpty == true ? null : value,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon:
                  icon != null
                      ? Icon(icon, size: 20, color: Colors.grey[600])
                      : null,
            ),
            icon: const SizedBox.shrink(),
            items:
                options
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdownFieldCustomArrow(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            children: [
              DropdownButtonFormField<String>(
                value: value?.isEmpty == true ? null : value,
                onChanged: onChanged,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                icon: const SizedBox.shrink(),
                items:
                    options
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
              ),

              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Icon(
                  icon ?? Icons.arrow_drop_down,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRentSaleLeaseOptions(NewLeadProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildPropertyForOption(
              'Rent',
              provider.currentProperty?.propertyFor == 'Rent',
              () {
                provider.updatePropertyFor('Rent');

                if (provider.leadModel.leadType.isEmpty ||
                    ![
                      'Owner',
                      'Tenant',
                    ].contains(provider.leadModel.leadType)) {
                  provider.updateLeadType('');
                }
              },
            ),
            SizedBox(width: 20),
            _buildPropertyForOption(
              'Sale',
              provider.currentProperty?.propertyFor == 'Sale',
              () {
                provider.updatePropertyFor('Sale');

                provider.updateLeadType('Owner');
              },
            ),
            SizedBox(width: 20),
            _buildPropertyForOption(
              'Lease',
              provider.currentProperty?.propertyFor == 'Lease',
              () {
                provider.updatePropertyFor('Lease');

                if (provider.leadModel.leadType.isEmpty ||
                    ![
                      'Owner',
                      'Tenant',
                    ].contains(provider.leadModel.leadType)) {
                  provider.updateLeadType('');
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeadTypeDropdown(NewLeadProvider provider) {
    List<String> getLeadTypeOptions() {
      String? propertyFor = provider.currentProperty?.propertyFor;

      switch (propertyFor) {
        case 'Sale':
          return ['Owner', 'Buyer'];
        case 'Rent':
        case 'Lease':
          return ['Owner', 'Tenant'];
        default:
          return ['Owner', 'Tenant'];
      }
    }

    List<String> availableOptions = getLeadTypeOptions();

    bool isCurrentSelectionValid = availableOptions.contains(
      provider.leadModel.leadType,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:
                      (provider.leadModel.leadType.isEmpty ||
                              !isCurrentSelectionValid)
                          ? null
                          : provider.leadModel.leadType,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down),
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  hint: Text(
                    'Select Lead Type',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  items:
                      availableOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                  onChanged: (String? value) {
                    provider.updateLeadCategory("");
                    if (value != null) {
                      provider.updateLeadType(value);
                    }
                  },
                ),
              ),
            ),
            Positioned(
              top: 5,
              left: 20,
              child: Text(
                'Lead Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyForOption(
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.textColor : Colors.grey.shade400,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child:
                isSelected
                    ? Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.textColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                    : null,
          ),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeDropdown(NewLeadProvider provider) {
    List<String> getPropertyTypes() {
      if (provider.leadModel.leadType == 'Tenant') {
        return ['Residential', 'Commercial', 'Plot'];
      } else {
        return ['Residential', 'Commercial', 'Plot'];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:
                      provider.selectedPropertyType.isEmpty ||
                              !getPropertyTypes().contains(
                                provider.selectedPropertyType,
                              )
                          ? null
                          : provider.selectedPropertyType,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down),
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  hint: Text(
                    'Select Property Type',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  items:
                      getPropertyTypes()
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                  onChanged: (String? value) {
                    provider.updateLeadCategory("");

                    if (value != null) {
                      provider.updatePropertyType(value);
                    }
                  },
                ),
              ),
            ),
            Positioned(
              top: 5,
              left: 20,
              child: Text(
                'Property Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertySubTypeOptions(NewLeadProvider provider) {
    if (provider.currentProperty == null) {
      return SizedBox.shrink();
    }

    switch (provider.selectedPropertyType) {
      case 'Residential':
        return _buildResidentialSubTypes(provider);
      case 'Commercial':
        return _buildCommercialSubTypes(provider);
      case 'Plot':
        return _buildLandSubTypes(provider);
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildResidentialSubTypes(NewLeadProvider provider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertySubOption(
              'Flat/Apartment',
              provider.selectedSubType == 'Flat/Apartment',
              () => provider.selectPropertySubType('Flat/Apartment'),
            ),
            SizedBox(width: 15),

            _buildPropertySubOption(
              'House/Villa',
              provider.selectedSubType == 'House/Villa',
              () => provider.selectPropertySubType('House/Villa'),
            ),

            SizedBox(width: 15),

            _buildPropertySubOption(
              'Other',
              provider.selectedSubType == 'Other',
              () => provider.selectPropertySubType('Other'),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBathroomSection(NewLeadProvider provider) {
    final residential = provider.residentialProperty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bathrooms',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildBathroomTextField(
                'Attached',
                attachedBathroomController,
                provider.updateBathroomAttached,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBathroomTextField(
                'Common',
                commonBathroomController,
                provider.updateBathroomCommon,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBathroomTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          suffixIcon: Icon(
            Icons.bathroom_outlined,
            size: 20,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildCommercialSubTypes(NewLeadProvider provider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertySubOption(
              'Office Space',
              provider.selectedSubType == 'Office Space',
              () => provider.selectPropertySubType('Office Space'),
            ),

            SizedBox(width: 35),
            _buildPropertySubOption(
              'Shop/Showroom',
              provider.selectedSubType == 'Shop/Showroom',
              () => provider.selectPropertySubType('Shop/Showroom'),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertySubOption(
              'Go down',
              provider.selectedSubType == 'Go down',
              () => provider.selectPropertySubType('Go down'),
            ),
            SizedBox(width: 35),

            _buildPropertySubOption(
              'Other',
              provider.selectedSubType == 'Other',
              () => provider.selectPropertySubType('Other'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLandSubTypes(NewLeadProvider provider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertySubOption(
              'Agriculture',
              provider.selectedSubType == 'Agriculture',
              () => provider.selectPropertySubType('Agriculture'),
            ),
            SizedBox(width: 5),

            _buildPropertySubOption(
              'Residential',
              provider.selectedSubType == 'Residential',
              () => provider.selectPropertySubType('Residential'),
            ),
            SizedBox(width: 5),

            _buildPropertySubOption(
              'Commercial',
              provider.selectedSubType == 'Commercial',
              () => provider.selectPropertySubType('Commercial'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertySubOption(
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.textColor : Colors.grey.shade400,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child:
                isSelected
                    ? Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.textColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                    : null,
          ),
          SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, NewLeadProvider provider) {
    return Container(
      width: double.infinity,
      height: 50,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                await provider.updateLead();
                if (provider.isSuccess) {
                  Navigator.pop(context, true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lead updated successfully!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'Failed to update lead',
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context, NewLeadProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          // Validate all required fields
          String? validationError = _validateRequiredFields(provider);

          if (validationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validationError),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          await provider.updateLead();
          if (provider.isSuccess) {
            Navigator.pop(context, true);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lead updated successfully!'),
                backgroundColor: AppColors.primaryGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage ?? 'Failed to update lead'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            provider.isLoading
                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  String? _validateRequiredFields(NewLeadProvider provider) {
    // Basic lead information validation
    if (nameController.text.isEmpty) {
      return 'Name is required';
    }

    if (_phoneController.text.isEmpty) {
      return 'Phone number is required';
    }

    if (_whatsappController.text.isEmpty) {
      return 'WhatsApp number is required';
    }

    if (provider.currentProperty?.propertyFor?.isEmpty ?? true) {
      return 'Property for (Rent/Sale/Lease) is required';
    }

    if (provider.leadModel.leadType?.isEmpty ?? true) {
      return 'Lead type is required';
    }

    if (provider.selectedPropertyType?.isEmpty ?? true) {
      return 'Property type is required';
    }

    if (provider.selectedSubType?.isEmpty ?? true) {
      return 'Property sub-type is required';
    }

    // Property-specific validation
    if (provider.selectedPropertyType == 'Residential') {
      return _validateResidentialProperty(provider);
    } else if (provider.selectedPropertyType == 'Commercial') {
      return _validateCommercialProperty(provider);
    } else if (provider.selectedPropertyType == 'Plot') {
      return _validateLandProperty(provider);
    }

    return null; // All validations passed
  }

  String? _validateResidentialProperty(NewLeadProvider provider) {
    final residential = provider.residentialProperty;
    final lead = provider.leadModel;

    if (residential == null) {
      return 'Residential property details are required';
    }

    // BHK validation
    if (residential.selectedBHK?.isEmpty ?? true) {
      return 'BHK selection is required';
    }

    // Price/Budget validation
    if (askingPriceController.text.isEmpty) {
      String label =
          provider.leadModel.leadType == 'Owner' ? 'Asking price' : 'Budget';
      return '$label is required';
    }

    // Bathroom validation
    if (lead.leadType != 'Tenant') {
      if ((residential.bathroomAttached == '0') &&
          (residential.bathroomCommon == '0')) {
        return 'At least one bathroom (Attached or Common) is required';
      }
    }
    // Furnishing validation
    if (!(residential.furnished ?? false) &&
        !(residential.unfurnished ?? false) &&
        !(residential.semiFinished ?? false)) {
      return 'Furnishing type is required';
    }

    // Location validation
    if (locationController.text.isEmpty) {
      return 'Location is required';
    }

    // Lead category validation for tenant residential
    if (provider.selectedPropertyType.toLowerCase() == 'residential' &&
        provider.leadModel.leadType.toLowerCase() == 'tenant' &&
        (provider.leadModel.leadCategory?.isEmpty ?? true)) {
      return 'Lead category is required';
    }

    return null;
  }

  String? _validateCommercialProperty(NewLeadProvider provider) {
    final commercial = provider.commercialProperty;

    if (commercial == null) {
      return 'Commercial property details are required';
    }

    // Price/Budget validation
    if (askingPriceController.text.isEmpty) {
      String label =
          provider.leadModel.leadType == 'Owner' ? 'Asking price' : 'Budget';
      return '$label is required';
    }

    // Square feet validation
    if (squareFeetController.text.isEmpty) {
      return 'Square feet is required';
    }

    // Location validation
    if (locationController.text.isEmpty) {
      return 'Location is required';
    }

    // Washrooms validation
    if (washroomsController.text.isEmpty) {
      return 'Number of washrooms is required';
    }

    // Furnishing validation
    if (commercial.furnished?.isEmpty ?? true) {
      return 'Furnishing type is required';
    }

    // Number of seats validation
    if (seatsController.text.isEmpty) {
      return 'Number of seats is required';
    }

    return null;
  }

  String? _validateLandProperty(NewLeadProvider provider) {
    final land = provider.landProperty;

    if (land == null) {
      return 'Land property details are required';
    }

    // Price/Budget validation
    if (askingPriceController.text.isEmpty) {
      String label =
          provider.leadModel.leadType == 'Owner' ? 'Asking price' : 'Budget';
      return '$label is required';
    }

    // Area validation
    final selectedUnit = provider.selectedAreaUnit ?? 'Square Feet';
    if (selectedUnit == 'Square Feet') {
      if (squareFeetController.text.isEmpty) {
        return 'Square feet is required';
      }
    } else if (selectedUnit == 'Acre & Cent') {
      if (acresController.text.isEmpty && centsController.text.isEmpty) {
        return 'Acres or cents is required';
      }
    }

    // Location validation
    if (locationController.text.isEmpty) {
      return 'Location is required';
    }

    return null;
  }
}
