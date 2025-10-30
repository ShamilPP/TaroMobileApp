import 'package:flutter/material.dart';
import 'package:taro_mobile/core/constants/colors.dart';

class CustomSquareRadioOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final double size;

  const CustomSquareRadioOption({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.activeColor = AppColors.textColor,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              border: Border.all(
                color: isSelected ? activeColor : Colors.grey.shade400,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child:
                isSelected
                    ? Center(
                      child: Container(
                        width: size - 5,
                        height: size - 5,
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}