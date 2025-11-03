import 'package:flutter/material.dart';
import 'package:taro_mobile/core/constants/colors.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime _currentDate = DateTime(2025, 10, 1);
  DateTime _selectedDate = DateTime(2025, 10, 26);

  List<String> _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  void _navigateMonth(bool forward) {
    setState(() {
      if (forward) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      } else {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      }
    });
  }

  List<DateTime?> _getMonthDates() {
    List<DateTime?> dates = [];

    // Get first day of the month
    DateTime firstDay = DateTime(_currentDate.year, _currentDate.month, 1);
    // Convert weekday: Dart's weekday is 1=Monday, 7=Sunday
    // We need 0=Sunday, 1=Monday, ..., 6=Saturday
    int firstWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday;

    // Get last day of the month
    int lastDay = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

    // Get previous month's last day to fill empty cells
    DateTime prevMonthLastDay = DateTime(_currentDate.year, _currentDate.month, 0);
    int prevMonthDays = prevMonthLastDay.day;

    // Add empty cells for days before the first day of the month (from previous month)
    for (int i = firstWeekday - 1; i >= 0; i--) {
      dates.add(DateTime(_currentDate.year, _currentDate.month - 1, prevMonthDays - i));
    }

    // Add all days of the current month
    for (int i = 1; i <= lastDay; i++) {
      dates.add(DateTime(_currentDate.year, _currentDate.month, i));
    }

    // Fill remaining cells to make 6 weeks (42 days total)
    int remaining = 42 - dates.length;
    for (int i = 1; i <= remaining; i++) {
      dates.add(DateTime(_currentDate.year, _currentDate.month + 1, i));
    }

    return dates;
  }

  void _selectDate(DateTime date) {
    if (date.month == _currentDate.month) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Green Header
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Calendar Section
                    _buildCalendarSection(),

                    // Today's Tasks Section
                    _buildTasksSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tasks & Reminders', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lato')),
          SizedBox(height: 8),
          Text('Stay on top of your schedule.', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), fontFamily: 'Lato')),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    List<DateTime?> monthDates = _getMonthDates();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month and Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthNames[_currentDate.month - 1]} ${_currentDate.year}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Lato'),
              ),
              Row(
                children: [
                  GestureDetector(onTap: () => _navigateMonth(false), child: Icon(Icons.chevron_left, color: Colors.black, size: 24)),
                  SizedBox(width: 16),
                  GestureDetector(onTap: () => _navigateMonth(true), child: Icon(Icons.chevron_right, color: Colors.black, size: 24)),
                ],
              ),
            ],
          ),

          SizedBox(height: 16),

          // Days of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                _dayNames.map((day) {
                  return Expanded(child: Center(child: Text(day, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'Lato'))));
                }).toList(),
          ),

          SizedBox(height: 12),

          // Calendar Grid - Limit to 6 weeks (42 items) max
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.0, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: monthDates.length > 42 ? 42 : monthDates.length,
            itemBuilder: (context, index) {
              DateTime? date = monthDates[index];
              if (date == null) {
                return Container();
              }

              bool isCurrentMonth = date.month == _currentDate.month;
              bool isSelected = isCurrentMonth && date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;

              return GestureDetector(
                onTap: () => _selectDate(date),
                child: Container(
                  decoration: BoxDecoration(color: isSelected ? AppColors.primaryGreen : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected
                                ? Colors.white
                                : isCurrentMonth
                                ? Colors.black
                                : Colors.grey[300],
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Tasks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Lato')),
              Text('1/4 completed', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontFamily: 'Lato')),
            ],
          ),

          SizedBox(height: 16),

          // Task Cards - Scrollable
          Column(
            children: [
              _buildTaskCard(
                title: 'Site visit with Mr. Sharma',
                subtitle: 'Show 3BHK apartment in Powai',
                time: '10:30 AM',
                tag: 'Site Visit',
                lead: 'Lead: Mr. Rajesh Sharma',
                property: 'Property: Spacious 3BHK with Lake View',
                icon: Icons.home,
                isCompleted: false,
              ),
              SizedBox(height: 12),
              _buildTaskCard(
                title: 'Agreement signing - Villa project',
                subtitle: 'Final paperwork for Lonavala villa',
                time: null,
                tag: null,
                lead: null,
                property: null,
                icon: Icons.description,
                isCompleted: false,
              ),
              SizedBox(height: 12),
              // Add some padding at bottom for better scrolling
              SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    String? time,
    String? tag,
    String? lead,
    String? property,
    required IconData icon,
    required bool isCompleted,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Container(
            margin: EdgeInsets.only(top: 2),
            child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[400]!, width: 2))),
          ),

          SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Lato')),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'Lato')),
                if (time != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'Lato')),
                      if (tag != null) ...[
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                          child: Text(tag, style: TextStyle(fontSize: 11, color: Colors.grey[700], fontFamily: 'Lato')),
                        ),
                      ],
                    ],
                  ),
                ],
                if (lead != null) ...[SizedBox(height: 6), Text(lead, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'Lato'))],
                if (property != null) ...[SizedBox(height: 4), Text(property, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'Lato'))],
              ],
            ),
          ),

          // Icon
          Container(margin: EdgeInsets.only(left: 8), child: Icon(icon, color: AppColors.primaryGreen, size: 24)),
        ],
      ),
    );
  }
}
