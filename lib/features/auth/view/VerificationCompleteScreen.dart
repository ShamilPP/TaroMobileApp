import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/view/home_sreen.dart' as nav;
import 'package:taro_mobile/features/auth/view/choose_org_action_screen.dart';
import 'package:taro_mobile/features/auth/repository/user_repository.dart';

class VerificationCompleteScreen extends StatefulWidget {
  final String phoneNumber;

  const VerificationCompleteScreen({super.key, required this.phoneNumber});

  @override
  State<VerificationCompleteScreen> createState() => _VerificationCompleteScreenState();
}

class _VerificationCompleteScreenState extends State<VerificationCompleteScreen> {
  final UserRepository _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2)); // Show success animation briefly

    if (!mounted) return;

    try {
      // Get user profile from API to check if user has organization
      final user = await _userRepo.getProfile();

      if (!mounted) return;

      // Check if user has an organization (using orgId)
      if (user.orgId != null && user.orgId!.isNotEmpty) {
        // Existing user with org → Navigate to home
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => nav.MainNavigationScreen()), (route) => false);
      } else {
        // New user without org → Show organization selection
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => ChooseOrgActionScreen(phoneNumber: widget.phoneNumber)), (route) => false);
      }
    } catch (e) {
      // If API call fails, assume new user and show org selection
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => ChooseOrgActionScreen(phoneNumber: widget.phoneNumber)), (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('assets/animations/success.json', repeat: false, height: 150),
              const SizedBox(height: 30),
              Text("Verification Complete!", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
              const SizedBox(height: 10),
              Text("You're successfully verified. Redirecting...", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }
}
