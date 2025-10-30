import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/constants/image_constants.dart';
import 'package:taro_mobile/features/home/view/home_sreen.dart';
import 'package:taro_mobile/features/auth/controller/auth_provider.dart';
import 'features/auth/view/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isAuthChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;

    setState(() {
      _isAuthChecking = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (!authProvider.isInitialized) {
        await authProvider.initializationCompleter.future;
      }

      
      if (!mounted) return;
      

      
      if (authProvider.isLoggedIn) {
        print("Error checking auth state:");

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        return;
      }
      setState(() {
        _isAuthChecking = false;
      });
    } catch (e) {
      print("Error checking auth state: $e");
      if (mounted) {
        setState(() {
          _isAuthChecking = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.splash),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: 40),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppImages.logo, width: 208, height: 208),
                  Transform.translate(
                    offset: Offset(0, -20), 
                    child: Text(
                      'TɅRO',
                      style: GoogleFonts.inter(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: EdgeInsets.only(bottom: 60),
                child:
                    _isAuthChecking
                        ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen,
                          ),
                        )
                        : ElevatedButton(
                          onPressed: _navigateToLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Get Started',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}