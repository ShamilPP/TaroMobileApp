import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/view/home_screen.dart' as dashboard;
import 'package:taro_mobile/features/home/view/leads_list_screen.dart';
import 'package:taro_mobile/features/lead/add_lead_controller.dart';
import 'package:taro_mobile/features/lead/add_lead_screen.dart';
import 'package:taro_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:taro_mobile/features/auth/view/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isSelectionMode = false; // Track selection mode state

  List<Widget> get _pages => [
    const dashboard.HomeScreen(), // Dashboard/Home
    LeadsListScreen(onProfileTap: _navigateToProfile, onSelectionModeChanged: _onSelectionModeChanged), // Leads
    const Center(child: Text('Properties\nComing Soon', textAlign: TextAlign.center)), // Properties
    const Center(child: Text('Tasks\nComing Soon', textAlign: TextAlign.center)), // Tasks
    ProfileScreen(), // Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProfile() {
    setState(() {
      _selectedIndex = 4; // Profile is now at index 4
    });
  }

  // Callback to handle selection mode changes from LeadsView
  void _onSelectionModeChanged(bool isSelectionMode) {
    setState(() {
      _isSelectionMode = isSelectionMode;
    });
  }

  // Check if FAB should be shown (only for Leads screen)
  bool get _shouldShowFAB {
    return !_isSelectionMode && _selectedIndex == 1; // Only show on Leads tab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,

      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, toolbarHeight: 0, automaticallyImplyLeading: false),
      body: Container(color: Colors.white, child: SafeArea(bottom: false, child: _pages[_selectedIndex])),

      // Show FAB only for Leads screen (index 1)
      floatingActionButton:
          _shouldShowFAB
              ? FloatingActionButton(
                onPressed: () {
                  // Add Lead
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChangeNotifierProvider<NewLeadProvider>(create: (_) => NewLeadProvider(), child: const NewLeadFormScreen())),
                  );
                },
                backgroundColor: AppColors.primaryGreen,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Hide bottom navigation bar during selection mode
      bottomNavigationBar: _isSelectionMode ? null : CustomBottomNavBar(selectedIndex: _selectedIndex, onItemSelected: _onItemTapped),
    );
  }
}
