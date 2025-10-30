import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/view/lead_screen.dart';
import 'package:taro_mobile/features/lead/add_lead_controller.dart';
import 'package:taro_mobile/features/lead/add_lead_screen.dart';
import 'package:taro_mobile/features/reminder/new_reminder_screen.dart';
import 'package:taro_mobile/features/reminder/reminder_screen.dart';
import 'package:taro_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:taro_mobile/features/auth/view/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSelectionMode = false; // Track selection mode state

  List<Widget> get _pages => [
    const Center(),
    RemainderScreen(onProfileTap: _navigateToProfile),
    const Center(child: Text('Downloads')),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProfile() {
    setState(() {
      _selectedIndex = 3;
    });
  }

  // Callback to handle selection mode changes from LeadsView
  void _onSelectionModeChanged(bool isSelectionMode) {
    setState(() {
      _isSelectionMode = isSelectionMode;
    });
  }

  // Check if FAB should be shown
  bool get _shouldShowFAB {
    // Only show FAB for index 0 (Leads) and index 1 (Reminders)
    // Hide during selection mode
    return !_isSelectionMode && (_selectedIndex == 0 || _selectedIndex == 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
      ),
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child:
                    _selectedIndex == 0
                        ? LeadsView(
                          onProfileTap: _navigateToProfile,
                          onSelectionModeChanged: _onSelectionModeChanged,
                        )
                        : _pages[_selectedIndex],
              ),
            ],
          ),
        ),
      ),

      // Show FAB only for Leads (index 0) and Reminders (index 1)
      floatingActionButton:
          _shouldShowFAB
              ? FloatingActionButton(
                onPressed: () {
                  if (_selectedIndex == 0) {
                    // Add Lead
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ChangeNotifierProvider<NewLeadProvider>(
                                  create: (_) => NewLeadProvider(),
                                  child: const NewLeadFormScreen(),
                                ),
                      ),
                    );
                  } else if (_selectedIndex == 1) {
                    // Add Reminder
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewReminderScreen(),
                      ),
                    );
                  }
                },
                backgroundColor: AppColors.primaryGreen,
                elevation: 8,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Hide bottom navigation bar during selection mode
      bottomNavigationBar:
          _isSelectionMode
              ? null
              : CustomBottomNavBar(
                selectedIndex: _selectedIndex,
                onItemSelected: _onItemTapped,
              ),
    );
  }
}
