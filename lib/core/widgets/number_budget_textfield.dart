import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat indianFormat = NumberFormat.decimalPattern('en_IN');

class IndianNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    
    if (newValue.text.isEmpty) {
      return newValue;
    }

    
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    
    if (digitsOnly.length > 12) {
      return oldValue;
    }

    
    String formatted = indianFormat.format(int.parse(digitsOnly));

    
    int cursorPosition = formatted.length;

    
    if (newValue.text.length >= oldValue.text.length) {
      cursorPosition = formatted.length;
    } else {
      
      cursorPosition = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

Widget buildFormattedPriceTextField({
  required String label,
  required String initialValue,
  required void Function(String) onChanged,
  IconData? icon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextFormField(
          initialValue: formatToIndian(initialValue),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          inputFormatters: [IndianNumberInputFormatter()],
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            suffixIcon:
                icon != null
                    ? Icon(icon, size: 20, color: Colors.grey[600])
                    : null,
          ),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

String formatToIndian(String value) {
  String digits = value.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return '';

  try {
    return indianFormat.format(int.parse(digits));
  } catch (e) {
    return '';
  }
}