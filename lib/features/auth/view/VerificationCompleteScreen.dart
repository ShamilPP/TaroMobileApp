import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/view/home_sreen.dart';
import 'package:taro_mobile/features/auth/controller/auth_provider.dart';
import 'package:taro_mobile/features/auth/view/choose_org_action_screen.dart';
import 'package:provider/provider.dart';

class VerificationCompleteScreen extends StatefulWidget {
  final String phoneNumber;

  const VerificationCompleteScreen({super.key, required this.phoneNumber});

  @override
  State<VerificationCompleteScreen> createState() => _VerificationCompleteScreenState();
}

class _VerificationCompleteScreenState extends State<VerificationCompleteScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await Future.delayed(const Duration(seconds: 2)); // Show success animation briefly

    final user = await authProvider.verifyPhoneWithBackend(widget.phoneNumber);

    if (!mounted) return;

    if (user != null && user.orgId != null) {
      // Existing user with org
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
      );
    } else {
      // New user, needs org setup
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ChooseOrgActionScreen(phoneNumber: widget.phoneNumber)),
            (route) => false,
      );
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
              Lottie.asset(
                'assets/animations/success.json',
                repeat: false,
                height: 150,
              ),
              const SizedBox(height: 30),
              Text(
                "Verification Complete!",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You're successfully verified. Redirecting...",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
