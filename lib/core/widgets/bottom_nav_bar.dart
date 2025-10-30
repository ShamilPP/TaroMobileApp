import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/constants/image_constants.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  // Check if cutout should be shown (only for index 0 and 1)
  bool get _shouldShowCutout => selectedIndex == 0 || selectedIndex == 1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: CustomNavBarPainter(showCutout: _shouldShowCutout),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    defaultIcon: AppImages.houseIcon,
                    selectedIcon: AppImages.homeSelected,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildNavItem(
                    defaultIcon: AppImages.taskIcon,
                    selectedIcon:
                        AppImages
                            .taskIcon, // replace if you have a selected version
                    label: 'Tasks',
                    index: 1,
                  ),

                  // Conditionally show spacing for FAB
                  SizedBox(width: _shouldShowCutout ? 60 : 0),

                  _buildNavItem(
                    defaultIcon: AppImages.downloadIcon,
                    selectedIcon: AppImages.eSignIcon,
                    label: 'eSign',
                    index: 2,
                  ),
                  _buildNavItem(
                    defaultIcon: AppImages.profileIcon,
                    selectedIcon: AppImages.profileSelected,
                    label: 'Profile',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String defaultIcon,
    required String selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onItemSelected(index),
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            isSelected ? selectedIcon : defaultIcon,
            height: 22,
            width: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.textColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomNavBarPainter extends CustomPainter {
  final bool showCutout;

  const CustomNavBarPainter({this.showCutout = true});

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    final cornerRadius = 0.0;

    if (showCutout) {
      // Draw navbar with cutout for FAB
      _drawNavBarWithCutout(canvas, size, height, width, cornerRadius);
    } else {
      // Draw simple navbar without cutout
      _drawSimpleNavBar(canvas, size, height, width, cornerRadius);
    }
  }

  void _drawNavBarWithCutout(
    Canvas canvas,
    Size size,
    double height,
    double width,
    double cornerRadius,
  ) {
    final centerWidth = width / 2;
    final fabRadius = 30.0;
    final cutoutRadius = 32.0;

    final mainPath = Path();

    mainPath.moveTo(0, height);
    mainPath.lineTo(0, cornerRadius);
    mainPath.quadraticBezierTo(0, 0, cornerRadius, 0);
    mainPath.lineTo(centerWidth - fabRadius - 10, 0);

    mainPath.arcToPoint(
      Offset(centerWidth + fabRadius + 10, 0),
      radius: Radius.circular(fabRadius),
      clockwise: false,
    );

    mainPath.lineTo(width - cornerRadius, 0);
    mainPath.quadraticBezierTo(width, 0, width, cornerRadius);
    mainPath.lineTo(width, height);
    mainPath.lineTo(0, height);

    final cutoutPath = Path();
    cutoutPath.addOval(
      Rect.fromCircle(center: Offset(centerWidth, -5), radius: cutoutRadius),
    );

    final finalPath = Path.combine(
      PathOperation.difference,
      mainPath,
      cutoutPath,
    );

    final backgroundPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawPath(finalPath, backgroundPaint);

    final borderPaint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    canvas.drawPath(finalPath, borderPaint);
  }

  void _drawSimpleNavBar(
    Canvas canvas,
    Size size,
    double height,
    double width,
    double cornerRadius,
  ) {
    final path = Path();

    // Simple rectangle with rounded top corners
    path.moveTo(0, height);
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.lineTo(width - cornerRadius, 0);
    path.quadraticBezierTo(width, 0, width, cornerRadius);
    path.lineTo(width, height);
    path.lineTo(0, height);

    final backgroundPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawPath(path, backgroundPaint);

    // No border for simple navbar - completely clean look
  }

  @override
  bool shouldRepaint(covariant CustomNavBarPainter oldDelegate) {
    return oldDelegate.showCutout != showCutout;
  }
}

// Alternative version with smoother transitions
class CustomBottomNavBarAnimated extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBarAnimated({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  bool get _shouldShowCutout => selectedIndex == 0 || selectedIndex == 1;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 70,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: CustomNavBarPainter(showCutout: _shouldShowCutout),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    defaultIcon: AppImages.houseIcon,
                    selectedIcon: AppImages.homeSelected,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildNavItem(
                    defaultIcon: AppImages.taskIcon,
                    selectedIcon: AppImages.taskIcon,
                    label: 'Tasks',
                    index: 1,
                  ),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _shouldShowCutout ? 60 : 0,
                  ),

                  _buildNavItem(
                    defaultIcon: AppImages.downloadIcon,
                    selectedIcon: AppImages.eSignIcon,
                    label: 'eSign',
                    index: 2,
                  ),
                  _buildNavItem(
                    defaultIcon: AppImages.profileIcon,
                    selectedIcon: AppImages.profileSelected,
                    label: 'Profile',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String defaultIcon,
    required String selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onItemSelected(index),
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            isSelected ? selectedIcon : defaultIcon,
            height: 22,
            width: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.textColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
