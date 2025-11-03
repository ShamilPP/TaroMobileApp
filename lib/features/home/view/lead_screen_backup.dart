import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/constants/image_constants.dart';
import 'package:taro_mobile/features/home/controller/filter_state.dart';
import 'package:taro_mobile/features/home/controller/lead_controller.dart';
import 'package:taro_mobile/features/home/view/lead_details_screen.dart';
import 'package:taro_mobile/features/home/view/property_details_screen.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:taro_mobile/features/reminder/new_reminder_screen.dart';
import 'package:taro_mobile/core/widgets/filter_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class LeadsView extends StatefulWidget {
  final VoidCallback? onProfileTap; // Add this parameter
  final Function(bool)? onSelectionModeChanged; // Add this callback

  const LeadsView({
    Key? key,
    this.onProfileTap,
    this.onSelectionModeChanged, // Add this parameter
  }) : super(key: key);
  @override
  State<LeadsView> createState() => _LeadsViewState();
}

class _LeadsViewState extends State<LeadsView> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  // User data variables
  String firstName = 'Loading...';
  String lastName = 'Loading...';
  String userEmail = 'Loading...';
  String userInitials = ''; // UNIFIED FILTER STATE - Replace LeadFilterState with UnifiedFilterState
  UnifiedFilterState filterState = UnifiedFilterState();

  // Controllers for price inputs
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Text style for property details
  final TextStyle propertyTextStyle = TextStyle(fontSize: 13, color: Colors.grey[700], fontFamily: 'Lato');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadProvider>().fetchLeads();
      _loadUserData();
    });

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void didPopNext() {
    context.read<LeadProvider>().fetchLeads();
    super.didPopNext();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;

  int _getClosedDealsCount(LeadProvider leadProvider) {
    return leadProvider.leads.where((lead) => lead.status == 'Closed').length;
  }

  Future<void> _loadUserData() async {
    try {
      if (currentUser != null) {
        // First try to get user data from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser!.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            firstName = userData['firstName'] ?? 'User';
            lastName = userData['lastName'] ?? 'User';
            userEmail = userData['email'] ?? currentUser!.email ?? 'No email';
            userInitials = _getInitials('$firstName $lastName');
          });
        } else {
          // If no user document exists, try to get from Firebase Auth
          setState(() {
            firstName = currentUser!.displayName ?? 'User';
            userEmail = currentUser!.email ?? 'No email';
            userInitials = _getInitials(firstName);
          });

          // Create user document if it doesn't exist
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Fallback to Firebase Auth data
      if (currentUser != null) {
        setState(() {
          firstName = currentUser!.displayName ?? 'User';
          userEmail = currentUser!.email ?? 'No email';
          userInitials = _getInitials(firstName);
        });
      }
    }
  }

  // Generate initials from name
  String _getInitials(String name) {
    if (name.isEmpty || name == 'Loading...') return '';

    List<String> names = name.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    } else {
      return '${names[0].substring(0, 1)}${names[names.length - 1].substring(0, 1)}'.toUpperCase();
    }
  }

  void _enterSelectionMode(String leadId) {
    setState(() {
      isSelectionMode = true;
      selectedLeadIds.add(leadId);
    });

    // Notify parent about selection mode change
    widget.onSelectionModeChanged?.call(true);

    HapticFeedback.selectionClick();
    _showSelectionSnackBar();
  }

  void _toggleLeadSelection(String leadId) {
    setState(() {
      if (selectedLeadIds.contains(leadId)) {
        selectedLeadIds.remove(leadId);
      } else {
        selectedLeadIds.add(leadId);
      }

      if (selectedLeadIds.isEmpty) {
        isSelectionMode = false;
        // Notify parent when exiting selection mode
        widget.onSelectionModeChanged?.call(false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });

    if (selectedLeadIds.isNotEmpty) {
      _showSelectionSnackBar();
    }

    HapticFeedback.selectionClick();
  }

  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedLeadIds.clear();
    });

    // Notify parent about selection mode change
    widget.onSelectionModeChanged?.call(false);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  bool _hasActiveFilters() {
    return (filterState.selectedPropertyType != 'All' && filterState.selectedPropertyType.isNotEmpty) ||
        (filterState.selectedBHK != 'All' && filterState.selectedBHK.isNotEmpty) ||
        (filterState.selectedFurnishingStatus != 'All' && filterState.selectedFurnishingStatus.isNotEmpty) ||
        filterState.selectedStatuses.isNotEmpty ||
        filterState.selectedLocations.isNotEmpty ||
        filterState.selectedSubtypes.isNotEmpty ||
        filterState.selectedBudgetRanges.isNotEmpty ||
        filterState.selectedTenantPreferences.isNotEmpty ||
        filterState.minPrice.isNotEmpty ||
        filterState.maxPrice.isNotEmpty ||
        (filterState.useSliderBudget &&
            (filterState.minBudgetSlider > _getMinSliderValue(filterState.selectedPropertyFor) ||
                filterState.maxBudgetSlider < _getMaxSliderValue(filterState.selectedPropertyFor)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeadProvider>(
      builder: (context, leadProvider, child) {
        return Container(
          color: Color(0xFFF5F5F5),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildDashboardHeader(context, leadProvider), _buildTodayScheduleSection(context), const SizedBox(height: 80)],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardHeader(BuildContext context, LeadProvider leadProvider) {
    // Get greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    // Format date
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d');
    final dateString = dateFormat.format(now);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting and analytics icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, ${firstName.isNotEmpty ? firstName : 'Sharma'} ✨',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lato'),
                    ),
                    SizedBox(height: 2),
                    Text(dateString, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85), fontFamily: 'Lato')),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.trending_up, color: Colors.white, size: 22),
                ),
              ],
            ),

            SizedBox(height: 14),

            // Stats cards grid
            Row(
              children: [
                Expanded(child: _buildDashboardStatCard(icon: Icons.people, iconColor: Color(0xFF2DD4BF), value: '24', label: 'Active Leads')),
                SizedBox(width: 10),
                Expanded(child: _buildDashboardStatCard(icon: Icons.apartment, iconColor: Color(0xFF3B82F6), value: '18', label: 'Active Listings')),
              ],
            ),

            SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildDashboardStatCard(
                    icon: Icons.motion_photos_on,
                    iconColor: Color(0xFFF59E0B),
                    value: '5',
                    label: 'Deals Closed',
                    subtitle: '+2 this week',
                    subtitleColor: Color(0xFF2DD4BF),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildDashboardStatCard(
                    icon: Icons.calendar_today,
                    iconColor: Color(0xFFEC4899),
                    value: '12',
                    label: 'Upcoming Tasks',
                    subtitle: 'Next 7 days',
                    subtitleColor: Color(0xFF2DD4BF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStatCard({required IconData icon, required Color iconColor, required String value, required String label, String? subtitle, Color? subtitleColor}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Lato')),
          SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'Lato')),
          if (subtitle != null) ...[
            SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.trending_up, color: subtitleColor ?? Colors.green, size: 12),
                SizedBox(width: 3),
                Text(subtitle, style: TextStyle(fontSize: 10, color: subtitleColor ?? Colors.green, fontWeight: FontWeight.w600, fontFamily: 'Lato')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 18, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Schedule", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Lato')),
              Text('4 tasks', style: TextStyle(fontSize: 14, color: Color(0xFF2DD4BF), fontWeight: FontWeight.w600, fontFamily: 'Lato')),
            ],
          ),

          SizedBox(height: 14),

          // Task items
          _buildTaskItem(title: 'Site visit with Mr. Sharma', time: '10:30 AM', category: 'Site Visit', isCompleted: false),

          _buildTaskItem(title: 'Agreement signing - Villa project', time: '2:00 PM', category: 'Signing', isCompleted: false),

          _buildTaskItem(title: 'Follow-up call with Mrs. Patel', time: '4:30 PM', category: 'Call', isCompleted: true),

          _buildTaskItem(title: 'Property inspection - Malad East', time: '6:00 PM', category: 'Inspection', isCompleted: false),

          SizedBox(height: 16),

          // View All Tasks button
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to tasks screen
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('View All Tasks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Lato')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({required String title, required String time, required String category, required bool isCompleted}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Checkmark icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: isCompleted ? Colors.grey[300] : AppColors.primaryGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.check, color: isCompleted ? Colors.grey[500] : AppColors.primaryGreen, size: 22),
          ),

          SizedBox(width: 14),

          // Task details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.grey[400] : Colors.black87,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    fontFamily: 'Lato',
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Text(time, style: TextStyle(fontSize: 13, color: isCompleted ? Colors.grey[400] : Colors.grey[600], fontFamily: 'Lato')),
                    Text('  •  ', style: TextStyle(color: isCompleted ? Colors.grey[400] : Colors.grey[400])),
                    Text(category, style: TextStyle(fontSize: 13, color: isCompleted ? Colors.grey[400] : Colors.grey[600], fontFamily: 'Lato')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, LeadProvider leadProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen, // Green background
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile section
            GestureDetector(
              onTap: widget.onProfileTap,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Color(0xFF14A76C), shape: BoxShape.circle),
                    child: Center(child: Text(userInitials.isNotEmpty ? userInitials : 'CJ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                  ),
                  const SizedBox(width: 16),
                  Text('$firstName $lastName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Stats cards section
            Consumer<LeadProvider>(
              builder: (context, leadProvider, child) {
                final activeLeads = leadProvider.leads.where((lead) => lead.status != 'Archived' && lead.status != 'Lost').length;

                final now = DateTime.now();
                final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1)); // Monday
                final weekEnd = weekStart.add(Duration(days: 7)); // Next Monday

                final thisWeekLeads =
                    leadProvider.leads.where((lead) {
                      if (lead.createdAt == null) return false;

                      final createdAt = (lead.createdAt is Timestamp) ? (lead.createdAt as Timestamp).toDate() : lead.createdAt;

                      return createdAt.isAfter(weekStart) && createdAt.isBefore(weekEnd);
                    }).length;

                final totalLeads = leadProvider.leads.length;

                return Row(
                  children: [
                    Expanded(child: _buildStatCard(value: activeLeads.toString(), label: 'Active Leads')),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard(value: thisWeekLeads.toString(), label: 'This week')),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard(value: totalLeads.toString(), label: 'Total')),
                  ],
                );
              },
            ),
            SizedBox(height: 15),

            _buildHeaderWithSearch(leadProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String value, required String label}) {
    return Container(
      margin: EdgeInsets.all(8), // Prevent clipping of outer shadow
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0x4DFFFFFF), // 30% white
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12), // Use dark shadow for contrast
            blurRadius: 12,
            spreadRadius: 2,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildHeaderWithSearch(LeadProvider leadProvider) {
    return Container(
      color: AppColors.primaryGreen, // Same green background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: _buildSearchField(leadProvider)), const SizedBox(width: 12), _buildFilterIcon()]),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 0),
            child: Row(
              children: [
                const Text('Leads', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white, fontFamily: 'Lato')),
                Spacer(),
                GestureDetector(
                  onTap: () => _downloadLeadsAsCSV(leadProvider),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Download', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, fontFamily: 'Lato')),
                      const SizedBox(width: 8),

                      Icon(Icons.download, color: Colors.white, size: 13),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildActiveFilterChips(),
        ],
      ),
    );
  }

  // Updated build method section - replace the SliverToBoxAdapter content

  Widget _buildAchievementContainer(int totalLeads) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.taroGrey, AppColors.taroGrey]),
          borderRadius: BorderRadius.circular(20),
          // border: Border.all(color: const Color(0xFFE0E6ED), width: 1),
          boxShadow: [BoxShadow(color: AppColors.taroGrey, blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Stack(
          children: [
            // Confetti decorations
            Positioned(
              top: 10,
              left: 20,
              child: Transform.rotate(angle: 0.3, child: Container(width: 8, height: 3, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2)))),
            ),
            Positioned(top: 25, left: 50, child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
            Positioned(
              top: 15,
              right: 30,
              child: Transform.rotate(angle: -0.5, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle))),
            ),
            Positioned(
              top: 30,
              right: 60,
              child: Transform.rotate(angle: 0.8, child: Container(width: 10, height: 2, decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(1)))),
            ),
            Positioned(
              bottom: 20,
              left: 40,
              child: Transform.rotate(angle: -0.3, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle))),
            ),
            Positioned(
              bottom: 15,
              right: 45,
              child: Transform.rotate(angle: 0.6, child: Container(width: 8, height: 3, decoration: BoxDecoration(color: Colors.cyan, borderRadius: BorderRadius.circular(2)))),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trophy icon
                  const Text("🏆", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),

                  // Main achievement text with dynamic count
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2E5984), height: 1.2),
                      children: [
                        const TextSpan(text: "You've crushed "),
                        TextSpan(
                          text: "$totalLeads deals", // Dynamic count
                          style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w800),
                        ),
                        const TextSpan(text: " this month!"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Closing deals like it's a sport ", style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      Text("🥇", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Add this method to your _LeadsViewState class

  Widget _buildActiveFilterChips() {
    List<Widget> filterChips = [];

    // Lead Type filter
    if (filterState.selectedLeadType != 'All' && filterState.selectedLeadType.isNotEmpty) {
      filterChips.add(
        _buildFilterChip(
          label: filterState.selectedLeadType,
          onRemove: () {
            setState(() {
              filterState.selectedLeadType = 'All';
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Property For filter
    if (filterState.selectedPropertyFor != 'All' && filterState.selectedPropertyFor.isNotEmpty) {
      filterChips.add(
        _buildFilterChip(
          label: filterState.selectedPropertyFor,
          onRemove: () {
            setState(() {
              filterState.selectedPropertyFor = 'All';
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Property Type filter
    if (filterState.selectedPropertyType != 'All' && filterState.selectedPropertyType.isNotEmpty) {
      filterChips.add(
        _buildFilterChip(
          label: filterState.selectedPropertyType,
          onRemove: () {
            setState(() {
              filterState.selectedPropertyType = 'All';
            });
            _refreshFilters();
          },
        ),
      );
    }

    // BHK filter
    if (filterState.selectedBHK != 'All' && filterState.selectedBHK.isNotEmpty) {
      filterChips.add(
        _buildFilterChip(
          label: '${filterState.selectedBHK} ',
          onRemove: () {
            setState(() {
              filterState.selectedBHK = 'All';
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Furnishing Status filter
    if (filterState.selectedFurnishingStatus != 'All' && filterState.selectedFurnishingStatus.isNotEmpty) {
      filterChips.add(
        _buildFilterChip(
          label: filterState.selectedFurnishingStatus,
          onRemove: () {
            setState(() {
              filterState.selectedFurnishingStatus = 'All';
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Status filters
    for (String status in filterState.selectedStatuses) {
      filterChips.add(
        _buildFilterChip(
          label: status,
          onRemove: () {
            setState(() {
              filterState.selectedStatuses.remove(status);
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Location filters
    for (String location in filterState.selectedLocations) {
      filterChips.add(
        _buildFilterChip(
          label: location,
          onRemove: () {
            setState(() {
              filterState.selectedLocations.remove(location);
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Property Subtype filters
    for (String subtype in filterState.selectedSubtypes) {
      filterChips.add(
        _buildFilterChip(
          label: subtype,
          onRemove: () {
            setState(() {
              filterState.selectedSubtypes.remove(subtype);
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Budget Range filters
    for (String budgetRange in filterState.selectedBudgetRanges) {
      filterChips.add(
        _buildFilterChip(
          label: budgetRange,
          onRemove: () {
            setState(() {
              filterState.selectedBudgetRanges.remove(budgetRange);
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Tenant Preferences filters
    for (String preference in filterState.selectedTenantPreferences) {
      filterChips.add(
        _buildFilterChip(
          label: preference,
          onRemove: () {
            setState(() {
              filterState.selectedTenantPreferences.remove(preference);
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Price Range filter
    if (filterState.minPrice.isNotEmpty || filterState.maxPrice.isNotEmpty) {
      String priceLabel = '';
      if (filterState.minPrice.isNotEmpty && filterState.maxPrice.isNotEmpty) {
        priceLabel = '${_formatPriceForChip(filterState.minPrice)} - ${_formatPriceForChip(filterState.maxPrice)}';
      } else if (filterState.minPrice.isNotEmpty) {
        priceLabel = 'Min: ₹${_formatPriceForChip(filterState.minPrice)}';
      } else {
        priceLabel = 'Max: ₹${_formatPriceForChip(filterState.maxPrice)}';
      }

      filterChips.add(
        _buildFilterChip(
          label: priceLabel,
          onRemove: () {
            setState(() {
              filterState.minPrice = '';
              filterState.maxPrice = '';
            });
            _refreshFilters();
          },
        ),
      );
    }

    // Budget Slider filter
    // if (filterState.useSliderBudget &&
    //     (filterState.minBudgetSlider >
    //             _getMinSliderValue(filterState.selectedPropertyFor) ||
    //         filterState.maxBudgetSlider <
    //             _getMaxSliderValue(filterState.selectedPropertyFor))) {
    //   String sliderLabel =
    //       '₹${_formatSliderValue(filterState.minBudgetSlider)} - ₹${_formatSliderValue(filterState.maxBudgetSlider)}';
    //   filterChips.add(
    //     _buildFilterChip(
    //       label: sliderLabel,
    //       onRemove: () {
    //         setState(() {
    //           filterState.minBudgetSlider = _getMinSliderValue(
    //             filterState.selectedPropertyFor,
    //           );
    //           filterState.maxBudgetSlider = _getMaxSliderValue(
    //             filterState.selectedPropertyFor,
    //           );
    //         });
    //         _refreshFilters();
    //       },
    //     ),
    //   );
    // }

    // Add "Clear All" chip if there are multiple filters
    if (filterChips.length > 1) {
      filterChips.insert(0, _buildClearAllChip());
    }

    if (filterChips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 6, children: filterChips)]),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1)),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
              child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryGreen)),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                margin: const EdgeInsets.only(left: 4, right: 6, top: 3),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.close, size: 14, color: AppColors.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearAllChip() {
    return GestureDetector(
      onTap: _clearAllFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.5), width: 1)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear_all, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  // Helper method to clear all filters
  void _clearAllFilters() {
    setState(() {
      filterState.selectedLeadType = 'All';
      filterState.selectedPropertyFor = 'All';
      filterState.selectedPropertyType = 'All';
      filterState.selectedBHK = 'All';
      filterState.selectedFurnishingStatus = 'All';
      filterState.selectedStatuses.clear();
      filterState.selectedLocations.clear();
      filterState.selectedSubtypes.clear();
      filterState.selectedBudgetRanges.clear();
      filterState.selectedTenantPreferences.clear();
      filterState.minPrice = '';
      filterState.maxPrice = '';
      filterState.minBudgetSlider = _getMinSliderValue('All');
      filterState.maxBudgetSlider = _getMaxSliderValue('All');
      filterState.useSliderBudget = false;
      filterState.selectedTransactionType = 'All';
    });
    _refreshFilters();
  }

  // Helper method to refresh filters
  void _refreshFilters() {
    final leadProvider = context.read<LeadProvider>();
    _applyFiltersToProvider(filterState, leadProvider);
  }

  // Helper method to format price for chips
  String _formatPriceForChip(String price) {
    if (price.isEmpty) return '';

    final numPrice = int.tryParse(price.replaceAll(',', ''));
    if (numPrice == null) return price;

    if (numPrice >= 10000000) {
      final crores = numPrice / 10000000;
      return crores == crores.toInt() ? '${crores.toInt()}Cr' : '${crores.toStringAsFixed(1)}Cr';
    } else if (numPrice >= 100000) {
      final lakhs = numPrice / 100000;
      return lakhs == lakhs.toInt() ? '${lakhs.toInt()}L' : '${lakhs.toStringAsFixed(1)}L';
    } else if (numPrice >= 1000) {
      return '${(numPrice / 1000).toStringAsFixed(0)}K';
    }
    return price;
  }

  // Helper method to format slider values for chips
  String _formatSliderValue(double value) {
    if (value >= 1) {
      return value == value.toInt() ? '${value.toInt()}L' : '${value.toStringAsFixed(1)}L';
    } else {
      return '${(value * 100000).toStringAsFixed(0)}';
    }
  }

  Future<void> _downloadLeadsAsCSV(LeadProvider leadProvider) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(content: Row(children: const [CircularProgressIndicator(), SizedBox(width: 20), Text('Preparing CSV...')]));
        },
      );

      List<LeadModel> leads = leadProvider.leads;

      if (leads.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No leads data to export'), behavior: SnackBarBehavior.floating));
        return;
      }

      String csvContent = await _generateCSVContent(leads);
      print("DEBUG: CSV Content generated, length: ${csvContent.length}");

      final fileName = 'leads_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';

      if (Platform.isAndroid) {
        await _saveFileAndroid15Compatible(csvContent, fileName, leads.length);
      } else {
        await _saveFileIOS(csvContent, fileName, leads.length);
      }

      Navigator.of(context).pop(); // Close dialog
    } catch (e) {
      print("DEBUG: Error in _downloadLeadsAsCSV: $e");
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating CSV: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _saveFileAndroid15Compatible(String csvContent, String fileName, int leadCount) async {
    print("DEBUG: Starting Android 15 compatible file save process");

    try {
      // Method 1: Use SAF (Storage Access Framework) - Most reliable for Android 15
      if (await _trySAFDownload(csvContent, fileName, leadCount)) {
        return;
      }

      // Method 2: Save to app documents and share
      print("DEBUG: Fallback to app documents + share");
      final appDocDir = await getApplicationDocumentsDirectory();
      final appDocFile = File('${appDocDir.path}/$fileName');
      await appDocFile.writeAsString(csvContent, encoding: utf8);

      print("DEBUG: Successfully saved to app documents: ${appDocFile.path}");

      // Always share the file since direct downloads access is restricted
      await _shareFile(appDocFile.path, fileName, leadCount);
    } catch (e) {
      print("DEBUG: All methods failed: $e");
      throw e;
    }
  }

  Future<bool> _trySAFDownload(String csvContent, String fileName, int leadCount) async {
    try {
      print("DEBUG: Attempting SAF download");

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csvContent, encoding: utf8);

      // Use SAF to save to Downloads
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV file',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: await tempFile.readAsBytes(),
      );

      if (result != null) {
        print("DEBUG: SAF save successful: $result");
        _showSuccessMessage("File saved to Downloads folder", leadCount);

        // Clean up temp file
        await tempFile.delete();
        return true;
      }

      print("DEBUG: SAF save cancelled by user");
      return false;
    } catch (e) {
      print("DEBUG: SAF save failed: $e");
      return false;
    }
  }

  // Alternative approach using MediaStore for Android 15+
  Future<bool> _tryMediaStoreDownload(String csvContent, String fileName, int leadCount) async {
    try {
      print("DEBUG: Attempting MediaStore download");

      // This requires adding platform-specific code or using a plugin
      // For now, we'll use the file_picker approach above

      return false;
    } catch (e) {
      print("DEBUG: MediaStore save failed: $e");
      return false;
    }
  }

  // Updated permission request for Android 15

  Future<void> _shareFile(String filePath, String fileName, int leadCount) async {
    try {
      print("DEBUG: Sharing file: $filePath");
      await Share.shareXFiles([XFile(filePath)], text: 'Leads Export CSV - $leadCount leads exported', subject: 'Leads Export');
      _showSuccessMessage("File ready to save - choose your preferred location", leadCount);
    } catch (e) {
      print("DEBUG: Share failed: $e");
      _showFileLocationDialog(fileName, leadCount);
    }
  }

  void _showSuccessMessage(String message, int leadCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Expanded(child: Text(message))]),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _saveFileIOS(String csvContent, String fileName, int leadCount) async {
    print("DEBUG: Starting iOS file save process");

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvContent, encoding: utf8);

      await Share.shareXFiles([XFile(file.path)], text: 'Leads Export CSV - $leadCount leads exported', subject: 'Leads Export');

      _showSuccessMessage("File saved and shared", leadCount);
    } catch (e) {
      print("DEBUG: iOS save failed: $e");
      throw e;
    }
  }

  void _showFileLocationDialog(String fileName, int leadCount) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(children: [Icon(Icons.info, color: Colors.blue), SizedBox(width: 8), Text('CSV Created')]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your CSV file has been created successfully!'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('File: $fileName', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(height: 4),
                      Text('Total leads: $leadCount', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      SizedBox(height: 4),
                      Text('Location: App\'s private storage', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text('The file is saved in the app\'s private storage. You can share it using the button below.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    final directory = await getApplicationDocumentsDirectory();
                    final file = File('${directory.path}/$fileName');
                    await Share.shareXFiles([XFile(file.path)]);
                  } catch (e) {
                    print("DEBUG: Share button failed: $e");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to share file: $e'), behavior: SnackBarBehavior.floating));
                  }
                },
                child: Text('Share'),
              ),
            ],
          ),
    );
  }

  // Helper method to generate CSV content (same as before)
  Future<String> _generateCSVContent(List<LeadModel> leads) async {
    List<String> csvRows = [];

    // CSV Headers - Added Transaction Type and Amount as separate columns
    csvRows.add(
      [
        'Name',
        'Lead Type',
        'Lead Category',
        'Phone Number',
        'WhatsApp Number',
        'Status',
        'Location',
        'Transaction Type', // New field for propertyFor
        'Amount', // New field for askingPrice

        'Property Details',
      ].map((header) => '"$header"').join(','),
    );

    // Process each lead
    for (LeadModel lead in leads) {
      // Get property details and locations for this lead
      Map<String, dynamic> propertyInfo = await _getPropertyInfoForCSV(lead.id ?? '');

      String propertyDetails = propertyInfo['details'] ?? '';
      String locations = propertyInfo['locations'] ?? '';
      String transactionTypes = propertyInfo['transactionTypes'] ?? '';
      String amounts = propertyInfo['amounts'] ?? '';
      int propertyCount = propertyInfo['count'] ?? 0;

      // Format dates
      String createdDate = lead.createdAt?.toString().split(' ')[0] ?? 'N/A';

      // Create CSV row with separate transaction type and amount columns
      List<String> row = [
        lead.name,
        lead.leadType,
        lead.leadCategory,
        lead.phoneNumber,
        lead.whatsappNumber ?? '',
        lead.status,
        locations,
        transactionTypes, // Separate transaction type field
        amounts, // Separate amount field

        propertyDetails, // Property details without transaction type and amount
      ];

      // Escape and add quotes to each field
      String csvRow = row.map((field) => '"${field.replaceAll('"', '""')}"').join(',');
      csvRows.add(csvRow);
    }

    return csvRows.join('\n');
  }

  // Updated helper method to return property details, locations, transaction types, and amounts separately
  Future<Map<String, dynamic>> _getPropertyInfoForCSV(String leadId) async {
    if (leadId.isEmpty) return {'details': '', 'locations': '', 'transactionTypes': '', 'amounts': '', 'count': 0};

    try {
      List<String> propertyDetails = [];
      List<String> locations = [];
      List<String> transactionTypes = [];
      List<String> amounts = [];
      int totalCount = 0;

      // Get Residential Properties
      QuerySnapshot residentialSnapshot =
          await FirebaseFirestore.instance.collection('Residential').where('leadId', isEqualTo: leadId).where('status', isNotEqualTo: 'Inactive').get();

      for (QueryDocumentSnapshot doc in residentialSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        ResidentialProperty property = ResidentialProperty.fromMap(data, doc.id);

        // Property details without location, transaction type, and amount
        String details = ['Residential', property.selectedBHK ?? '', property.propertySubType ?? ''].where((detail) => detail.isNotEmpty).join(' | ');

        if (details.isNotEmpty) propertyDetails.add(details);

        // Add location separately
        if (property.location != null && property.location!.isNotEmpty) {
          locations.add(property.location!);
        }

        // Add transaction type separately
        if (property.propertyFor != null && property.propertyFor!.isNotEmpty) {
          transactionTypes.add(property.propertyFor!);
        }

        // Add amount separately
        if (property.askingPrice != null && property.askingPrice!.isNotEmpty) {
          amounts.add(property.askingPrice!);
        }
      }
      totalCount += residentialSnapshot.docs.length;

      // Get Commercial Properties
      QuerySnapshot commercialSnapshot =
          await FirebaseFirestore.instance.collection('Commercial').where('leadId', isEqualTo: leadId).where('status', isNotEqualTo: 'Inactive').get();

      for (QueryDocumentSnapshot doc in commercialSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        CommercialProperty property = CommercialProperty.fromMap(data, doc.id);

        // Property details without location, transaction type, and amount
        String details = ['Commercial', property.propertySubType ?? ''].where((detail) => detail.isNotEmpty).join(' | ');

        if (details.isNotEmpty) propertyDetails.add(details);

        // Add location separately
        if (property.location != null && property.location!.isNotEmpty) {
          locations.add(property.location!);
        }

        // Add transaction type separately
        if (property.propertyFor != null && property.propertyFor!.isNotEmpty) {
          transactionTypes.add(property.propertyFor!);
        }

        // Add amount separately
        if (property.askingPrice != null && property.askingPrice!.isNotEmpty) {
          amounts.add(property.askingPrice!);
        }
      }
      totalCount += commercialSnapshot.docs.length;

      // Get Plot Properties
      QuerySnapshot plotSnapshot = await FirebaseFirestore.instance.collection('Plots').where('leadId', isEqualTo: leadId).where('status', isNotEqualTo: 'Inactive').get();

      for (QueryDocumentSnapshot doc in plotSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        LandProperty property = LandProperty.fromMap(data, doc.id);

        // Property details without location, transaction type, and amount
        String details = ['Plot', property.propertySubType ?? ''].where((detail) => detail.isNotEmpty).join(' | ');

        if (details.isNotEmpty) propertyDetails.add(details);

        // Add location separately
        if (property.location != null && property.location!.isNotEmpty) {
          locations.add(property.location!);
        }

        // Add transaction type separately
        if (property.propertyFor != null && property.propertyFor!.isNotEmpty) {
          transactionTypes.add(property.propertyFor!);
        }

        // Add amount separately
        if (property.askingPrice != null && property.askingPrice!.isNotEmpty) {
          amounts.add(property.askingPrice!);
        }
      }
      totalCount += plotSnapshot.docs.length;

      // Remove duplicates and join them
      Set<String> uniqueLocations = locations.toSet();
      Set<String> uniqueTransactionTypes = transactionTypes.toSet();
      Set<String> uniqueAmounts = amounts.toSet();

      return {
        'details': propertyDetails.join('; '),
        'locations': uniqueLocations.join('; '),
        'transactionTypes': uniqueTransactionTypes.join('; '),
        'amounts': uniqueAmounts.join('; '),
        'count': totalCount,
      };
    } catch (e) {
      print('Error fetching property info for CSV: $e');
      return {
        'details': 'Error loading properties',
        'locations': 'Error loading locations',
        'transactionTypes': 'Error loading transaction types',
        'amounts': 'Error loading amounts',
        'count': 0,
      };
    }
  }

  // Keep the property count method for backward compatibility if needed elsewhere

  // Helper method to get property count (same as before)
  Future<int> _getPropertyCount(String leadId) async {
    if (leadId.isEmpty) return 0;

    try {
      int count = 0;

      // Count Residential Properties
      QuerySnapshot residentialSnapshot =
          await FirebaseFirestore.instance.collection('Residential').where('leadId', isEqualTo: leadId).where('status', isNotEqualTo: 'Inactive').get();
      count += residentialSnapshot.docs.length;

      // Count Commercial Properties
      QuerySnapshot commercialSnapshot =
          await FirebaseFirestore.instance.collection('Commercial').where('leadId', isEqualTo: leadId).where('status', isNotEqualTo: 'Inactive').get();
      count += commercialSnapshot.docs.length;

      // Count Plot Properties
      QuerySnapshot plotSnapshot = await FirebaseFirestore.instance.collection('Plots').where('leadId', isEqualTo: leadId).where('status', isNotEqualTo: 'Inactive').get();
      count += plotSnapshot.docs.length;

      return count;
    } catch (e) {
      print('Error counting properties: $e');
      return 0;
    }
  }

  // New method to build CSV download button
  Widget _buildCSVDownloadButton(LeadProvider leadProvider) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => _downloadLeadsAsCSV(leadProvider),
            child: Row(
              children: [
                const Text('Export', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textColor, fontFamily: 'Lato')),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.textColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))],
                  ),
                  child: const Icon(Icons.download, color: Colors.white, size: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterIcon() {
    int activeFilterCount = _getActiveFilterCount();

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showFilterBottomSheet(context),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))],
            ),
            child: const Icon(Icons.tune, color: Colors.black, size: 18),
          ),
        ),
        // if (activeFilterCount > 0)
        //   Positioned(
        //     right: 0,
        //     top: 0,
        //     child: Container(
        //       padding: EdgeInsets.all(2),
        //       decoration: BoxDecoration(
        //         color: Colors.red,
        //         borderRadius: BorderRadius.circular(8),
        //       ),
        //       constraints: BoxConstraints(minWidth: 16, minHeight: 16),
        //       child: Text(
        //         '$activeFilterCount',
        //         style: TextStyle(
        //           color: Colors.white,
        //           fontSize: 10,
        //           fontWeight: FontWeight.bold,
        //         ),
        //         textAlign: TextAlign.center,
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  // Helper method to count active filters
  // int _getActiveFilterCount() {
  //   int count = 0;

  //   if (filterState.selectedLeadType != 'All') count++;
  //   if (filterState.selectedPropertyFor != 'All') count++;
  //   if (filterState.selectedPropertyType != 'All') count++;
  //   if (filterState.selectedStatuses.isNotEmpty) count++;
  //   if (filterState.selectedLocations.isNotEmpty) count++;
  //   if (filterState.minPrice.isNotEmpty || filterState.maxPrice.isNotEmpty)
  //     count++;

  //   return count;
  // }

  Widget _buildSearchField(LeadProvider leadProvider) {
    return Container(
      // Removed horizontal margin as it's now handled by parent spacing
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: _isSearchFocused ? -2 : 2,
          intensity: 0.6,
          color: AppColors.taroGrey,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
          shadowDarkColor: Colors.grey.shade400,
          shadowLightColor: Colors.white,
        ),
        child: Container(
          height: 48, // Slightly reduced for better proportion
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: _isSearchFocused ? Border.all(color: AppColors.textColor.withOpacity(0.3), width: 1) : null),
          child: Row(
            children: [
              Icon(Icons.search, color: _isSearchFocused ? AppColors.textColor : Colors.grey.shade500, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) {
                    // Add debouncing if needed
                    leadProvider.searchLeads(value);
                  },
                  style: const TextStyle(fontSize: 14, color: AppColors.textColor, fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    hintText: 'Search leads by name, location...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w400),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    leadProvider.searchLeads('');
                    _searchFocusNode.unfocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllTypeFilters() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: Alignment.topLeft,
      child: Container(
        width: 180, // Increased width to accommodate three buttons
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: AppColors.taroGrey,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0xFFDBDFE4), offset: Offset(2, 2), blurRadius: 3, spreadRadius: 0.5),
            BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 3, spreadRadius: 0.5),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCategoryButtonWithDoubleClick(
              'Owner',
              isActive: filterState.selectedLeadType == 'Owner',
              onTap: () {
                setState(() {
                  if (filterState.selectedLeadType == 'Owner') {
                    // Double-click: deselect
                    filterState.selectedLeadType = 'All'; // or empty string ''
                  } else {
                    filterState.selectedLeadType = 'Owner';
                  }
                });
              },
            ),
            _buildCategoryButtonWithDoubleClick(
              'Tenant',
              isActive: filterState.selectedLeadType == 'Tenant',
              onTap: () {
                setState(() {
                  if (filterState.selectedLeadType == 'Tenant') {
                    // Double-click: deselect
                    filterState.selectedLeadType = 'All'; // or empty string ''
                  } else {
                    filterState.selectedLeadType = 'Tenant';
                  }
                });
              },
            ),
            _buildCategoryButtonWithDoubleClick(
              'Buyer',
              isActive: filterState.selectedLeadType == 'Buyer',
              onTap: () {
                setState(() {
                  if (filterState.selectedLeadType == 'Buyer') {
                    // Double-click: deselect
                    filterState.selectedLeadType = 'All'; // or empty string ''
                  } else {
                    filterState.selectedLeadType = 'Buyer';
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyForFilters() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: Alignment.topLeft,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: AppColors.taroGrey,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0xFFDBDFE4), offset: Offset(2, 2), blurRadius: 3, spreadRadius: 0.5),
            BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 3, spreadRadius: 0.5),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCategoryButtonWithDoubleClick(
              'Rent',
              isActive: filterState.selectedPropertyFor == 'Rent',
              onTap: () {
                setState(() {
                  if (filterState.selectedPropertyFor == 'Rent') {
                    // Double-click: deselect
                    filterState.selectedPropertyFor = 'All'; // or empty string ''
                  } else {
                    filterState.selectedPropertyFor = 'Rent';
                  }
                });
              },
            ),
            _buildCategoryButtonWithDoubleClick(
              'Sale',
              isActive: filterState.selectedPropertyFor == 'Sale',
              onTap: () {
                setState(() {
                  if (filterState.selectedPropertyFor == 'Sale') {
                    // Double-click: deselect
                    filterState.selectedPropertyFor = 'All'; // or empty string ''
                  } else {
                    filterState.selectedPropertyFor = 'Sale';
                    // Auto-select Buyer when Sale is selected (optional)
                    // filterState.selectedOwnerType = 'Buyer';
                  }
                });
              },
            ),
            _buildCategoryButtonWithDoubleClick(
              'Lease',
              isActive: filterState.selectedPropertyFor == 'Lease',
              onTap: () {
                setState(() {
                  if (filterState.selectedPropertyFor == 'Lease') {
                    // Double-click: deselect
                    filterState.selectedPropertyFor = 'All'; // or empty string ''
                  } else {
                    filterState.selectedPropertyFor = 'Lease';
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Updated category button with double-click functionality
  Widget _buildCategoryButtonWithDoubleClick(String label, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryGreen : AppColors.taroGrey,
          borderRadius: BorderRadius.circular(100),
          boxShadow:
              isActive
                  ? const [
                    BoxShadow(color: Color(0xFFBFC5CA), offset: Offset(2, 2), blurRadius: 4, spreadRadius: 0.5),
                    BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4, spreadRadius: 0.5),
                  ]
                  : const [BoxShadow(color: Colors.white), BoxShadow(color: Colors.white)],
        ),
        child: Center(child: Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.taroBlack, fontWeight: FontWeight.w500, fontSize: 11))),
      ),
    );
  }
  // Updated Bottom Sheet with Property Subtype Filters

  void _showFilterBottomSheet(BuildContext context) {
    final leadProvider = context.read<LeadProvider>();

    // Get available data from properties and leads
    List<String> availableLocations = _getAvailableLocations(leadProvider);

    List<String> availableTenantPreferences = _getAvailableTenantPreferences(leadProvider);

    // Create current filter state from LeadProvider and local state
    UnifiedFilterState currentFilterState =
        UnifiedFilterState()
          ..selectedLeadType = filterState.selectedLeadType
          ..selectedOwnerType = leadProvider.selectedOwnerType
          ..selectedPropertyFor = leadProvider.selectedPropertyFor
          ..selectedPropertyType = leadProvider.selectedPropertyType
          ..selectedTransactionType =
              leadProvider
                  .selectedPropertyFor // Sync these
          ..selectedBHK = leadProvider.selectedBHK
          ..selectedFurnishingStatus = leadProvider.selectedFurnishingStatus
          ..selectedStatuses = List.from(leadProvider.selectedStatuses)
          ..selectedSubtypes = List.from(leadProvider.selectedPropertySubtypes)
          ..selectedLocations = List.from(leadProvider.selectedLocations)
          ..selectedBudgetRanges = List.from(leadProvider.selectedBudgetRanges)
          ..selectedTenantPreferences = List.from(leadProvider.selectedTenantPreferences)
          ..minPrice = leadProvider.minPrice
          ..maxPrice = leadProvider.maxPrice
          ..useSliderBudget =
              false // Default to chips
          ..minBudgetSlider = _getMinSliderValue(leadProvider.selectedPropertyFor)
          ..maxBudgetSlider = _getMaxSliderValue(leadProvider.selectedPropertyFor);

    showGlobalFilterSheet(
      context: context,
      currentFilterState: currentFilterState,
      availableLocations: availableLocations,
      // availableBudgetRanges: availableBudgetRanges,
      availableTenantPreferences: availableTenantPreferences,
      onApplyFilters: (UnifiedFilterState newFilterState) {
        // Apply the filters to LeadProvider
        _applyFiltersToProvider(newFilterState, leadProvider);

        // Update local filter state
        setState(() {
          filterState.selectedLeadType = newFilterState.selectedLeadType;
          filterState.selectedOwnerType = newFilterState.selectedOwnerType;
          filterState.selectedPropertyFor = newFilterState.selectedPropertyFor;
          filterState.selectedTransactionType = newFilterState.selectedTransactionType;
          filterState.selectedPropertyType = newFilterState.selectedPropertyType;
          filterState.selectedBHK = newFilterState.selectedBHK;
          filterState.selectedFurnishingStatus = newFilterState.selectedFurnishingStatus;
          filterState.selectedStatuses = List.from(newFilterState.selectedStatuses);
          filterState.selectedSubtypes = List.from(newFilterState.selectedSubtypes);
          filterState.selectedLocations = List.from(newFilterState.selectedLocations);
          filterState.selectedBudgetRanges = List.from(newFilterState.selectedBudgetRanges);
          filterState.selectedTenantPreferences = List.from(newFilterState.selectedTenantPreferences);
          filterState.minPrice = newFilterState.minPrice;
          filterState.maxPrice = newFilterState.maxPrice;
          filterState.useSliderBudget = newFilterState.useSliderBudget;
          filterState.minBudgetSlider = newFilterState.minBudgetSlider;
          filterState.maxBudgetSlider = newFilterState.maxBudgetSlider;
        });

        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 20), SizedBox(width: 8), Text('Filters applied successfully!')]),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }

  // FIXED: Helper methods to get correct slider values (in actual rupees, not lakhs)
  // double _getMinSliderValue(String propertyFor) {
  //   switch (propertyFor.toLowerCase()) {
  //     case 'rent':
  //     case 'lease':
  //       return 5000.0; // ₹5,000 (actual rupees)
  //     case 'sale':
  //       return 50000.0; // ₹50,000 (actual rupees)
  //     default:
  //       return 5000.0; // Default to rent minimum
  //   }
  // }

  // double _getMaxSliderValue(String propertyFor) {
  //   switch (propertyFor.toLowerCase()) {
  //     case 'rent':
  //     case 'lease':
  //       return 1000000.0; // ₹10 Lakh (actual rupees)
  //     case 'sale':
  //       return 50000000.0; // ₹5 Crore (actual rupees)
  //     default:
  //       return 50000000.0; // Default to sale maximum
  //   }
  // }

  void _applyFiltersToProvider(UnifiedFilterState newFilterState, LeadProvider leadProvider) {
    print('=== APPLYING ENHANCED FILTERS TO PROVIDER ===');
    print('Lead Type: ${newFilterState.selectedLeadType}');
    print('Property For: ${newFilterState.selectedPropertyFor}');
    print('Transaction Type: ${newFilterState.selectedTransactionType}');
    print('Property Type: ${newFilterState.selectedPropertyType}');
    print('BHK: ${newFilterState.selectedBHK}');
    print('Furnishing Status: ${newFilterState.selectedFurnishingStatus}');
    print('Selected Locations: ${newFilterState.selectedLocations}');
    print('Selected Subtypes: ${newFilterState.selectedSubtypes}');
    print('Min Price: "${newFilterState.minPrice}"');
    print('Max Price: "${newFilterState.maxPrice}"');
    print('Use Slider Budget: ${newFilterState.useSliderBudget}');
    print('Slider Min: ${newFilterState.minBudgetSlider} (actual rupees)');
    print('Slider Max: ${newFilterState.maxBudgetSlider} (actual rupees)');

    // Apply all standard filters
    leadProvider.setOwnerTypeFilter(newFilterState.selectedLeadType);

    String propertyForValue = newFilterState.selectedPropertyFor;
    if (propertyForValue == 'All') {
      propertyForValue = newFilterState.selectedTransactionType;
    }
    leadProvider.setPropertyForFilter(propertyForValue);

    leadProvider.setPropertyTypeFilter(newFilterState.selectedPropertyType);
    leadProvider.setBHKFilter(newFilterState.selectedBHK);
    leadProvider.setFurnishingStatusFilter(newFilterState.selectedFurnishingStatus);

    // Clear and apply subtypes
    leadProvider.selectedPropertySubtypes.clear();
    for (String subtype in newFilterState.selectedSubtypes) {
      String normalizedSubtype = _normalizeSubtypeName(subtype);
      if (!leadProvider.selectedPropertySubtypes.contains(normalizedSubtype)) {
        leadProvider.selectedPropertySubtypes.add(normalizedSubtype);
      }
    }

    // Apply status filters
    leadProvider.selectedStatuses = List.from(newFilterState.selectedStatuses);

    // Apply location filters
    leadProvider.setLocationFilters(newFilterState.selectedLocations);

    // Apply tenant preferences
    leadProvider.setTenantPreferencesFilter(newFilterState.selectedTenantPreferences);

    // ENHANCED: Apply budget filters to the provider's filterState
    leadProvider.filterState.useSliderBudget = newFilterState.useSliderBudget;
    leadProvider.filterState.minBudgetSlider = newFilterState.minBudgetSlider;
    leadProvider.filterState.maxBudgetSlider = newFilterState.maxBudgetSlider;

    if (newFilterState.useSliderBudget) {
      // Clear text-based budget filters when using slider
      leadProvider.setBudgetRange('', '');
      leadProvider.clearBudgetFilters();

      print('🔧 Applied slider budget: ₹${newFilterState.minBudgetSlider} - ₹${newFilterState.maxBudgetSlider}');
    } else {
      // Use chip-based budget ranges or text input
      if (newFilterState.selectedBudgetRanges.isNotEmpty) {
        leadProvider.setBudgetRanges(newFilterState.selectedBudgetRanges);
        print('🔧 Applied budget range chips: ${newFilterState.selectedBudgetRanges}');
      } else {
        leadProvider.clearBudgetFilters();
      }

      // Apply min /max price from text fields
      if (newFilterState.minPrice.isNotEmpty || newFilterState.maxPrice.isNotEmpty) {
        leadProvider.setBudgetRange(newFilterState.minPrice, newFilterState.maxPrice);
        print('🔧 Applied text budget range: "${newFilterState.minPrice}" - "${newFilterState.maxPrice}"');
      }
    }

    // Trigger the filter application
    leadProvider.applyFilters();

    print('=== FILTERS APPLIED TO PROVIDER ===');
  }

  // Update your slider value helper methods
  double _getMinSliderValue(String propertyFor) {
    switch (propertyFor.toLowerCase()) {
      case 'rent':
      case 'lease':
        return 5000.0; // ₹5,000 (actual rupees)
      case 'sale':
        return 50000.0; // ₹50,000 (actual rupees)
      default:
        return 5000.0; // Default to rent minimum
    }
  }

  double _getMaxSliderValue(String propertyFor) {
    switch (propertyFor.toLowerCase()) {
      case 'rent':
      case 'lease':
        return 1000000.0; // ₹10 Lakh (actual rupees)
      case 'sale':
        return 50000000.0; // ₹5 Crore (actual rupees)
      default:
        return 50000000.0; // Default to sale maximum
    }
  }

  String _normalizeSubtypeName(String subtype) {
    // Map UI display names to database field names
    final Map<String, String> subtypeMapping = {
      'Shop/Showroom': 'shop/showroom',
      'Flat/Apartment': 'flat/apartment',
      'House/Villa': 'house/villa',
      'Office Space': 'office space',
      'Go down': 'go down',
      // Add reverse mappings for safety
      'shop/showroom': 'shop/showroom',
      'flat/apartment': 'flat/apartment',
      'house/villa': 'house/villa',
      'office space': 'office space',
      'go down': 'go down',
      // Handle variations
      'godown': 'go down',
      'warehouse': 'go down',
      'Shop': 'shop/showroom',
      'Showroom': 'shop/showroom',
      'Flat': 'flat/apartment',
      'Apartment': 'flat/apartment',
      'House': 'house/villa',
      'Villa': 'house/villa',
      'Office': 'office space',
    };

    String normalized = subtypeMapping[subtype] ?? subtype.toLowerCase();
    print('🔵 Normalizing "$subtype" -> "$normalized"');
    return normalized;
  }

  // Updated helper method to count active filters
  int _getActiveFilterCount() {
    int count = 0;

    if (filterState.selectedLeadType != 'All') count++;
    if (filterState.selectedPropertyFor != 'All') count++;
    if (filterState.selectedPropertyType != 'All') count++;
    if (filterState.selectedSpecificPropertyType != 'All') count++;
    if (filterState.selectedTransactionType != 'All') count++;
    if (filterState.selectedBHK != 'All') count++; // NEW
    if (filterState.selectedFurnishingStatus != 'All') count++; // NEW
    if (filterState.selectedStatuses.isNotEmpty) count++;
    if (filterState.selectedSubtypes.isNotEmpty) count++;
    if (filterState.selectedLocations.isNotEmpty) count++;
    if (filterState.selectedBudgetRanges.isNotEmpty) count++;
    if (filterState.selectedTenantPreferences.isNotEmpty) count++;
    if (filterState.minPrice.isNotEmpty || filterState.maxPrice.isNotEmpty) count++;
    if (filterState.useSliderBudget && (filterState.minBudgetSlider > 0 || filterState.maxBudgetSlider < 500)) count++;

    return count;
  }

  // Enhanced helper methods for getting available options
  List<String> _getAvailableTenantPreferences(LeadProvider leadProvider) {
    return leadProvider.getAvailableTenantPreferencesWithDebug();
  }

  List<String> _getAvailableLocations(LeadProvider leadProvider) {
    return leadProvider.getAvailableLocations();
  }

  // Enhanced method to get budget ranges based on current property type

  Stream<List<BaseProperty>> getFilteredPropertiesForLead(String leadId) {
    if (leadId.isEmpty) return Stream.value([]);

    print(
      'Fetching properties for leadId: $leadId with filters: '
      'LeadType: ${filterState.selectedLeadType}, '
      'PropertyFor: ${filterState.selectedPropertyFor}, '
      // 'PropertyType: ${filterState.selectedPropertyType}',
      'OwnerType: ${filterState.selectedOwnerType}',
    );

    // If showing all, don't filter by propertyFor
    String? propertyForFilter = filterState.selectedPropertyFor == 'All' ? null : filterState.selectedPropertyFor;

    // Create list of property streams based on property type filter
    List<Stream<List<BaseProperty>>> propertyStreams = [];

    if (filterState.selectedPropertyType == 'All' || filterState.selectedPropertyType == 'Residential') {
      propertyStreams.add(_buildPropertyStream('Residential', leadId, propertyForFilter, (data, id) => ResidentialProperty.fromMap(data, id)));
    }

    if (filterState.selectedPropertyType == 'All' || filterState.selectedPropertyType == 'Commercial') {
      propertyStreams.add(_buildPropertyStream('Commercial', leadId, propertyForFilter, (data, id) => CommercialProperty.fromMap(data, id)));
    }

    if (filterState.selectedPropertyType == 'All' || filterState.selectedPropertyType == 'Plots') {
      propertyStreams.add(_buildPropertyStream('Plots', leadId, propertyForFilter, (data, id) => LandProperty.fromMap(data, id)));
    }

    // If no streams (shouldn't happen), return empty
    if (propertyStreams.isEmpty) {
      return Stream.value([]);
    }

    return CombineLatestStream.list(propertyStreams).map((listOfLists) {
      List<BaseProperty> allProperties = [];
      for (List<BaseProperty> propertyList in listOfLists) {
        allProperties.addAll(propertyList);
      }

      print('Total Properties found for leadId $leadId: ${allProperties.length}');
      return allProperties;
    });
  }

  // Helper method to build property streams with filtering
  Stream<List<BaseProperty>> _buildPropertyStream(String collection, String leadId, String? propertyFor, BaseProperty Function(Map<String, dynamic>, String) fromMap) {
    Query query = FirebaseFirestore.instance.collection(collection).where('leadId', isEqualTo: leadId).where('status', isNotEqualTo: 'Inactive');

    // Add propertyFor filter if provided
    if (propertyFor != null && propertyFor.isNotEmpty) {
      query = query.where('propertyFor', isEqualTo: propertyFor);
    }

    return query.snapshots().map((snapshot) {
      final list =
          snapshot.docs
              .map((doc) {
                print('Found $collection Property: ${doc.id} for leadId: $leadId');
                return fromMap(doc.data() as Map<String, dynamic>, doc.id);
              })
              .cast<BaseProperty>()
              .toList();

      print('Total $collection Properties for $leadId: ${list.length}');
      return list;
    });
  }

  // Method to check if a lead should be shown based on current filters
  bool shouldShowLead(LeadModel lead, List<BaseProperty> properties) {
    // 1. Handle status filtering FIRST (single location, no duplicates)
    if (filterState.selectedStatuses.isNotEmpty) {
      // User selected specific statuses - check if lead status matches
      if (!filterState.selectedStatuses.contains(lead.status)) {
        return false;
      }
    } else {
      // Default behavior: hide 'Archived' if no status filter is applied
      if (lead.status == 'Archived' || lead.status == 'Lost') {
        return false;
      }
    }

    // 2. If all filters are set to "All", show everything (but archived is already handled above)
    if (filterState.isAllSelected) {
      return true;
    }

    // 3. Check lead type filter
    if (filterState.selectedLeadType != 'All') {
      if (lead.leadType != filterState.selectedLeadType) {
        return false;
      }
    }

    // 4. Check if lead has properties matching the property type and propertyFor filters
    if (filterState.selectedPropertyType != 'All' || filterState.selectedPropertyFor != 'All') {
      if (properties.isEmpty) {
        return false; // No properties match the filter criteria
      }
    }

    // 5. REMOVED: Duplicate status filter check (was here before)
    // This was overriding the archived lead filtering done at the top

    return true;
  }

  String formatLeadCategoryForDisplay(String leadCategory) {
    if (leadCategory.isEmpty) return '';

    String category = leadCategory.toLowerCase().trim();

    // Handle bachelor cases
    if (category.contains('bachelor')) {
      if (category.contains('(f)') || category.contains('female')) {
        return 'Bachelor F';
      } else if (category.contains('(m)') || category.contains('male')) {
        return 'Bachelor M';
      } else {
        return 'Bachelor';
      }
    }

    // Handle family cases
    if (category.contains('family')) {
      return 'Family';
    }

    // For any other category, return as is (same as input)
    return leadCategory;
  }

  // Add these variables to your widget's state class
  Set<String> selectedLeadIds = {};
  bool isSelectionMode = false;

  Widget _buildLeadCard(LeadModel lead) {
    return StreamBuilder<List<BaseProperty>>(
      stream: getFilteredPropertiesForLead(lead.id ?? ''),
      builder: (context, propertySnapshot) {
        final properties = propertySnapshot.data ?? [];

        if (!shouldShowLead(lead, properties)) {
          return const SizedBox.shrink();
        }

        final isSelected = selectedLeadIds.contains(lead.id);

        return GestureDetector(
          onTap: () {
            if (isSelectionMode) {
              _toggleLeadSelection(lead.id ?? '');
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsDisplayScreen(lead: lead)));
            }
          },
          onLongPress: () {
            if (!isSelectionMode) {
              _enterSelectionMode(lead.id ?? '');
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
              border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, spreadRadius: 1, offset: const Offset(4, 4))],
            ),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  // Left border - Fixed width to prevent flicker
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: isSelected ? 0 : 3,
                      decoration: BoxDecoration(color: isSelected ? Colors.red : _getColorForPropertyFor(properties.isNotEmpty ? properties.first.propertyFor : null)),
                    ),
                  ),

                  // Top border - Fixed height to prevent flicker
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    child: Container(height: isSelected ? 0 : 3, decoration: BoxDecoration(color: isSelected ? Colors.red : AppColors.primaryGreen)),
                  ),

                  // Content - Use Padding instead of Positioned for main content
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row with name, status, and actions
                        Row(
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: AvatarColorUtils.getAvatarColorFromLead(lead), shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?', style: AppFonts.interBold.copyWith(fontSize: 18, color: Colors.white)),
                                  ),
                                ),
                                // Selection indicator
                                if (isSelected)
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(width: 12),

                            // Name and type - Expanded is now properly inside Row
                            Expanded(
                              child: Transform.translate(
                                offset: const Offset(0, -8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lead.name, style: AppFonts.interBold.copyWith(fontSize: 18, color: Colors.black87), overflow: TextOverflow.ellipsis),
                                    Row(
                                      children: [
                                        // Lead Type Chip
                                        if (lead.leadType.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                                            child: Text(lead.leadType, style: AppFonts.interDefault.copyWith(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                                          ),

                                        // Optional spacing between chips
                                        if (lead.leadType.isNotEmpty && lead.leadCategory?.isNotEmpty == true) const SizedBox(width: 8),

                                        // Lead Category Chip
                                        if (lead.leadCategory?.isNotEmpty == true)
                                          Text(lead.leadCategory!, style: AppFonts.interDefault.copyWith(fontSize: 11, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Status badge and action buttons
                            Column(
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, 15),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(20)),
                                    child: GestureDetector(
                                      onTap: () {
                                        _showStatusMenu(context, lead);
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(lead.status == 'New Lead' ? 'New lead' : lead.status, style: AppFonts.interSemiBold.copyWith(fontSize: 12, color: Colors.white)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildNeumorphicIcon(AppImages.whatsappIcon, () => _launchWhatsApp(lead)),
                                    const SizedBox(width: 15),
                                    _buildNeumorphicIcon(AppImages.callIcon, () => _makePhoneCall(lead)),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(width: 12),
                          ],
                        ),

                        // Property details
                        Transform.translate(offset: const Offset(0, -15), child: _buildNewLeadPropertyInfo(properties, lead)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSelectionSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Container(
        height: 60,
        child: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.grey[700], size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${selectedLeadIds.length} lead${selectedLeadIds.length > 1 ? 's' : ''} selected',
                    style: AppFonts.interSemiBold.copyWith(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            // Cancel button
            TextButton(
              onPressed: _exitSelectionMode,
              style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text('Cancel', style: AppFonts.interDefault.copyWith(fontSize: 14, color: Colors.grey[600])),
            ),
            SizedBox(width: 8),
            // Delete button
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _showDeleteConfirmation,
                icon: Icon(Icons.delete, size: 18),
                label: Text('DELETE', style: AppFonts.interSemiBold.copyWith(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      behavior: SnackBarBehavior.fixed, // Fixed behavior - covers bottom nav
      duration: Duration(days: 1),
      // No margin property when using fixed behavior
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      elevation: 8,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Delete Leads', style: AppFonts.interBold.copyWith(fontSize: 18), textAlign: TextAlign.center),
          content: Text(
            'Are you sure you want to delete ${selectedLeadIds.length} lead${selectedLeadIds.length > 1 ? 's' : ''}? This action cannot be undone.',
            style: AppFonts.interDefault.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: AppFonts.interDefault.copyWith(color: Colors.grey.shade600))),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedLeads();
              },
              child: Text('Delete', style: AppFonts.interSemiBold.copyWith(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedLeads() async {
    try {
      final selectedCount = selectedLeadIds.length;

      // Hide selection snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
              SizedBox(width: 12),
              Text('Deleting $selectedCount lead${selectedCount > 1 ? 's' : ''}...', style: AppFonts.interDefault.copyWith(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.only(bottom: 20, left: 16, right: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Delete leads from Firestore
      for (String leadId in selectedLeadIds) {
        await FirebaseFirestore.instance.collection('leads').doc(leadId).delete();
      }

      // for (String leadId in selectedLeadIds) {
      //   try {
      //     // Step 1: Fetch the lead document to get the propertyType
      //     final leadSnapshot =
      //         await _firestore.collection('leads').doc(leadId).get();

      //     if (leadSnapshot.exists) {
      //       final data = leadSnapshot.data();
      //       final propertyType = data?['propertyType'] ?? '';

      //       // Step 2: Call deleteLead with fetched propertyType
      //       await deleteLead(context, leadId, propertyType);
      //     } else {
      //       print('Lead not found: $leadId');
      //     }
      //   } catch (e) {
      //     print('Error processing leadId $leadId: $e');
      //   }
      // }

      // Exit selection mode and notify parent
      setState(() {
        isSelectionMode = false;
        selectedLeadIds.clear();
      });

      // Notify parent about selection mode change
      widget.onSelectionModeChanged?.call(false);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('$selectedCount lead${selectedCount > 1 ? 's' : ''} deleted successfully', style: AppFonts.interDefault.copyWith(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            margin: EdgeInsets.only(bottom: 20, left: 16, right: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      // Show error and exit selection mode
      setState(() {
        isSelectionMode = false;
        selectedLeadIds.clear();
      });

      // Notify parent about selection mode change
      widget.onSelectionModeChanged?.call(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Failed to delete leads. Please try again.', style: AppFonts.interDefault.copyWith(color: Colors.white))),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            margin: EdgeInsets.only(bottom: 20, left: 16, right: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> deleteLead(BuildContext context, String leadId, String propertyType) async {
    try {
      // Delete lead document
      await _firestore.collection('leads').doc(leadId).delete();

      // Determine the correct property collection
      String collectionName;
      switch (propertyType) {
        case 'Residential':
          collectionName = 'Residential';
          break;
        case 'Commercial':
          collectionName = 'Commercial';
          break;
        case 'Plot':
        case 'Land':
          collectionName = 'Plots';
          break;
        default:
          collectionName = '';
      }

      // Delete associated property if applicable
      if (collectionName.isNotEmpty) {
        await _firestore.collection(collectionName).doc(leadId).delete();
      }

      print('Lead and associated property deleted: $leadId');

      if (context.mounted) {
        await context.read<LeadProvider>().fetchLeads(); // Refresh list
      }
    } catch (e) {
      print('Error deleting lead: $e');
    } finally {}
  }

  // Status menu helper method
  void _showStatusMenu(BuildContext context, LeadModel lead) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size buttonSize = button.size;

    final RelativeRect position = RelativeRect.fromRect(Rect.fromLTWH(buttonPosition.dx + buttonSize.width, buttonPosition.dy, 0, 0), Offset.zero & overlay.size);

    // Define statuses based on lead type
    List<String> statuses;

    if (lead.leadType == 'Owner') {
      statuses = ['New Lead', 'Details Collected', 'Listing Live', 'Advance Received', 'Agreement', 'Payment Complete', 'Closed', 'Archived', 'Lost'];
    } else {
      // For Buyer/Tenant
      statuses = ['New Lead', 'Details Shared', 'Site Visit', 'Negotiation', 'Advance Paid', 'Agreement', 'Payment Complete', 'Closed', 'Archived', 'Lost'];
    }

    // Generate popup menu items dynamically
    List<PopupMenuItem<String>> menuItems =
        statuses.map((status) {
          return PopupMenuItem(value: status, child: Center(child: Text(status, style: AppFonts.interDefault.copyWith(fontSize: 12))));
        }).toList();

    showMenu<String>(context: context, position: position, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), color: Colors.white, items: menuItems).then((
      String? selectedValue,
    ) async {
      if (selectedValue != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updating status to $selectedValue...', style: AppFonts.interDefault), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
        );
        await _updateLeadStatusInFirestore(selectedValue, lead, context);
      }
    });
  }

  // Helper method to get avatar color based on lead type

  Color _getAvatarColor(String leadType, {String? uniqueId}) {
    // Use current timestamp or provided unique ID
    final seed = uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final combined = '$leadType-$seed';

    int hash = combined.hashCode.abs();
    double hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  // Updated property info display for the new design
  // Replace the _buildNewLeadPropertyInfo method in your _LeadsViewState class with this:

  Color _getColorForPropertyFor(String? propertyFor) {
    if (propertyFor == null) return const Color(0xFF108981); // Default color

    switch (propertyFor.toLowerCase()) {
      case 'rent':
        return const Color.fromARGB(255, 26, 170, 160); // Teal
      case 'sale':
        return const Color(0xFFF59E0B); // Orange
      case 'lease':
        return const Color(0xFFB388FF); // Purple
      default:
        return const Color(0xFF108981); // Default teal
    }
  }

  Widget _buildNewLeadPropertyInfo(List<BaseProperty> properties, LeadModel lead) {
    if (properties.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
        child: Row(children: [SizedBox(width: 8), Text('', style: AppFonts.interDefault.copyWith(color: Colors.grey[600], fontSize: 12))]),
      );
    }

    final primaryProperty = properties.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location row with icon (from NEW method)
        if (primaryProperty.location?.isNotEmpty == true)
          Transform.translate(
            offset: Offset(-1, 0), // Move 2 pixels to the left
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 12),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatLocationForNewCard(primaryProperty.location),
                    style: AppFonts.interDefault.copyWith(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 5),
        // Use OLD method for property details display
        if (primaryProperty is ResidentialProperty) _buildCompactResidentialDetails(primaryProperty, lead),
        if (primaryProperty is CommercialProperty) _buildCompactCommercialDetails(primaryProperty),
        if (primaryProperty is LandProperty) _buildCompactLandDetails(primaryProperty),

        // NEW method ONLY for price display with better formatting
        if (primaryProperty.askingPrice?.isNotEmpty == true)
          Row(
            children: [
              Text(
                _formatPriceForNewCard(primaryProperty.askingPrice, primaryProperty.propertyFor) +
                    (primaryProperty.propertyFor?.toLowerCase() == 'rent'
                        ? ' /month${_hasDeposit(primaryProperty) ? '*' : ''}'
                        : primaryProperty.propertyFor?.toLowerCase() == 'lease' && primaryProperty.leadDuration?.isNotEmpty == true
                        ? ' ${primaryProperty.leadDuration}'
                        : ''),
                style: AppFonts.interBold.copyWith(fontSize: 18, color: AppColors.primaryGreen),
              ),

              if (primaryProperty.propertyFor?.toLowerCase() == 'rent') ...[
                // if (_hasDeposit(primaryProperty)) ...[
                //   const SizedBox(width: 4),
                //   Text(
                //     _getDepositText(primaryProperty),
                //     style: propertyTextStyle.copyWith(
                //       fontWeight: FontWeight.w500,
                //     ),
                //     maxLines: 1,
                //     overflow: TextOverflow.ellipsis,
                //   ),
                // ],
                if (_hasMaintenance(primaryProperty)) ...[
                  const SizedBox(width: 8),
                  Text(_getMaintenanceText(primaryProperty), style: propertyTextStyle.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ],
          ),

        SizedBox(height: 5),

        _buildTagsRow(primaryProperty, lead),
      ],
    );
  }

  // Keep your existing _formatPriceForNewCard method as is:

  String _formatPriceForNewCard(String? price, String? propertyFor) {
    if (price == null || price.isEmpty) return '';

    final numPrice = int.tryParse(price.replaceAll(',', ''));
    if (numPrice == null) return '₹$price';

    if (numPrice >= 10000000) {
      final crores = numPrice / 10000000;
      return '₹${crores.toStringAsFixed(crores == crores.toInt() ? 0 : 1)} Cr';
    }

    // Use comma formatting for everything else
    final formatted = NumberFormat('#,##,###').format(numPrice);
    return '₹$formatted';
  }

  // Also keep your existing helper methods for deposit:
  bool _hasDeposit(BaseProperty property) {
    if (property is ResidentialProperty) {
      return property.deposit?.isNotEmpty == true && property.deposit != '0';
    }
    return false;
  }

  bool _hasMaintenance(BaseProperty property) {
    if (property is ResidentialProperty) {
      return property.maintenance?.isNotEmpty == true && property.maintenance != '0';
    }
    return false;
  }

  String _getMaintenanceText(BaseProperty property) {
    if (property is ResidentialProperty && property.maintenance?.isNotEmpty == true && property.maintenance != '0') {
      return '🛠 ${_formatPriceForNewCard(property.maintenance, null)} /month';
    }
    return '';
  }

  String _getDepositText(BaseProperty property) {
    if (property is ResidentialProperty && property.deposit?.isNotEmpty == true && property.deposit != '0') {
      return '💰: ${_formatPriceForNewCard(property.deposit, null)}';
    }
    return '';
  }

  // Also add the _buildTagsRow method and _buildTag helper method:
  Widget _buildTagsRow(BaseProperty property, LeadModel lead) {
    List<Widget> tags = [];

    // Add property-specific tags
    if (property is ResidentialProperty) {
      if (lead.leadType == 'Owner') {
        if (property.preferences.isNotEmpty == true) {
          for (String preference in property.preferences) {
            tags.add(_buildTag(preference));
          }
        }
      } else {
        if (property.facilities.isNotEmpty == true) {
          for (String facility in property.facilities) {
            tags.add(_buildTag(facility));
          }
        }
      }

      // if (property.preferences?.isNotEmpty == true) {
      //   for (String preference in property.preferences!.take(2)) {
      //     tags.add(_buildTag(preference));
      //   }
      // }
      // if (property.facilities?.isNotEmpty == true) {
      //   for (String facility in property.facilities!.take(3 - tags.length)) {
      //     tags.add(_buildTag(facility));
      //   }
      // }
    } else if (property is CommercialProperty) {
      if (property.facilities?.isNotEmpty == true) {
        for (String facility in property.facilities!) {
          tags.add(_buildTag(facility));
        }
      }
      if (property.noOfSeats?.isNotEmpty == true) {
        tags.add(_buildTag('${property.noOfSeats} seats'));
      }
      if (property.washrooms?.isNotEmpty == true) {
        tags.add(_buildTag('${property.washrooms} bathroom'));
      }
    }

    if (tags.isEmpty) return SizedBox.shrink();

    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: tags.map((tag) => Padding(padding: EdgeInsets.only(right: 8), child: tag)).toList()));
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: AppFonts.interDefault.copyWith(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500)),
    );
  }

  // Also add the _formatLocationForNewCard helper method:
  String _formatLocationForNewCard(String? location) {
    if (location == null || location.isEmpty) return '';

    // Remove "India" and postal codes, take first two parts
    String cleanLocation = location.replaceAll(RegExp(r',\s*India$'), '').replaceAll(RegExp(r',\s*\d{6}'), '').trim();

    List<String> parts = cleanLocation.split(',').map((e) => e.trim()).toList();
    String result = parts.isNotEmpty ? parts[0] : location;

    // Cap to 2 words
    List<String> words = result.split(' ');
    if (words.length > 2) {
      return '${words[0]} ${words[1]}';
    }

    return result;
  }

  // Helper methods for property details
  List<Widget> _buildResidentialDetails(ResidentialProperty property) {
    List<Widget> details = [];

    if (property.selectedBHK?.isNotEmpty == true) {
      details.add(
        Row(
          children: [
            Icon(Icons.home, color: Colors.grey[600], size: 16),
            SizedBox(width: 4),
            Text(property.selectedBHK!, style: AppFonts.interDefault.copyWith(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      );
    }

    if (property.propertySubType?.isNotEmpty == true) {
      if (details.isNotEmpty) details.add(SizedBox(width: 16));
      details.add(Text(property.propertySubType!, style: AppFonts.interDefault.copyWith(fontSize: 14, color: Colors.grey[700])));
    }

    String furnishing = _getFurnishingText(property);
    if (furnishing.isNotEmpty) {
      if (details.isNotEmpty) details.add(SizedBox(width: 16));
      details.add(
        Row(
          children: [
            Icon(Icons.chair, color: Colors.grey[600], size: 16),
            SizedBox(width: 4),
            Text(furnishing, style: AppFonts.interDefault.copyWith(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      );
    }

    return details;
  }

  List<Widget> _buildCommercialDetails(CommercialProperty property) {
    List<Widget> details = [];

    if (property.propertySubType?.isNotEmpty == true) {
      details.add(
        Row(
          children: [
            Icon(Icons.business, color: Colors.grey[600], size: 16),
            SizedBox(width: 4),
            Text(property.propertySubType!, style: AppFonts.interDefault.copyWith(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      );
    }

    if (property.furnished?.isNotEmpty == true) {
      if (details.isNotEmpty) details.add(SizedBox(width: 16));
      details.add(
        Row(
          children: [
            Icon(Icons.chair, color: Colors.grey[600], size: 16),
            SizedBox(width: 4),
            Text(property.furnished!, style: AppFonts.interDefault.copyWith(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      );
    }

    return details;
  }

  List<Widget> _buildLandDetails(LandProperty property) {
    List<Widget> details = [];

    if (property.propertySubType?.isNotEmpty == true) {
      details.add(
        Row(
          children: [
            Icon(Icons.terrain, color: Colors.grey[600], size: 16),
            SizedBox(width: 4),
            Text('${property.propertySubType!} Plot', style: AppFonts.interDefault.copyWith(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      );
    }

    String area = _getAreaText(property);
    if (area.isNotEmpty) {
      if (details.isNotEmpty) details.add(SizedBox(width: 16));
      details.add(Text(area, style: AppFonts.interDefault.copyWith(fontSize: 14, color: Colors.grey[700])));
    }

    return details;
  }

  String _getAreaText(LandProperty property) {
    if (property.acres?.isNotEmpty == true && property.acres != '0') {
      return '${property.acres} acres';
    }
    if (property.cents?.isNotEmpty == true && property.cents != '0') {
      return '${property.cents} cents';
    }
    if (property.squareFeet?.isNotEmpty == true && property.squareFeet != '0') {
      return '${property.squareFeet} sq ft';
    }
    return '';
  }

  Future _updateLeadStatusInFirestore(String newStatus, LeadModel lead, BuildContext context) async {
    try {
      if (lead.id != null) {
        final docRef = FirebaseFirestore.instance.collection('leads').doc(lead.id);

        // if (newStatus.toLowerCase() == 'archived') {
        //   await docRef.delete();
        //   print('Lead archived and deleted successfully');
        // } else {
        await docRef.update({'status': newStatus});
        print('Lead status updated successfully');
        // }
      } else {
        print('No lead ID found to update or delete');
      }
    } catch (e) {
      print('Error updating lead status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}', style: AppFonts.interDefault),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating, // <-- THIS IS THE FIX
        ),
      );
    }
  }

  // Helper method to navigate to New Reminder Screen with prefilled data
  void _navigateToNewReminder(BuildContext context, LeadModel lead, List<BaseProperty> properties) {
    // Prepare property details for prefilling
    String propertyDetails = _formatPropertyDetails(properties);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => NewReminderScreen(
              prefilledName: lead.name,
              prefilledLeadId: lead.id,
              prefilledPropertyDetails: propertyDetails,
              prefilledLocationDetails: '',
              leadProperties: properties,
            ),
      ),
    );
  }

  // Helper method to format property details
  String _formatPropertyDetails(List<BaseProperty> properties) {
    if (properties.isEmpty) return '';

    List<String> propertyStrings = [];
    for (BaseProperty property in properties) {
      List<String> details = [];

      if (property is ResidentialProperty) {
        // For residential: selectedBHK, propertySubType, and location (2 words)
        String bhk = property.selectedBHK ?? '';
        String subType = property.propertySubType ?? '';
        String location = property.location ?? '';

        // Limit location to 2 words
        if (location.isNotEmpty) {
          List<String> locationWords = location.split(' ').where((word) => word.trim().isNotEmpty).toList();
          if (locationWords.length > 2) {
            location = locationWords.take(2).join(' ');
          }
        }

        if (bhk.isNotEmpty) details.add(bhk);
        if (subType.isNotEmpty) details.add(subType);
        if (location.isNotEmpty) details.add(location);
      } else if (property is CommercialProperty) {
        // For commercial: furnished, propertySubType, and location (2 words)
        String furnished = property.furnished ?? '';
        String subType = property.propertySubType ?? '';
        String location = property.location ?? '';

        // Limit location to 2 words
        if (location.isNotEmpty) {
          List<String> locationWords = location.split(' ').where((word) => word.trim().isNotEmpty).toList();
          if (locationWords.length > 2) {
            location = locationWords.take(2).join(' ');
          }
        }

        if (furnished.isNotEmpty) details.add(furnished);
        if (subType.isNotEmpty) details.add(subType);
        if (location.isNotEmpty) details.add(location);
      } else if (property is LandProperty) {
        // For land/plots: propertySubType, area with unit, and location (2 words)
        String subType = property.propertySubType ?? '';
        String location = property.location ?? '';

        // Limit location to 2 words
        if (location.isNotEmpty) {
          List<String> locationWords = location.split(' ').where((word) => word.trim().isNotEmpty).toList();
          if (locationWords.length > 2) {
            location = locationWords.take(2).join(' ');
          }
        }

        // Check for different area units and use whichever is available
        String areaWithUnit = '';

        if (property.acres != null && property.acres.toString().isNotEmpty) {
          areaWithUnit = '${property.acres} acres';
        } else if (property.cents != null && property.cents.toString().isNotEmpty) {
          areaWithUnit = '${property.cents} cents';
        } else if (property.squareFeet != null && property.squareFeet.toString().isNotEmpty) {
          areaWithUnit = '${property.squareFeet} sq ft';
        } else if (property.acres != null && property.acres.toString().isNotEmpty) {
          // Fallback to generic area field
          String inputUnit = property.inputUnit ?? 'sq ft';
          areaWithUnit = '${property.acres} $inputUnit';
        }

        if (subType.isNotEmpty) details.add(subType);
        if (areaWithUnit.isNotEmpty) details.add(areaWithUnit);
        if (location.isNotEmpty) details.add(location);
      }

      // Join details with bullet separator, same as getPropertyDisplayDetails
      if (details.isNotEmpty) {
        propertyStrings.add(details.join(' • '));
      }
    }

    return propertyStrings.join(', ');
  }

  void _launchWhatsApp(LeadModel lead) async {
    String phoneNumber = lead.whatsappNumber!.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone number not available', style: AppFonts.interDefault), behavior: SnackBarBehavior.floating));
      return;
    }

    // Add +91 if missing
    if (!phoneNumber.startsWith('+91')) {
      phoneNumber = '+91$phoneNumber';
    }

    // WhatsApp URL requires digits only (remove +)
    final cleanNumber = phoneNumber.replaceAll('+', '').replaceAll(RegExp(r'[^\d]'), '');
    final url = 'https://wa.me/$cleanNumber';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch WhatsApp', style: AppFonts.interDefault), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error launching WhatsApp: $e', style: AppFonts.interDefault), behavior: SnackBarBehavior.floating));
    }
  }

  void _makePhoneCall(LeadModel lead) async {
    final phoneNumber = lead.phoneNumber;

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone number not available', style: AppFonts.interDefault), behavior: SnackBarBehavior.floating));
      return;
    }

    // Clean phone number (remove spaces, dashes, etc.)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = 'tel:$cleanNumber';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not make phone call', style: AppFonts.interDefault), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error making phone call: $e', style: AppFonts.interDefault), behavior: SnackBarBehavior.floating));
    }
  }

  // Conditional widget to display property information in lead card
  Widget _buildLeadPropertyInfo(List<BaseProperty> properties, LeadModel lead) {
    if (properties.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
        child: Text('No properties added yet', style: AppFonts.interDefault.copyWith(color: Colors.grey, fontSize: 10)),
      );
    }

    final primaryProperty = properties.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primaryProperty is ResidentialProperty) _buildCompactResidentialDetails(primaryProperty, lead),
        if (primaryProperty is CommercialProperty) _buildCompactCommercialDetails(primaryProperty),
        if (primaryProperty is LandProperty) _buildCompactLandDetails(primaryProperty),
      ],
    );
  }

  String _getFurnishingText(ResidentialProperty property) {
    if (property.furnished == true) return '          🪑: Furnished';
    if (property.unfurnished == true) return '          🪑: Unfurnished'; // ✅ Fixed: unfurnished not preferUnfurnished
    if (property.semiFinished == true) return '          🪑: Semi-Furnished'; // ✅ Fixed: semiFinished not preferSemiFurnished
    return '';
  }

  Widget _buildCompactResidentialDetails(ResidentialProperty property, LeadModel lead) {
    if (lead.leadType == 'Tenant') {
      // 🟦 Show a different UI for tenants WITH budget information
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property details (BHK, Furnishing, Subtype)
          Text(
            [
              property.selectedBHK?.isNotEmpty == true ? '🏠: ${property.selectedBHK}' : null,
              property.propertySubType?.isNotEmpty == true ? property.propertySubType : null,
              _getFurnishingText(property).isNotEmpty ? _getFurnishingText(property) : null,
            ].whereType<String>().join(' '),
            style: propertyTextStyle.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),

          // Location (separated from price)
          // Row(
          //   children: [
          //     if (property.location != null &&
          //         _formatLocation(property.location) != 'N/A')
          //       Text(
          //         '📍: ${_formatLocation(property.location)}',
          //         style: propertyTextStyle,
          //         maxLines: 1,
          //         overflow: TextOverflow.ellipsis,
          //       ),

          //     // Price (independent of location)
          //     if (property.askingPrice?.isNotEmpty == true)
          //       Text(
          //         '💵: ${_formatPrice(property.askingPrice)}${property.propertyFor?.toLowerCase() == 'rent' ? ' /m' : ''}${_getLeaseDurationText(property)}',
          //         style: propertyTextStyle,
          //         maxLines: 1,
          //         overflow: TextOverflow.ellipsis,
          //       ),
          //   ],
          // ),

          // const SizedBox(height: 1),

          // Facilities
          // if (property.facilities?.isNotEmpty == true)
          //   Text(
          //     '🛠️: ${property.facilities!.take(3).join(', ')}${property.facilities!.length > 3 ? '...' : ''}',
          //     style: propertyTextStyle,
          //     maxLines: 1,
          //     overflow: TextOverflow.ellipsis,
          //   ),
        ],
      );
    }

    // For non-tenant leads (Owner/Buyer) - keeping original logic
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(),
        Text(
          [
            property.selectedBHK?.isNotEmpty == true ? '🏠: ${property.selectedBHK}' : null,
            property.propertySubType?.isNotEmpty == true ? property.propertySubType : null,
            _getFurnishingText(property).isNotEmpty ? _getFurnishingText(property) : null,
          ].whereType<String>().join(' '),
          style: propertyTextStyle.copyWith(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // const SizedBox(height: 1),
        // Row(
        //   children: [
        //     Expanded(
        //       flex: 3,
        //       child: Text(
        //         property.location != null && property.location!.isNotEmpty
        //             ? '📍: ${property.location!.split(' ').take(2).join(' ')}'
        //             : '',
        //         style: propertyTextStyle,
        //         maxLines: 1,
        //         overflow: TextOverflow.ellipsis,
        //       ),
        //     ),
        //   ],
        // ),
        // if (property.askingPrice?.isNotEmpty == true) ...[
        //   Text(
        //     _buildPriceText(property),
        //     style: propertyTextStyle,
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        //   const SizedBox(height: 1),
        // ],
        // if (property.facilities?.isNotEmpty == true) ...[
        //   Text(
        //     '👥: ${property.facilities!.take(3).join(', ')}${property.facilities!.length > 3 ? '...' : ''}',
        //     style: propertyTextStyle,
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        // ],
      ],
    );

    // Helper method to build price text with proper conditional separators
  }

  String _getLeaseDurationText(BaseProperty property) {
    if (property.propertyFor?.toLowerCase() == 'lease' && property.leadDuration?.isNotEmpty == true) {
      String duration = property.leadDuration!;

      String convertedDuration = duration.toLowerCase().replaceAll('/month', '/m').replaceAll('/year', '/y');

      return ' $convertedDuration';
    }
    return '';
  }

  Widget _buildCompactCommercialDetails(CommercialProperty property) {
    print('🏢 COMMERCIAL DEBUG: property.location = "${property.location}"');

    // Helper method to build property type line
    String buildPropertyTypeLine() {
      List<String> parts = [];

      if (property.propertySubType?.isNotEmpty == true) {
        parts.add(property.propertySubType!);
      }

      if (property.furnished?.isNotEmpty == true) {
        parts.add('           🪑: ${property.furnished}');
      }

      if (parts.isNotEmpty) {
        return '🏢: ${parts.join(' ')}';
      }

      return '';
    }

    // Helper method to build facilities line

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (buildPropertyTypeLine().isNotEmpty) ...[
          Text(buildPropertyTypeLine(), style: propertyTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
        ],

        if (property.squareFeet?.isNotEmpty == true) ...[
          Text('📏: ${property.squareFeet} sq ft', style: propertyTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
        ],
      ],
    );
  }

  Widget _buildCompactLandDetails(LandProperty property) {
    // Helper method to build location and price line
    String buildLocationPriceLine() {
      List<String> parts = [];

      return parts.join(' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (property.propertySubType?.isNotEmpty == true) ...[
          Text('🏞️: ${property.propertySubType} Plot', style: propertyTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
        ],
        // Show location and price info if either exists
        if (buildLocationPriceLine().isNotEmpty) ...[
          Text(buildLocationPriceLine(), style: propertyTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
        ],
        // Conditional area display based on cents and acres values
        if (_shouldShowAreaInfo(property)) ...[
          Text(_getAreaDisplayText(property), style: propertyTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
        ],
        if (property.additionalNotes?.isNotEmpty == true) Text('📋: ${property.additionalNotes}', style: propertyTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
  // Additional helper method you might need for _formatPrice

  // Helper method to determine if area info should be shown
  bool _shouldShowAreaInfo(LandProperty property) {
    return (property.squareFeet?.isNotEmpty == true && property.squareFeet != "0") ||
        (property.cents?.isNotEmpty == true && property.cents != "0") ||
        (property.acres?.isNotEmpty == true && property.acres != "0");
  }

  // Helper method to get the appropriate area display text
  String _getAreaDisplayText(LandProperty property) {
    final cents = property.cents;
    final acres = property.acres;
    final sqft = property.squareFeet;

    final hasCents = cents?.isNotEmpty == true && cents != "0";
    final hasAcres = acres?.isNotEmpty == true && acres != "0";
    final hasSqft = sqft?.isNotEmpty == true && sqft != "0";

    // If both cents and acres are 0 (or empty), show square feet
    if (!hasCents && !hasAcres && hasSqft) {
      return '📏: $sqft sq ft';
    }
    // If only cents has value, show cents
    else if (hasCents && !hasAcres) {
      return '📏: $cents cents';
    }
    // If only acres has value, show acres
    else if (hasAcres && !hasCents) {
      return '📏: $acres acres';
    }
    // If both cents and acres have values, show both
    else if (hasCents && hasAcres) {
      return '📏: $acres acres, $cents cents';
    }
    // Fallback to square feet if available
    else if (hasSqft) {
      return '📏: $sqft sq ft';
    }

    return '📏: Area not specified';
  }

  // Helper method to format price with Indian rupee conventions
  // NEW _formatPrice2 method - formats 1000+ as K, L, Cr
  String _formatPrice2(String? price) {
    if (price == null || price.isEmpty) {
      return 'N/A';
    }

    // Remove all commas and spaces from the input price
    String cleanPrice = price.replaceAll(',', '').replaceAll(' ', '');

    // Try to parse the cleaned price as a number
    final numPrice = int.tryParse(cleanPrice);
    if (numPrice == null) {
      return price; // Return as-is if not a valid number
    }

    // Format with K, L, Cr system
    if (numPrice >= 10000000) {
      // 1 crore and above
      final crores = numPrice / 10000000;
      if (crores == crores.toInt()) {
        return '₹${crores.toInt()}Cr';
      } else {
        return '₹${crores.toStringAsFixed(1)}Cr';
      }
    } else if (numPrice >= 100000) {
      // 1 lakh and above
      final lakhs = numPrice / 100000;
      if (lakhs == lakhs.toInt()) {
        return '₹${lakhs.toInt()}L';
      } else {
        return '₹${lakhs.toStringAsFixed(1)}L';
      }
    } else if (numPrice >= 1000) {
      // 1,000 and above (but less than 1 lakh) - format as K
      final thousands = numPrice / 1000;
      if (thousands == thousands.toInt()) {
        return '₹${thousands.toInt()}K';
      } else {
        return '₹${thousands.toStringAsFixed(1)}K';
      }
    } else {
      // For amounts less than 1,000, no formatting needed
      return '₹$numPrice';
    }
  }

  // Helper method to format price with Indian rupee conventions
  String _formatPrice(String? price) {
    if (price == null || price.isEmpty) {
      return 'N/A';
    }

    // Remove all commas and spaces from the input price
    String cleanPrice = price.replaceAll(',', '').replaceAll(' ', '');

    // Try to parse the cleaned price as a number
    final numPrice = int.tryParse(cleanPrice);
    if (numPrice == null) {
      return price; // Return as-is if not a valid number
    }

    // Format with Indian numbering system (lakhs, crores)
    if (numPrice >= 10000000) {
      // 1 crore and above
      final crores = numPrice / 10000000;
      if (crores == crores.toInt()) {
        return '₹${crores.toInt()} Cr';
      } else {
        return '₹${crores.toStringAsFixed(1)} Cr';
      }
    } else if (numPrice >= 100000) {
      // 1 lakh and above
      final lakhs = numPrice / 100000;
      if (lakhs == lakhs.toInt()) {
        return '₹${lakhs.toInt()} L';
      } else {
        return '₹${lakhs.toStringAsFixed(1)} L';
      }
    } else if (numPrice >= 1000) {
      // For amounts 1,000 and above (but less than 1 lakh), use Indian comma formatting
      return '₹${_addIndianCommas(numPrice)}';
    } else {
      // For amounts less than 1,000, no commas needed
      return '₹$numPrice';
    }
  }

  // Helper method to add commas for Indian numbering system
  String _addIndianCommas(int number) {
    String numStr = number.toString();

    if (numStr.length <= 3) {
      return numStr;
    }

    // For Indian numbering: last 3 digits, then groups of 2
    String result = '';
    int digitCount = 0;

    // Process from right to left
    for (int i = numStr.length - 1; i >= 0; i--) {
      if (digitCount == 3 || (digitCount > 3 && (digitCount - 3) % 2 == 0)) {
        result = ',' + result;
      }
      result = numStr[i] + result;
      digitCount++;
    }

    return result;
  }

  // Loading state widget
  Widget _buildLoadingPropertyInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildShimmerRow(), const SizedBox(height: 3), _buildShimmerRow(), const SizedBox(height: 3), _buildShimmerRow()],
      ),
    );
  }

  // Error state widget
  Widget _buildErrorPropertyInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 12, color: Colors.red),
          const SizedBox(width: 4),
          Expanded(child: Text('Error loading properties', style: TextStyle(fontSize: 10, color: Colors.red[700]))),
        ],
      ),
    );
  }

  // Shimmer loading row
  Widget _buildShimmerRow() {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Expanded(child: Container(height: 8, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
      ],
    );
  }

  // Updated method to include click functionality
  Widget _buildNeumorphicIcon(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13), // Half of width/height for circular ripple
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: AppColors.taroGrey,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textColor, width: 0.1),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, offset: const Offset(4, 4), blurRadius: 6, spreadRadius: 1),
            const BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 6, spreadRadius: 1),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }

  // Helper methods for actions

  // Don't forget to add url_launcher dependency in pubspec.yaml:
  // dependencies:
  //   url_launcher: ^6.2.1
}
