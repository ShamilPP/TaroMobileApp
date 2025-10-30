import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/constants/image_constants.dart';
import 'package:taro_mobile/features/home/controller/lead_controller.dart';
import 'package:taro_mobile/features/home/view/lead_details_screen.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:taro_mobile/features/reminder/new_reminder_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailsDisplayScreen extends StatefulWidget {
  final LeadModel lead;

  const PropertyDetailsDisplayScreen({super.key, required this.lead});

  @override
  State<PropertyDetailsDisplayScreen> createState() =>
      _PropertyDetailsDisplayScreenState();
}

class _PropertyDetailsDisplayScreenState
    extends State<PropertyDetailsDisplayScreen> {
  List<BaseProperty> leadProperties = [];
  bool isLoadingProperties = false;
  final NumberFormat _indianFormat = NumberFormat.decimalPattern('en_IN');

  @override
  void initState() {
    super.initState();
    _loadLeadProperties();
  }

  void _loadLeadProperties() {
    setState(() {
      isLoadingProperties = true;
    });

    final leadController = Provider.of<LeadProvider>(context, listen: false);
    leadController.getPropertiesForLead(widget.lead.id ?? '').listen((
      properties,
    ) {
      setState(() {
        leadProperties = properties;
        isLoadingProperties = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Column(
                  children: [
                    _buildScreenshotHeader(),
                    _buildLeadDetailsSection(),
                    _buildMainPropertyCard(),
                  ],
                ),
              ),
            ),
            // Loading or content section
            if (isLoadingProperties)
              SliverFillRemaining(
                child: Container(
                  color: Colors.white,
                  child: Center(child: _buildElegantLoader()),
                ),
              )
            else ...[
              SliverToBoxAdapter(child: _buildPropertyFeaturesSection()),
              SliverToBoxAdapter(child: _buildPropertySection()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          // Back button matching screenshot
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              // color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildElegantLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A2332)),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'loading property details...',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildNeumorphicReminderButton() {
    return InkWell(
      onTap: () {
        // Prepare property details string
        String propertyDetails = '';
        if (leadProperties.isNotEmpty) {
          var property = leadProperties.first;
          if (property is ResidentialProperty) {
            propertyDetails =
                '${property.selectedBHK ?? ''} ${property.propertySubType ?? ''} - ${property.location ?? ''}';
          } else if (property is CommercialProperty) {
            propertyDetails =
                '${property.propertySubType ?? ''} - ${property.squareFeet ?? ''} Sq.Ft - ${property.location ?? ''}';
          } else if (property is LandProperty) {
            propertyDetails =
                '${property.propertySubType ?? ''} - ${property.squareFeet ?? property.acres ?? ''} - ${property.location ?? ''}';
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => NewReminderScreen(
                  prefilledName: widget.lead.name,
                  prefilledLeadId: widget.lead.id,
                  prefilledPropertyDetails: propertyDetails,
                  prefilledLocationDetails: '',
                  leadProperties: leadProperties,
                ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm_add_outlined, color: Colors.white, size: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadDetailsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Text(
            'Edit Lead',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 5),

          _buildNeumorphicEditButton(),

          const Spacer(),
          Text(
            'Add Reminder',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 5),

          _buildNeumorphicReminderButton(),
        ],
      ),
    );
  }

  Widget _buildNeumorphicEditButton() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => LeadDetailsScreen(
                    existingLead: widget.lead,
                    isEditMode: true,
                  ),
            ),
          ).then((result) {
            if (result == true) {
              _loadLeadProperties();
            }
          });
        },
        borderRadius: BorderRadius.circular(15),
        child: const Center(
          child: Icon(Icons.edit_outlined, color: Colors.white, size: 15),
        ),
      ),
    );
  }

  String getInitials(String name) {
    List<String> names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.length == 1 && names[0].isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'UC';
  }

  Widget _buildLeadHeader(
    BuildContext context,
    String leadName,
    String phone,
    String leadCategory,
    Color? avatarColor,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final avatarSize = isSmallScreen ? 50.0 : 55.0;

    return Container(
      child: InkWell(
        onTap: () {
          // Add any lead profile tap functionality here
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            // bottom: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: avatarColor,
                  child: Text(
                    getInitials(leadName),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      leadName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.lead.leadType}${widget.lead.leadType.isNotEmpty && leadCategory.isNotEmpty ? ', ' : ''}$leadCategory',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainPropertyCard() {
    String leadName = widget.lead.name ?? 'Unknown Client';
    String phone = widget.lead.phoneNumber ?? '+91-98XXXXXXXX';
    String whatsApp = widget.lead.whatsappNumber ?? '+91-98XXXXXXXX';
    String leadType = widget.lead.leadType ?? 'Unknown';
    String leadCategory = widget.lead.leadCategory ?? 'Not specified';

    return Container(
      margin: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Main card content
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upper section with white background
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeadHeader(
                        context,
                        leadName,
                        phone,
                        leadCategory,
                        widget.lead.avatarColor,
                      ),
                      const SizedBox(height: 12),

                      // Row(
                      //   children: [
                      //     const SizedBox(width: 15),
                      //     if (leadCategory.isNotEmpty &&
                      //         leadCategory != 'Not specified') ...[
                      //       Text(
                      //         'Lead Category: $leadCategory',
                      //         style: GoogleFonts.inter(
                      //           fontSize: 10,
                      //           fontWeight: FontWeight.w400,
                      //           color: Colors.black87,
                      //         ),
                      //       ),
                      //     ],
                      //   ],
                      // ),
                    ],
                  ),
                ),

                // Divider
                Container(height: 1, color: Colors.grey[300]),

                // Lower section with light grey background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100], // Light grey background
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildNeumorphicIcon(
                              AppImages.whatsappIcon,
                              () => _launchWhatsApp(
                                widget.lead,
                              ), // Pass the lead object
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "+91 $whatsApp",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 60,
                        width: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _buildNeumorphicIcon(
                              AppImages.callIcon,
                              () => _makePhoneCall(
                                widget.lead,
                              ), // Pass the lead object
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "+91 $phone",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status badge positioned at top-right edge
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                Text(
                  "Status: ",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                _buildNeumorphicStatusBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyFeaturesSection() {
    if (leadProperties.isEmpty) {
      return Container(
        color: Colors.grey[50],
        padding: const EdgeInsets.all(24),
        child: _buildDefaultFeatures(),
      );
    }

    var property = leadProperties.first;

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (property is CommercialProperty)
            _buildCommercialFeatures(property)
          else if (property is ResidentialProperty)
            _buildResidentialFeatures(property)
          else if (property is LandProperty)
            _buildLandFeatures(property)
          else
            _buildDefaultFeatures(),
        ],
      ),
    );
  }

  void _launchWhatsApp(LeadModel lead) async {
    String phoneNumber = lead.whatsappNumber!.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Add +91 if missing
    if (!phoneNumber.startsWith('+91')) {
      phoneNumber = '+91$phoneNumber';
    }

    // WhatsApp URL requires digits only (remove +)
    final cleanNumber = phoneNumber
        .replaceAll('+', '')
        .replaceAll(RegExp(r'[^\d]'), '');
    final url = 'https://wa.me/$cleanNumber';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching WhatsApp: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _makePhoneCall(LeadModel lead) async {
    final phoneNumber = lead.phoneNumber;

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Clean phone number (remove spaces, dashes, etc.)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = 'tel:$cleanNumber';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making phone call: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildNeumorphicIcon(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: AppColors.taroGrey,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textColor, width: 0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(4, 4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildCommercialFeatures(CommercialProperty property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.lead.leadType == 'Tenant'
                  ? "Property Needed"
                  : 'Property Details',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            // _buildNeumorphicPropertyEditButton(),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildFeatureItem(
                Icons.chair,
                property.noOfSeats != null ? '${property.noOfSeats} seats' : '',
                property.noOfSeats != null ? '' : '',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureItem(
                Icons.weekend_outlined,
                property.furnished ?? 'Unfurnished',
                '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: _buildFeatureItem(
                Icons.wc_outlined,
                property.washrooms != null
                    ? '${property.washrooms} Washrooms'
                    : '2 Washrooms',
                '',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureItem(
                Icons.location_on_outlined,
                (property.location ?? 'Main Road')
                    .replaceAll(',', '')
                    .split(' ')
                    .take(2)
                    .join(' '),
                '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResidentialFeatures(ResidentialProperty property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.lead.leadType == 'Tenant'
                  ? "Property Needed"
                  : 'Property Details',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Conditional layout based on bathroom details
        _getBathroomDetails(property) == null
            ? Row(
              children: [
                Expanded(
                  child: _buildFeatureItem(
                    Icons.home_outlined,
                    property.selectedBHK ?? 'BHK',
                    '',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildFeatureItem(
                    Icons.weekend_outlined,
                    _getFurnishingStatus(property) ?? 'Unfurnished',
                    '',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildFeatureItem(
                    Icons.location_on_outlined,
                    (property.location ?? 'Main Road')
                        .split(' ')
                        .take(2)
                        .join(' '),
                    '',
                  ),
                ),
              ],
            )
            : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureItem(
                        Icons.home_outlined,
                        property.selectedBHK ?? 'BHK',
                        '',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildFeatureItem(
                        Icons.weekend_outlined,
                        _getFurnishingStatus(property) ?? 'Unfurnished',
                        '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureItem(
                        Icons.wc_outlined,
                        _getBathroomDetails(property) ?? 'Bathrooms',
                        '',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildFeatureItem(
                        Icons.location_on_outlined,
                        (property.location ?? 'Main Road')
                            .split(' ')
                            .take(2)
                            .join(' '),
                        '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
      ],
    );
  }

  Widget _buildLandFeatures(LandProperty property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.lead.leadType == 'Tenant'
                  ? "Property Needed"
                  : 'Property Details',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildFeatureItem(
                Icons.landscape_outlined,
                (property.squareFeet != null &&
                        property.squareFeet != "0" &&
                        property.squareFeet!.isNotEmpty)
                    ? '${property.squareFeet} Sq.Ft'
                    : (property.acres != null && property.cents != null)
                    ? '${property.acres} Acres and ${property.cents} Cents'
                    : (property.acres != null)
                    ? '${property.acres} Acres'
                    : (property.cents != null)
                    ? '${property.cents} Cents'
                    : '',
                '',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureItem(
                Icons.location_on_outlined,
                (property.location ?? 'Main Road').split(' ').take(2).join(' '),
                '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultFeatures() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFeatureItem(
                Icons.straighten,
                '1700 sqft Covered Area',
                'Suitable for 17-25',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureItem(
                Icons.weekend_outlined,
                'Unfurnished',
                '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: _buildFeatureItem(Icons.wc_outlined, '2 Washrooms', ''),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureItem(
                Icons.location_on_outlined,
                'Main Road',
                '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.grey[600], size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          overflow: TextOverflow.ellipsis,

          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,

          textAlign: TextAlign.center,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildPropertySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [],
          ),
        ),
        const SizedBox(height: 20),
        if (leadProperties.isEmpty)
          _buildNeumorphicEmptyState()
        else
          // Use neumorphic cards for each property
          ...leadProperties.asMap().entries.map((entry) {
            int index = entry.key;
            BaseProperty property = entry.value;

            if (property is ResidentialProperty) {
              return _buildNeumorphicPropertyCard(
                property: property,
                type: 'Residential',
                icon: Icons.home_outlined,
                color: AppColors.primaryDarkBlue,
                index: index,
              );
            } else if (property is CommercialProperty) {
              return _buildNeumorphicCommercialCard(
                property: property,
                type: 'Commercial',
                icon: Icons.business_outlined,
                color: AppColors.primaryDarkBlue,
                index: index,
              );
            } else if (property is LandProperty) {
              return _buildNeumorphicLandCard(
                property: property,
                type: 'Land',
                icon: Icons.landscape_outlined,
                color: AppColors.primaryDarkBlue,
                index: index,
              );
            }
            return Container();
          }).toList(),
      ],
    );
  }

  Widget _buildNeumorphicPropertyEditButton() {
    return NeumorphicButton(
      style: NeumorphicStyle(
        shape: NeumorphicShape.flat,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
        depth: 4,
        lightSource: LightSource.topLeft,
        color: AppColors.primaryDarkBlue.withOpacity(0.1),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => LeadDetailsScreen(
                  existingLead: widget.lead,
                  isEditMode: true,
                ),
          ),
        ).then((result) {
          if (result == true) {
            _loadLeadProperties();
          }
        });
      },
      child: Container(
        width: 20,
        height: 20,
        child: const Center(
          child: Icon(
            Icons.edit_outlined,
            color: AppColors.primaryDarkBlue,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicEmptyState() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Neumorphic(
        style: NeumorphicStyle(
          shape: NeumorphicShape.flat,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
          depth: 8,
          lightSource: LightSource.topLeft,
          color: AppColors.taroGrey,
        ),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                Neumorphic(
                  style: NeumorphicStyle(
                    shape: NeumorphicShape.concave,
                    boxShape: NeumorphicBoxShape.roundRect(
                      BorderRadius.circular(20),
                    ),
                    depth: 4,
                    lightSource: LightSource.topLeft,
                    color: AppColors.taroGrey,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    child: const Center(
                      child: Icon(
                        Icons.home_outlined,
                        size: 40,
                        color: AppColors.primaryDarkBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Properties Listed',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Property details will be displayed here once available',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: AppColors.primaryDarkBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Updated _buildNeumorphicPropertyCard method for Residential Properties
  Widget _buildNeumorphicPropertyCard({
    required ResidentialProperty property,
    required String type,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(24, index == 0 ? 0 : 16, 24, 0),
      child: Neumorphic(
        style: NeumorphicStyle(
          shape: NeumorphicShape.flat,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
          depth: 6,
          lightSource: LightSource.topLeft,
          color: AppColors.taroGrey,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNeumorphicPropertyHeader(
              type: type,
              subType: property.propertySubType ?? 'N/A',
              icon: icon,
              color: color,
              price: property.askingPrice,
              propertyFor: property.propertyFor,
              leaseDuration: property.leadDuration,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Asking Price
                  if (property.askingPrice != null &&
                      property.askingPrice!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow(
                      widget.lead.leadType == 'Tenant'
                          ? 'Budget'
                          : 'Asking Price',
                      _getAskingPriceDisplay(
                        property.askingPrice,
                        property.propertyFor,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (property.selectedBHK != null) ...[
                    _buildNeumorphicPropertyRow('BHK', property.selectedBHK!),
                    const SizedBox(height: 16),
                  ],
                  if (_getFurnishingStatus(property) != null) ...[
                    _buildNeumorphicPropertyRow(
                      'Furnished',
                      _getFurnishingStatus(property)!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (property.location != null &&
                      property.location!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow('Location', property.location!),
                    const SizedBox(height: 16),
                  ],
                  if (_getBathroomDetails(property) != null) ...[
                    _buildNeumorphicPropertyRow(
                      'Bathrooms',
                      _getBathroomBreakdown(property)!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 16),

                  if (property.maintenance != null &&
                      property.maintenance!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow(
                      'Maintenance',
                      '₹${_formatPrice(property.maintenance!)}${_isRentProperty(property.propertyFor) ? '' : ''} /month',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (property.deposit != null &&
                      property.deposit!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow(
                      'Security Deposit',
                      '₹${_formatPrice(property.deposit!)}',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (property.vegOrNonVeg != null &&
                      property.vegOrNonVeg!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow(
                      'Veg Or Non-Veg',
                      '${property.vegOrNonVeg!}',
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (property.workingProfessional != null &&
                      property.workingProfessional!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow(
                      'Working Professionals',
                      '${property.workingProfessional!}',
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (property.facilities != null &&
                      property.facilities!.isNotEmpty)
                    _buildNeumorphicFacilitiesRow(property.facilities!),
                  if (property.preferences != null &&
                      property.preferences!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNeumorphicPreferencesRow(property.preferences!),
                  ],

                  if (property.status != null &&
                      property.status!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNeumorphicPropertyRow(
                      'Status',
                      '${property.status!}',
                    ),
                  ],
                  if (property.additionalNotes != null &&
                      property.additionalNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNeumorphicPropertyRow(
                      'Additional Notes',
                      property.additionalNotes!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated _buildNeumorphicCommercialCard method
  Widget _buildNeumorphicCommercialCard({
    required CommercialProperty property,
    required String type,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(24, index == 0 ? 0 : 16, 24, 0),
      child: Neumorphic(
        style: NeumorphicStyle(
          shape: NeumorphicShape.flat,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
          depth: 6,
          lightSource: LightSource.topLeft,
          color: AppColors.taroGrey,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNeumorphicPropertyHeader(
              type: type,
              subType: property.propertySubType ?? 'N/A',
              icon: icon,
              color: color,
              price: property.askingPrice,
              propertyFor: property.propertyFor,
              leaseDuration: property.leadDuration,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Asking Price
                  if (property.askingPrice != null &&
                      property.askingPrice!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow(
                      widget.lead.leadType == 'Tenant'
                          ? 'Budget'
                          : 'Asking Price',
                      _getAskingPriceDisplay(
                        property.askingPrice,
                        property.propertyFor,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (property.squareFeet != null) ...[
                    _buildNeumorphicPropertyRow(
                      'Area',
                      '${property.squareFeet} Sq.Ft',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (property.noOfSeats != null) ...[
                    _buildNeumorphicPropertyRow(
                      'Seating Capacity',
                      '${property.noOfSeats} seats',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (property.furnished != null) ...[
                    _buildNeumorphicPropertyRow(
                      'Furnished',
                      property.furnished!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (property.location != null &&
                      property.location!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow('Location', property.location!),
                    const SizedBox(height: 16),
                  ],
                  if (property.washrooms != null) ...[
                    _buildNeumorphicPropertyRow(
                      'Washrooms',
                      '${property.washrooms}',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (property.status != null &&
                      property.status!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNeumorphicPropertyRow(
                      'Status',
                      '${property.status!}',
                    ),
                  ],
                  if (property.additionalNotes != null &&
                      property.additionalNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNeumorphicPropertyRow(
                      'Additional Notes',
                      property.additionalNotes!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated _buildNeumorphicLandCard method
  Widget _buildNeumorphicLandCard({
    required LandProperty property,
    required String type,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(24, index == 0 ? 0 : 16, 24, 0),
      child: Neumorphic(
        style: NeumorphicStyle(
          shape: NeumorphicShape.flat,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
          depth: 6,
          lightSource: LightSource.topLeft,
          color: AppColors.taroGrey,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNeumorphicPropertyHeader(
              type: type,
              subType: property.propertySubType ?? 'N/A',
              icon: icon,
              color: color,
              price: property.askingPrice,
              propertyFor: property.propertyFor,
              leaseDuration: property.leadDuration,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Asking Price
                  if (property.askingPrice != null &&
                      property.askingPrice!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow(
                      widget.lead.leadType == 'Tenant'
                          ? 'Budget'
                          : 'Asking Price',
                      _getAskingPriceDisplay(
                        property.askingPrice,
                        property.propertyFor,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (property.squareFeet != '0') ...[
                    _buildNeumorphicPropertyRow(
                      'Area (Sq.Ft)',
                      '${property.squareFeet}',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (property.acres != null) ...[
                    _buildNeumorphicPropertyRow(
                      'Area (Acres)',
                      '${property.acres}',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (property.location != null &&
                      property.location!.isNotEmpty) ...[
                    _buildNeumorphicPropertyRow('Location', property.location!),
                    const SizedBox(height: 16),
                  ],
           
                  if (property.additionalNotes != null &&
                      property.additionalNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNeumorphicPropertyRow(
                      'Additional Notes',
                      property.additionalNotes!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for displaying asking price and askingPrice
  String _getAskingPriceDisplay(String? askingPrice, String? propertyFor) {
    if (askingPrice == null || askingPrice.isEmpty) {
      return 'Not specified';
    }

    String formattedPrice = '₹${_formatPrice(askingPrice)}';

    if (propertyFor != null) {
      if (propertyFor.toLowerCase().contains('rent')) {
        formattedPrice += '/month';
      } else if (propertyFor.toLowerCase().contains('lease')) {
        formattedPrice += '/lease';
      }
      // For sale, no suffix needed
    }

    return formattedPrice;
  }

  String _getaskingPriceDisplay(String? askingPrice, String? propertyFor) {
    if (askingPrice == null || askingPrice.isEmpty) {
      return 'Not specified';
    }

    String formattedaskingPrice = '₹${_formatPrice(askingPrice)}';

    if (propertyFor != null) {
      if (propertyFor.toLowerCase().contains('rent')) {
        formattedaskingPrice += '/month';
      } else if (propertyFor.toLowerCase().contains('lease')) {
        formattedaskingPrice += '/lease';
      }
      // For sale, no suffix needed
    }

    return formattedaskingPrice;
  }

  Widget _buildNeumorphicPropertyHeader({
    required String type,
    required String subType,
    required IconData icon,
    required Color color,
    String? price,
    String? propertyFor,
    String? leaseDuration,
  }) {
    return Neumorphic(
      style: NeumorphicStyle(
        shape: NeumorphicShape.concave,
        boxShape: NeumorphicBoxShape.roundRect(
          BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        depth: 2,
        lightSource: LightSource.topLeft,
        color: AppColors.primaryGreen,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppColors.primaryGreen,
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subType,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (price != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatPrice(price)}${_isRentProperty(propertyFor) ? '/month' : ''}${propertyFor == 'Lease' ? ' ${leaseDuration ?? ''}' : ''}',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (propertyFor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      propertyFor,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Widget _buildNeumorphicCommercialCard({
  //   required CommercialProperty property,
  //   required String type,
  //   required IconData icon,
  //   required Color color,
  //   required int index,
  // }) {
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(24, index == 0 ? 0 : 16, 24, 0),
  //     child: Neumorphic(
  //       style: NeumorphicStyle(
  //         shape: NeumorphicShape.flat,
  //         boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
  //         depth: 6,
  //         lightSource: LightSource.topLeft,
  //         color: AppColors.taroGrey,
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           _buildNeumorphicPropertyHeader(
  //             type: type,
  //             subType: property.propertySubType ?? 'N/A',
  //             icon: icon,
  //             color: color,
  //             price: property.askingPrice,
  //             propertyFor: property.propertyFor,
  //             leaseDuration: property.leadDuration,
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.all(24),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (property.squareFeet != null) ...[
  //                   _buildNeumorphicPropertyRow(
  //                     'Area',
  //                     '${property.squareFeet} Sq.Ft',
  //                   ),
  //                   const SizedBox(height: 16),
  //                 ],
  //                 if (property.noOfSeats != null) ...[
  //                   _buildNeumorphicPropertyRow(
  //                     'Seating Capacity',
  //                     '${property.noOfSeats} seats',
  //                   ),
  //                   const SizedBox(height: 16),
  //                 ],
  //                 if (property.furnished != null) ...[
  //                   _buildNeumorphicPropertyRow(
  //                     'Furnished',
  //                     property.furnished!,
  //                   ),
  //                   const SizedBox(height: 16),
  //                 ],
  //                 if (property.location != null &&
  //                     property.location!.isNotEmpty) ...[
  //                   _buildNeumorphicPropertyRow('Location', property.location!),
  //                   const SizedBox(height: 16),
  //                 ],
  //                 if (property.washrooms != null) ...[
  //                   _buildNeumorphicPropertyRow(
  //                     'Washrooms',
  //                     '${property.washrooms}',
  //                   ),
  //                   const SizedBox(height: 16),
  //                 ],
  //                 if (property.additionalNotes != null &&
  //                     property.additionalNotes!.isNotEmpty) ...[
  //                   const SizedBox(height: 16),
  //                   _buildNeumorphicPropertyRow(
  //                     'Additional Notes',
  //                     property.additionalNotes!,
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildNeumorphicLandCard({
  //   required LandProperty property,
  //   required String type,
  //   required IconData icon,
  //   required Color color,
  //   required int index,
  // }) {
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(24, index == 0 ? 0 : 16, 24, 0),
  //     child: Neumorphic(
  //       style: NeumorphicStyle(
  //         shape: NeumorphicShape.flat,
  //         boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
  //         depth: 6,
  //         lightSource: LightSource.topLeft,
  //         color: AppColors.taroGrey,
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           _buildNeumorphicPropertyHeader(
  //             type: type,
  //             subType: property.propertySubType ?? 'N/A',
  //             icon: icon,
  //             color: color,
  //             price: property.askingPrice,
  //             propertyFor: property.propertyFor,
  //             leaseDuration: property.leadDuration,
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.all(24),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (property.squareFeet != '0') ...[
  //                   _buildNeumorphicPropertyRow(
  //                     'Area (Sq.Ft)',
  //                     '${property.squareFeet}',
  //                   ),
  //                   const SizedBox(height: 16),
  //                 ],
  //                 if (property.acres != null) ...[
  //                   _buildNeumorphicPropertyRow(
  //                     'Area (Acres)',
  //                     '${property.acres}',
  //                   ),
  //                   const SizedBox(height: 16),
  //                 ],
  //                 if (property.location != null &&
  //                     property.location!.isNotEmpty) ...[
  //                   _buildNeumorphicPropertyRow('Location', property.location!),
  //                   const SizedBox(height: 16),
  //                 ],
  //                 if (property.additionalNotes != null &&
  //                     property.additionalNotes!.isNotEmpty) ...[
  //                   const SizedBox(height: 16),
  //                   _buildNeumorphicPropertyRow(
  //                     'Additional Notes',
  //                     property.additionalNotes!,
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildNeumorphicPropertyRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with fixed width, left-aligned
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.left, // Left align the label
          ),
        ),
        // Colon in its own column
        SizedBox(
          width: 20,
          child: Text(
            ':',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
        ),
        // Value takes remaining space
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDarkBlue,
            ),
          ),
        ),
      ],
    );
  }

  // Replace the existing _buildNeumorphicFacilitiesRow method with this:
  Widget _buildNeumorphicFacilitiesRow(List<String> facilities) {
    return _buildNeumorphicPropertyRow('Facilities', facilities.join(', '));
  }

  // Replace the existing _buildNeumorphicPreferencesRow method with this:
  Widget _buildNeumorphicPreferencesRow(List<String> preferences) {
    return _buildNeumorphicPropertyRow('Preferences', preferences.join(', '));
  }

  Widget _buildNeumorphicStatusBadge() {
    final status = widget.lead.status ?? 'New Lead';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF7E64B8), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // const SizedBox(width: 8),
          Text(
            status,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String? _getFurnishingStatus(ResidentialProperty property) {
    // if (property.furnished == true) return 'Furnished';
    // if (property.semiFurnished == true) return 'Semi-Furnished';
    // if (property.unFurnished == true) return 'Unfurnished';
    return null;
  }

  String? _getBathroomDetails(ResidentialProperty property) {
    int totalBathrooms = 0;

    // Add attached bathrooms if available
    if (property.bathroomAttached != null &&
        property.bathroomAttached!.isNotEmpty) {
      totalBathrooms += int.tryParse(property.bathroomAttached!) ?? 0;
    }

    // Add common bathrooms if available
    if (property.bathroomCommon != null &&
        property.bathroomCommon!.isNotEmpty) {
      totalBathrooms += int.tryParse(property.bathroomCommon!) ?? 0;
    }

    // Return formatted string if we have bathroom count
    if (totalBathrooms > 0) {
      return '$totalBathrooms Bathroom${totalBathrooms > 1 ? 's' : ''}';
    }

    return null;
  }

  String? _getBathroomBreakdown(ResidentialProperty property) {
    List<String> bathroomDetails = [];

    // Add attached bathrooms if available
    if (property.bathroomAttached != null &&
        property.bathroomAttached!.isNotEmpty) {
      int attached = int.tryParse(property.bathroomAttached!) ?? 0;
      if (attached > 0) {
        bathroomDetails.add('$attached Attached');
      }
    }

    // Add common bathrooms if available
    if (property.bathroomCommon != null &&
        property.bathroomCommon!.isNotEmpty) {
      int common = int.tryParse(property.bathroomCommon!) ?? 0;
      if (common > 0) {
        bathroomDetails.add('$common Common');
      }
    }

    // Return formatted string if we have bathroom details
    if (bathroomDetails.isNotEmpty) {
      return bathroomDetails.join(', ');
    }

    return null;
  }

  String _formatPrice(String price) {
    try {
      double priceValue = double.parse(price.replaceAll(',', ''));
      return _indianFormat.format(priceValue);
    } catch (e) {
      return price;
    }
  }

  // Helper method to check if property is for rent
  bool _isRentProperty(String? propertyFor) {
    if (propertyFor == null) return false;
    return propertyFor.toLowerCase().contains('rent');
  }
}
