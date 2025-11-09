import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/constants/image_constants.dart';
import 'package:taro_mobile/features/auth/controller/auth_provider.dart';
import 'package:taro_mobile/features/auth/view/login_screen.dart';
import 'package:taro_mobile/features/auth/view/choose_org_action_screen.dart';
import 'package:taro_mobile/features/auth/repository/user_repository.dart';
import 'package:taro_mobile/features/home/view/home_sreen.dart' as nav;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isAuthChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthState());
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;

    setState(() => _isAuthChecking = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Wait for initialization safely
      await authProvider.ensureInitialized();

      if (!mounted) return;

      if (authProvider.isLoggedIn) {
        // ✅ User is logged in → Check if they have an organization
        final user = firebase_auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final userRepo = UserRepository();
            final userProfile = await userRepo.getProfile();

            if (!mounted) return;

            // Check if user has an organization (using orgId)
            if (userProfile.orgId != null && userProfile.orgId!.isNotEmpty) {
              // User has org → Navigate to Home
              _navigateToScreen(const nav.MainNavigationScreen());
            } else {
              // User logged in but no org → Show organization selection
              final phoneNumber = user.phoneNumber ?? '';
              _navigateToScreen(ChooseOrgActionScreen(phoneNumber: phoneNumber));
            }
          } catch (e) {
            debugPrint("❌ Error checking user org: $e");
            // On error, assume user has org and go to home
            if (mounted) {
              _navigateToScreen(const nav.MainNavigationScreen());
            }
          }
        } else {
          // User not found, go to login
          if (mounted) setState(() => _isAuthChecking = false);
        }
      } else {
        // ⏳ Not logged in → Show "Get Started"
        setState(() => _isAuthChecking = false);
      }
    } catch (e) {
      debugPrint("❌ Error checking auth state: $e");
      if (mounted) setState(() => _isAuthChecking = false);
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _navigateToLogin() => _navigateToScreen(LoginScreen());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage(AppImages.splash), fit: BoxFit.cover)),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              /// Logo + App Name
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppImages.logo, width: 208, height: 208),
                  Transform.translate(offset: const Offset(0, -20), child: Text('TɅRO', style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white))),
                ],
              ),

              /// Loading or “Get Started” button
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child:
                    _isAuthChecking
                        ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen))
                        : ElevatedButton(
                          onPressed: _navigateToLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Get Started', style: TextStyle(fontSize: 18)),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
