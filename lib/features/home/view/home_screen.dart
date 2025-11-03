import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/controller/lead_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String firstName = 'Sharma';
  String lastName = '';

  @override
  void initState() {
    super.initState();
    // Load user data if needed
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
              children: [
                _buildDashboardHeader(context, leadProvider),
                _buildTodayScheduleSection(context),
                const SizedBox(height: 80),
              ],
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
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20,
          right: 20,
          bottom: 18,
        ),
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Lato',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      dateString,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),

            // Stats cards grid
            Row(
              children: [
                Expanded(
                  child: _buildDashboardStatCard(
                    icon: Icons.people,
                    iconColor: Color(0xFF2DD4BF),
                    value: '24',
                    label: 'Active Leads',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildDashboardStatCard(
                    icon: Icons.apartment,
                    iconColor: Color(0xFF3B82F6),
                    value: '18',
                    label: 'Active Listings',
                  ),
                ),
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

  Widget _buildDashboardStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    String? subtitle,
    Color? subtitleColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Lato',
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontFamily: 'Lato',
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: subtitleColor ?? Colors.green,
                  size: 12,
                ),
                SizedBox(width: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: subtitleColor ?? Colors.green,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                  ),
                ),
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
              Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Lato',
                ),
              ),
              Text(
                '4 tasks',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2DD4BF),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          SizedBox(height: 14),

          // Task items
          _buildTaskItem(
            title: 'Site visit with Mr. Sharma',
            time: '10:30 AM',
            category: 'Site Visit',
            isCompleted: false,
          ),
          _buildTaskItem(
            title: 'Agreement signing - Villa project',
            time: '2:00 PM',
            category: 'Signing',
            isCompleted: false,
          ),
          _buildTaskItem(
            title: 'Follow-up call with Mrs. Patel',
            time: '4:30 PM',
            category: 'Call',
            isCompleted: true,
          ),
          _buildTaskItem(
            title: 'Property inspection - Malad East',
            time: '6:00 PM',
            category: 'Inspection',
            isCompleted: false,
          ),
          SizedBox(height: 16),

          // View All Tasks button
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to tasks screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'View All Tasks',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String time,
    required String category,
    required bool isCompleted,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkmark icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.grey[300]
                  : AppColors.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.check,
              color: isCompleted ? Colors.grey[500] : AppColors.primaryGreen,
              size: 22,
            ),
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
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        color: isCompleted ? Colors.grey[400] : Colors.grey[600],
                        fontFamily: 'Lato',
                      ),
                    ),
                    Text(
                      '  •  ',
                      style: TextStyle(
                        color: isCompleted ? Colors.grey[400] : Colors.grey[400],
                      ),
                    ),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        color: isCompleted ? Colors.grey[400] : Colors.grey[600],
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

