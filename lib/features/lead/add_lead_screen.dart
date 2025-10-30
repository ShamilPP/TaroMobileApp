import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/view/home_sreen.dart';
import 'package:taro_mobile/features/lead/add_lead_controller.dart';
import 'package:taro_mobile/features/lead/location_picker.dart';
import 'package:taro_mobile/core/widgets/chip_widget.dart';
import 'package:taro_mobile/core/widgets/custom_radio_button.dart';
import 'package:taro_mobile/core/widgets/number_budget_textfield.dart';

class NewLeadFormScreen extends StatefulWidget {
  final String? prefilledPhoneNumber;

  const NewLeadFormScreen({super.key, this.prefilledPhoneNumber});
  @override
  State<NewLeadFormScreen> createState() => _NewLeadFormScreenState();
}

class _NewLeadFormScreenState extends State<NewLeadFormScreen> {
  final PageController _pageController = PageController();
  LocationData? homeLocation;

  late TextEditingController facilitiesController;
  late TextEditingController preferencesController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  final TextEditingController _acresController = TextEditingController();
  final TextEditingController _centsController = TextEditingController();
  final TextEditingController _squareFeetController = TextEditingController();
  @override
  void initState() {
    super.initState();

    facilitiesController = TextEditingController();
    preferencesController = TextEditingController();
    _phoneController = TextEditingController();
    _whatsappController = TextEditingController();
    if (widget.prefilledPhoneNumber != null &&
        widget.prefilledPhoneNumber!.isNotEmpty) {
      final formattedNumber = _formatPhoneNumber(widget.prefilledPhoneNumber!);
      _phoneController.text = formattedNumber;

      // IMPORTANT: Update the provider state as well
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<NewLeadProvider>(
          context,
          listen: false,
        ).updatePhoneNumber(formattedNumber);
      });
    }
  }

  @override
  void dispose() {
    facilitiesController.dispose();
    preferencesController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _pageController.dispose();
    _acresController.dispose();
    _centsController.dispose();
    _squareFeetController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters and return clean number
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  void _clearAllFields() {
    facilitiesController.clear();
    preferencesController.clear();
    _phoneController.clear();
    _whatsappController.clear();
    _acresController.clear();
    _centsController.clear();
    _squareFeetController.clear();
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
        final providerPhone = provider.leadModel.phoneNumber ?? '';
        final providerWhatsapp = provider.leadModel.whatsappNumber ?? '';

        // Update phone controller only if provider value is different and not empty
        if (providerPhone.isNotEmpty &&
            _phoneController.text != providerPhone) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _phoneController.text = providerPhone;
            }
          });
        }

        // Update WhatsApp controller only if provider value is different and not empty
        if (providerWhatsapp.isNotEmpty &&
            _whatsappController.text != providerWhatsapp) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _whatsappController.text = providerWhatsapp;
            }
          });
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  top: 16.0,
                  bottom: 8.0,
                ),
                child: Text(
                  "New Lead",
                  style: GoogleFonts.inter(
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    _buildTextField(
                      'Name',
                      provider.leadModel.name,
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
                          child: _buildNumberTextFieldPhone(
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
                          child: _buildNumberTextFieldPhone(
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
                    const SizedBox(height: 16),
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

                  _buildProgressBar(provider.currentStep, provider),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  final NumberFormat _indianFormat = NumberFormat.decimalPattern('en_IN');

  Widget _buildNumberPriceField(
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

  Widget _buildProgressBar(int currentStep, NewLeadProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Step ${currentStep + 1} of 2',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 100,
            height: 10,
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 2,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.textColor,
              ),
            ),
          ),
        ),
      ],
    );
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
                : buildFormattedPriceTextField(
                  label:
                      provider.currentProperty?.propertyFor == 'Rent'
                          ? '💵 Asking Price (per month)'
                          : '💵 Asking Price',
                  initialValue: residential.askingPrice ?? '',
                  onChanged: provider.updateAskingPrice,
                ),

            const SizedBox(height: 16),

            if (provider.currentProperty?.propertyFor == 'Rent') ...[
              buildFormattedPriceTextField(
                label: '💰 Security Deposit',
                initialValue: residential.deposit ?? '',
                onChanged: provider.updateDeposit,
              ),
              const SizedBox(height: 16),

              buildFormattedPriceTextField(
                label: '🔧 Maintenance (per month)',
                initialValue: residential.maintenance ?? '',
                onChanged: provider.updateMaintenance,
              ),

              const SizedBox(height: 16),
            ],

            _buildBathroomSection(provider),

            const SizedBox(height: 16),
            _buildFurnishingOptions(provider),
            const SizedBox(height: 16),
            LocationSearchTextField(
              initialValue: "",
              hintText: '📍Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );

                provider.updateLocation(locationData);
              },
            ),

            const SizedBox(height: 16),

            ChipInputField(
              label: '🛠️ Facilities',
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
              label: '👥 Preferences',
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
              '📝 Additional Notes',
              residential.additionalNotes ?? '',
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
          child: _buildTextField(
            'Asking Price',
            residential.askingPrice ?? '',
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
                : buildFormattedPriceTextField(
                  label:
                      provider.currentProperty?.propertyFor == 'Rent'
                          ? '💵 Asking Price (per month)'
                          : '💵 Asking Price',
                  initialValue: commercial.askingPrice ?? '',
                  onChanged: (value) {
                    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                    provider.updateAskingPrice(value);
                  },
                ),

            const SizedBox(height: 16),

            _buildTextField(
              '📏 Square Feet',
              commercial.squareFeet ?? '',
              provider.updateSquareFeet,
            ),

            // _buildTextField("🛠️ Facilities", commercial.facilities ?? '', (
            //   value,
            // ) {
            //   provider.updateCommercialFacilities(value);
            // }),

            //  ChipInputField(
            //         label: '🛠️ Facilities',
            //         selectedItems: commercial.facilities ?? [],
            //         onAdd: (facility) => provider.addCustomFacility(facility),
            //         onRemove: (facility) => provider.toggleFacility(facility),
            //         hintText: 'Add facilities (separate with commas)',
            //       ),
            //       const SizedBox(height: 16),

            //       ChipRow(
            //         options: const [
            //           'Car Parking',
            //           'Security 24x7',
            //           'Gated Society',
            //           'Power Backup',
            //           'Lift',
            //           'Club House',
            //           'Waste Management',
            //           'Gym',
            //         ],
            //         selectedOptions: commercial.facilities ?? [],
            //         onToggle: (facility) => provider.toggleFacility(facility),
            //         onAddNew: (facility) => provider.addCustomFacility(facility),
            //       ),
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

            LocationSearchTextField(
              initialValue: "",
              hintText: '📍 Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );

                provider.updateLocation(locationData);
              },
            ),
            SizedBox(height: 16),

            _buildNumberTextField(
              'No of Washrooms',
              commercial.washrooms ?? '',
              (value) {
                provider.updateWashroomFacilities(value);
              },
            ),
            SizedBox(height: 16),

            _buildCommercialFurnishingOptionsr(),

            SizedBox(height: 16),

            _buildNumberTextField('No of Seats', commercial.noOfSeats ?? '', (
              value,
            ) {
              provider.updateseatFacilities(value);
            }),
            const SizedBox(height: 16),
            _buildTextField(
              '📝 Additional Notes',
              commercial.additionalNotes ?? '',
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
          child: _buildTextField(
            'Asking Price',
            commercial.askingPrice != null && commercial.askingPrice!.isNotEmpty
                ? _formatPrice(commercial.askingPrice!)
                : '',
            (value) {
              String cleanValue = value.replaceAll(RegExp(r'[₹,CLcr\s]'), '');
              provider.updateAskingPrice(cleanValue);
            },
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

  Widget _buildOwnerLandStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        final land = provider.landProperty;
        if (land == null) return Container();

        return SingleChildScrollView(
          child: _buildStepContainer([
            provider.currentProperty?.propertyFor == 'Lease'
                ? _buildPriceFieldCompact(provider)
                : buildFormattedPriceTextField(
                  label:
                      provider.currentProperty?.propertyFor == 'Rent'
                          ? '💵 Asking Price (per month)'
                          : '💵 Asking Price',
                  initialValue: land.askingPrice ?? '',
                  onChanged: (value) {
                    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                    provider.updateAskingPrice(value);
                  },
                ),

            SizedBox(height: 16),

            _buildAreaTextField(provider),

            SizedBox(height: 16),

            LocationSearchTextField(
              initialValue: "",
              hintText: '📍 Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );
                provider.updateLocation(locationData);
              },
            ),
            SizedBox(height: 16),

            _buildTextField(
              '📝 Additional Notes',
              land.additionalNotes ?? '',
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
              child: _buildTextField(
                'Asking Price',
                land.askingPrice ?? '',
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
          land.askingPrice ?? '',
          provider.updateAskingPrice,
        );
  }

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty) {
      return 'N/A';
    }

    final numPrice = int.tryParse(price);
    if (numPrice == null) {
      return price;
    }

    if (numPrice >= 10000000) {
      final crores = numPrice / 10000000;
      if (crores == crores.toInt()) {
        return '₹${crores.toInt()} Cr';
      } else {
        return '₹${crores.toStringAsFixed(1)} Cr';
      }
    } else if (numPrice >= 100000) {
      final lakhs = numPrice / 100000;
      if (lakhs == lakhs.toInt()) {
        return '₹${lakhs.toInt()} L';
      } else {
        return '₹${lakhs.toStringAsFixed(1)} L';
      }
    } else if (numPrice >= 10000) {
      return '₹${_addCommas(numPrice)}';
    } else {
      return '₹$numPrice';
    }
  }

  String _addCommas(int number) {
    String numStr = number.toString();

    if (numStr.length <= 3) {
      return numStr;
    }

    String result = numStr.substring(numStr.length - 3);
    String remaining = numStr.substring(0, numStr.length - 3);

    while (remaining.length > 2) {
      result = remaining.substring(remaining.length - 2) + ',' + result;
      remaining = remaining.substring(0, remaining.length - 2);
    }

    if (remaining.isNotEmpty) {
      result = remaining + ',' + result;
    }

    return result;
  }

  Widget _buildAreaTextField(NewLeadProvider provider) {
    final selectedUnit = provider.selectedAreaUnit ?? 'Square Feet';
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

  Widget _buildSquareFeetField(NewLeadProvider provider, double currentSqft) {
    if (_squareFeetController.text.isEmpty && currentSqft > 0) {
      _squareFeetController.text = _formatNumber(currentSqft);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _squareFeetController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: '📏 Square Feet',
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
    final currentAcres = provider.landProperty?.acres ?? '0';
    final currentCents = provider.landProperty?.cents ?? '0';

    if (_acresController.text.isEmpty && currentAcres != '0') {
      _acresController.text = currentAcres;
    }
    if (_centsController.text.isEmpty && currentCents != '0') {
      _centsController.text = currentCents;
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
              controller: _acresController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                labelText: '📏 Acres',
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
                    _centsController.text.isEmpty ? '0' : _centsController.text;
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
              controller: _centsController,
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
                    _acresController.text.isEmpty ? '0' : _acresController.text;
                provider.updateAcresAndCents(acresValue, centsValue);
              },
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
            value: options.contains(value) ? value : options.first,
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

  String _formatNumber(double number) {
    if (number == number.roundToDouble()) {
      return number.round().toString();
    } else {
      return number.toStringAsFixed(2);
    }
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
                : buildFormattedPriceTextField(
                  label:
                      (provider.currentProperty?.propertyFor == 'Sale' &&
                              provider.leadModel.leadType == 'Buyer')
                          ? 'Budget'
                          : provider.currentProperty?.propertyFor == 'Rent'
                          ? 'Budget (per month)'
                          : 'Budget',
                  initialValue: residential.askingPrice ?? '',
                  onChanged: (value) {
                    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                    provider.updateAskingPrice(value);
                  },
                ),

            SizedBox(height: 16),
            _buildFurnishingOptions(provider),
            SizedBox(height: 16),
            LocationSearchTextField(
              initialValue: "",
              hintText: 'Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );

                provider.updateLocation(locationData);
              },
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
            SizedBox(height: 25),

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

            SizedBox(height: 16),
            _buildTextField(
              'Additional Requirements',
              residential.additionalNotes ?? '',
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

  Widget _buildTenantCommercialStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        final commercial = provider.commercialProperty;
        if (commercial == null) return Container();

        return SingleChildScrollView(
          child: _buildStepContainer([
            provider.currentProperty?.propertyFor == 'Lease'
                ? _buildBudgetFieldCompactCommercial(provider)
                : buildFormattedPriceTextField(
                  label:
                      (provider.currentProperty?.propertyFor == 'Sale' &&
                              provider.leadModel.leadType == 'Buyer')
                          ? 'Budget'
                          : provider.currentProperty?.propertyFor == 'Rent'
                          ? 'Budget (per month)'
                          : 'Budget',
                  initialValue: commercial.askingPrice ?? '',
                  onChanged: (value) {
                    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                    provider.updateAskingPrice(value);
                  },
                ),

            SizedBox(height: 16),
            _buildTextField(
              'Sq Ft',
              commercial.squareFeet ?? '',
              provider.updateSquareFeet,
            ),
            SizedBox(height: 16),

            LocationSearchTextField(
              initialValue: "",
              hintText: 'Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );

                provider.updateLocation(locationData);
              },
            ),
            SizedBox(height: 16),

            _buildNumberTextField(
              'No of Washrooms',
              commercial.washrooms ?? '',
              (value) {
                provider.updateWashroomFacilities(value);
              },
            ),
            SizedBox(height: 16),

            _buildCommercialFurnishingOptionsr(),

            SizedBox(height: 16),

            _buildNumberTextField('No of Seats', commercial.noOfSeats ?? '', (
              value,
            ) {
              provider.updateseatFacilities(value);
            }),
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
            _buildTextField(
              'Additional Notes',
              commercial.additionalNotes ?? '',
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

  Widget _buildTenantLandStep(BuildContext context) {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        final land = provider.landProperty;
        if (land == null) return Container();

        return SingleChildScrollView(
          child: _buildStepContainer([
            provider.currentProperty?.propertyFor == 'Lease'
                ? _buildBudgetFieldCompactLand(provider)
                : buildFormattedPriceTextField(
                  label:
                      provider.currentProperty?.propertyFor == 'Rent'
                          ? 'Budget (per month)'
                          : 'Budget',
                  initialValue: land.askingPrice ?? '',
                  onChanged: (value) {
                    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                    provider.updateAskingPrice(value);
                  },
                ),

            SizedBox(height: 16),

            _buildAreaTextField(provider),

            SizedBox(height: 16),

            LocationSearchTextField(
              initialValue: "",
              hintText: 'Search for your location...',
              onLocationSelected: (locationMap) {
                final locationData = LocationData(
                  address: locationMap['address'] ?? '',
                  latitude: locationMap['latitude'] ?? 0.0,
                  longitude: locationMap['longitude'] ?? 0.0,
                );
                provider.updateLocation(locationData);
              },
            ),
            SizedBox(height: 16),

            _buildTextField(
              'Additional Requirements',
              land.additionalNotes ?? '',
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
          child: _buildTextField(
            'Budget',
            land.askingPrice ?? '',
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

  Widget _buildBudgetFieldCompactResidential(NewLeadProvider provider) {
    final residential = provider.residentialProperty;
    if (residential == null) return Container();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTextField(
            'Budget',
            residential.askingPrice ?? '',
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

  Widget _buildBudgetFieldCompactCommercial(NewLeadProvider provider) {
    final commercial = provider.commercialProperty;
    if (commercial == null) return Container();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTextField(
            'Budget',
            commercial.askingPrice ?? '',
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

  Widget _buildTextField(
    String label,
    String value,
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
                residential?.bathroomAttached ?? '',
                provider.updateBathroomAttached,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBathroomTextField(
                'Common',
                residential?.bathroomCommon ?? '',
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
    String value,
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
        initialValue: value,
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

  Widget _buildNumberTextField(
    String label,
    String value,
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
          child: TextFormField(
            initialValue: value,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            maxLines: maxLines,
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

  Widget _buildNumberTextFieldPhone(
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

  Widget _buildCommercialFurnishingOptionsr() {
    return Consumer<NewLeadProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomSquareRadioOption(
                    text: "Furnished",
                    isSelected:
                        provider.commercialProperty?.furnished == "Furnished",
                    size: 22,
                    onTap:
                        () => provider.updateCommercialFurnishingType(
                          "Furnished",
                        ),
                  ),
                ),
                Expanded(
                  child: CustomSquareRadioOption(
                    text: "Unfurnished",
                    isSelected:
                        provider.commercialProperty?.furnished == "Unfurnished",
                    size: 22,
                    onTap:
                        () => provider.updateCommercialFurnishingType(
                          "Unfurnished",
                        ),
                  ),
                ),
                Expanded(
                  child: CustomSquareRadioOption(
                    text: "Semi-Furnished",
                    isSelected:
                        provider.commercialProperty?.furnished ==
                        "Semi-Furnished",
                    size: 22,
                    onTap:
                        () => provider.updateCommercialFurnishingType(
                          "Semi-Furnished",
                        ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
            SizedBox(width: 10),

            _buildPropertySubOption(
              'House/Villa',
              provider.selectedSubType == 'House/Villa',
              () => provider.selectPropertySubType('House/Villa'),
            ),

            SizedBox(width: 10),

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

          await provider.saveLead(context);
          _clearAllFields();
          Navigator.pop(context, true);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lead created successfully!'),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
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
    if (provider.leadModel.name?.isEmpty ?? true) {
      return 'Name is required';
    }

    if (provider.leadModel.phoneNumber?.isEmpty ?? true) {
      return 'Phone number is required';
    }

    if (provider.leadModel.whatsappNumber?.isEmpty ?? true) {
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
    if (residential.askingPrice?.isEmpty ?? true) {
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

    if (residential.location?.isEmpty ?? true) {
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
    if (commercial.askingPrice?.isEmpty ?? true) {
      String label =
          provider.leadModel.leadType == 'Owner' ? 'Asking price' : 'Budget';
      return '$label is required';
    }

    // Square feet validation
    if (commercial.squareFeet?.isEmpty ?? true) {
      return 'Square feet is required';
    }

    // Washrooms validation
    if (commercial.washrooms?.isEmpty ?? true) {
      return 'Number of washrooms is required';
    }

    // Furnishing validation
    if (commercial.furnished?.isEmpty ?? true) {
      return 'Furnishing type is required';
    }

    // Number of seats validation
    if (commercial.noOfSeats?.isEmpty ?? true) {
      return 'Number of seats is required';
    }
    if (commercial.location?.isEmpty ?? true) {
      return 'Location is required';
    }

    return null;
  }

  String? _validateLandProperty(NewLeadProvider provider) {
    final land = provider.landProperty;

    if (land == null) {
      return 'Land property details are required';
    }

    // Price/Budget validation
    if (land.askingPrice?.isEmpty ?? true) {
      String label =
          provider.leadModel.leadType == 'Owner' ? 'Asking price' : 'Budget';
      return '$label is required';
    }

    // Area validation
    final selectedUnit = provider.selectedAreaUnit ?? 'Square Feet';
    if (selectedUnit == 'Square Feet') {
      if (land.squareFeet?.isEmpty ?? true) {
        return 'Square feet is required';
      }
    } else if (selectedUnit == 'Acre & Cent') {
      if ((land.acres?.isEmpty ?? true) && (land.cents?.isEmpty ?? true)) {
        return 'Acres or cents is required';
      }
    }

    // Location validation
    if (land.location?.isEmpty ?? true) {
      return 'Location is required';
    }

    return null;
  }
}
