import 'package:flutter/material.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF06925A);
  static const Color taroBlack = Color.fromARGB(255, 0, 0, 0);
  static const Color textColor = Color(0xFF1F4C6B);
  static const Color taroGrey = Color(0xFFF5F4F8);
  static const Color primaryDarkBlue = Color(0xFF53587A);
}

const TextStyle propertyTextStyle = TextStyle(
  fontFamily: 'Lato',
  fontWeight: FontWeight.w600,
  fontSize: 11,
  height: 2.0,
  letterSpacing: 0.03,
  color: AppColors.primaryDarkBlue,
);

class AppFonts {
  static const String inter = 'Inter';

  // Text styles with Inter font
  static const TextStyle interDefault = TextStyle(fontFamily: inter);
  static const TextStyle interBold = TextStyle(
    fontFamily: inter,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle interSemiBold = TextStyle(
    fontFamily: inter,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle interMedium = TextStyle(
    fontFamily: inter,
    fontWeight: FontWeight.w500,
  );
}

class AvatarColorUtils {
  static Color _getAvatarColor(String leadType, {String? uniqueId}) {
    // Use current timestamp or provided unique ID
    final seed = uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final combined = '$leadType-$seed';

    int hash = combined.hashCode.abs();
    double hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  static Color getAvatarColor(String leadType, {String? uniqueId}) {
    return _getAvatarColor(leadType, uniqueId: uniqueId);
  }

  static Color getAvatarColorFromLead(LeadModel lead) {
    // If lead already has a saved color, use it
    if (lead.avatarColor != null) {
      return lead.avatarColor!;
    }

    // Otherwise, generate based on lead type and lead ID for consistency
    return _getAvatarColor(lead.leadType, uniqueId: lead.id);
  }

  // Method to generate and save avatar color for new leads
  static Color generateAndSaveAvatarColor(LeadModel lead) {
    if (lead.avatarColor != null) {
      return lead.avatarColor!;
    }

    // Generate color using lead ID as unique identifier
    return _getAvatarColor(lead.leadType, uniqueId: lead.id);
  }
}
