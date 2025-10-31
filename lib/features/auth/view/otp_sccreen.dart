import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/home/view/home_sreen.dart';
import 'package:taro_mobile/features/auth/controller/auth_provider.dart';
import 'package:taro_mobile/features/auth/view/registration_page.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String currentText = "";
  bool hasError = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F9FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    margin: EdgeInsets.only(top: 10.0, left: 0),
                    transform: Matrix4.translationValues(-10.0, 0.0, 0.0),
                    child: NeumorphicButton(
                      onPressed: () => Navigator.pop(context),
                      style: NeumorphicStyle(
                        shape: NeumorphicShape.convex,
                        boxShape: NeumorphicBoxShape.circle(),
                        depth: 4,
                        intensity: 0.8,
                        lightSource: LightSource.topLeft,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.taroBlack,
                        size: 18,
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.security_rounded,
                        size: 50,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  
                  Text(
                    "Verification",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 15),

                  
                  Text(
                    "Enter the 6-digit code sent to",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 8),

                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "+91 ${widget.phoneNumber}",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.edit, size: 16, color: Colors.grey),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.05),

                  
                  Form(
                    key: formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: PinCodeTextField(
                        appContext: context,
                        length: 6,
                        obscureText: false,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 55,
                          fieldWidth: 45,
                          activeFillColor: Colors.white,
                          inactiveFillColor: Colors.white,
                          selectedFillColor: Colors.white,
                          activeColor: AppColors.primaryGreen,
                          inactiveColor: Colors.grey.shade300,
                          selectedColor: AppColors.primaryGreen,
                        ),
                        cursorColor: AppColors.primaryGreen,
                        animationDuration: Duration(milliseconds: 300),
                        enableActiveFill: true,
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        boxShadows: [
                          BoxShadow(
                            offset: Offset(0, 2),
                            color: Colors.black12,
                            blurRadius: 10,
                          ),
                        ],
                        onCompleted: (v) {
                          
                          print("Completed: $v");
                        },
                        onChanged: (value) {
                          setState(() {
                            currentText = value;
                            hasError = false;
                          });
                        },
                        beforeTextPaste: (text) {
                          return text != null &&
                              text.length == 6 &&
                              int.tryParse(text) != null;
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  
                  Visibility(
                    visible: hasError,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        "Please enter a valid OTP",
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive OTP? ",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            authProvider.canResend
                                ? () {
                                  try {
                                    authProvider.sendOTP(
                                      widget.phoneNumber,
                                      (_, __) {},
                                      (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Error resending OTP: ${e.toString()}",
                                            ),
                                            backgroundColor:
                                                Colors.red.shade700,
                                          ),
                                        );
                                      },
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Error: $e"),
                                        backgroundColor: Colors.red.shade700,
                                      ),
                                    );
                                  }
                                }
                                : null,
                        child: Text(
                          authProvider.canResend
                              ? "Resend OTP"
                              : "Resend in ${authProvider.formatTime(authProvider.remainingSeconds)}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                authProvider.canResend
                                    ? AppColors.primaryGreen
                                    : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.06),

                  
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          authProvider.isLoading
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  if (currentText.length != 6) {
                                    setState(() {
                                      hasError = true;
                                    });
                                  } else {
                                    setState(() {
                                      hasError = false;
                                    });

                                    try {
                                      await authProvider.verifyOTP(currentText);
                                      final phoneNumber = widget.phoneNumber;

                                      // Check if user needs to complete registration
                                      // Backend user is already created, but might need profile completion
                                      if (authProvider.needsRegistration) {
                                        _navigateToRegistrationScreen(
                                          phoneNumber,
                                        );
                                      } else {
                                        await authProvider.refreshUserData();
                                        _navigateToHomeScreen();
                                      }
                                    } catch (e) {
                                      setState(() {
                                        hasError = true;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Invalid OTP. Please try again.",
                                          ),
                                          backgroundColor: Colors.red.shade700,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.primaryGreen.withOpacity(0.5),
                      ),
                      child:
                          authProvider.isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Verify",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHomeScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false,
    );
  }

  void _navigateToRegistrationScreen(String phoneNumber) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => RegistrationScreen(prefillPhoneNumber: phoneNumber),
      ),
      (route) => false,
    );
  }
}