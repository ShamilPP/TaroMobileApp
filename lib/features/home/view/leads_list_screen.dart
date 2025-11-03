import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/controller/lead_controller.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:url_launcher/url_launcher.dart';

class LeadsListScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final Function(bool)? onSelectionModeChanged;

  const LeadsListScreen({
    Key? key,
    this.onProfileTap,
    this.onSelectionModeChanged,
  }) : super(key: key);

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadProvider>().fetchLeads();
    });
  }

  int _getFilterCount(LeadProvider provider, String filter) {
    if (filter == 'All') return provider.leads.length;
    return provider.leads.where((lead) => lead.leadType == filter).length;
  }

  List<LeadModel> _getFilteredLeads(LeadProvider provider) {
    if (selectedFilter == 'All') return provider.leads;
    return provider.leads.where((lead) => lead.leadType == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeadProvider>(
      builder: (context, leadProvider, child) {
        final filteredLeads = _getFilteredLeads(leadProvider);

        return Container(
          color: Color(0xFFF5F5F5),
          child: Column(
            children: [
              _buildHeader(leadProvider),
              Expanded(
                child: leadProvider.isLoading
                    ? Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                    : filteredLeads.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                                SizedBox(height: 16),
                                Text(
                                  'No leads found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600], fontFamily: 'Lato'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
                            itemCount: filteredLeads.length,
                            itemBuilder: (context, index) {
                              return _buildLeadCard(filteredLeads[index]);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(LeadProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leads',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Lato',
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your client relationships',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'Lato',
                ),
              ),
              SizedBox(height: 20),
              _buildFilterTabs(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(LeadProvider provider) {
    final filters = ['All', 'Owner', 'Buyer', 'Tenant'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final count = _getFilterCount(provider, filter);
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filter),
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$filter ($count)',
                style: TextStyle(
                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeadCard(LeadModel lead) {
    Color borderColor = lead.leadType == 'Owner' ? AppColors.primaryGreen : Color(0xFF3B82F6);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: borderColor, width: 3),
          left: BorderSide(color: borderColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: borderColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Name and Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Lato',
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        lead.leadType,
                        style: TextStyle(
                          fontSize: 14,
                          color: borderColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lead.status,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // Actions
                _buildActionButton(Icons.message, () => _launchWhatsApp(lead)),
                SizedBox(width: 8),
                _buildActionButton(Icons.phone, () => _makePhoneCall(lead)),
              ],
            ),

            // Properties Section
            SizedBox(height: 16),
            Text(
              'Properties (3)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontFamily: 'Lato',
              ),
            ),
            SizedBox(height: 12),

            // Property Cards (Static for now - will integrate with real data)
            _buildPropertyCard(
              bhk: '4 BHK',
              type: 'Unfurnished',
              status: 'Available',
              location: 'Perambra',
              transactionType: 'Rent',
              price: '₹20,000/m',
            ),
            SizedBox(height: 8),
            _buildPropertyCard(
              bhk: '4 BHK',
              type: 'Unfurnished',
              status: 'Available',
              location: 'Perambra',
              transactionType: 'Rent',
              price: '₹20,000/m',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard({
    required String bhk,
    required String type,
    required String status,
    required String location,
    required String transactionType,
    required String price,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          // BHK Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '4',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ),
          SizedBox(width: 12),

          // Property Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bhk,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: 'Lato',
                      ),
                    ),
                    Text(' · ', style: TextStyle(color: Colors.grey[400])),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontFamily: 'Lato',
                      ),
                    ),
                    Text(' · ', style: TextStyle(color: Colors.grey[400])),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.red[400]),
                    SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Lato',
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        transactionType,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price
          Text(
            price,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.grey[700]),
      ),
    );
  }

  void _launchWhatsApp(LeadModel lead) async {
    String phoneNumber = lead.whatsappNumber ?? lead.phoneNumber;
    if (phoneNumber.isEmpty) return;

    if (!phoneNumber.startsWith('+91')) {
      phoneNumber = '+91$phoneNumber';
    }

    final cleanNumber = phoneNumber.replaceAll('+', '').replaceAll(RegExp(r'[^\d]'), '');
    final url = 'https://wa.me/$cleanNumber';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
    }
  }

  void _makePhoneCall(LeadModel lead) async {
    final phoneNumber = lead.phoneNumber;
    if (phoneNumber.isEmpty) return;

    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = 'tel:$cleanNumber';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Error making phone call: $e');
    }
  }
}

