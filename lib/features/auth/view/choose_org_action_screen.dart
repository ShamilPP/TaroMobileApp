import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'create_org_screen.dart';
import 'join_org_screen.dart';

class ChooseOrgActionScreen extends StatelessWidget {
  final String phoneNumber;
  const ChooseOrgActionScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Organization Setup", style: GoogleFonts.poppins(color: AppColors.textColor)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome! Choose how you want to get started.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            _buildButton(
              context,
              label: "🏢  Create New Organization",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateOrganizationScreen(phoneNumber: phoneNumber)),
              ),
            ),
            const SizedBox(height: 16),
            _buildButton(
              context,
              label: "🤝  Join Existing Team",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JoinOrganizationScreen(phoneNumber: phoneNumber)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
