import 'package:flutter/material.dart';
import 'package:taro_mobile/core/constants/colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({Key? key, required this.selectedIndex, required this.onItemSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: Offset(0, -2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', index: 0),
          _buildNavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Leads', index: 1),
          _buildNavItem(icon: Icons.apartment_outlined, selectedIcon: Icons.apartment, label: 'Properties', index: 2),
          _buildNavItem(icon: Icons.task_outlined, selectedIcon: Icons.task, label: 'Tasks', index: 3),
          _buildNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', index: 4),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required IconData selectedIcon, required String label, required int index}) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selectedIcon : icon, color: isSelected ? AppColors.primaryGreen : Colors.grey[400], size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryGreen : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
