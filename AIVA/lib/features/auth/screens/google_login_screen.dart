import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/login_api_service.dart';
import '../../home/screens/home_screen.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Retry sending stats if previous attempt failed
    LoginApiService.retryIfPending();
  }

  void _onGoogleSignIn() {
    setState(() => _isLoading = true);
    
    // Simulate Google Sign In - Coming Soon
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      
      // Navigate to home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    });
  }

  void _skipForNow() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dvpw * 0.07),
          child: Column(
            children: [
              SizedBox(height: dvph * 0.02),
              
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(dvpw * 0.03),
                    decoration: BoxDecoration(
                      color: AppColors.lightBg,
                      borderRadius: BorderRadius.circular(dvpw * 0.03),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: dvpw * 0.05,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Google icon with animation
              Container(
                width: dvpw * 0.35,
                height: dvpw * 0.35,
                decoration: BoxDecoration(
                  color: AppColors.lightBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grayLight.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: dvpw * 0.2,
                    height: dvpw * 0.2,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.grayLight.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: dvph * 0.04),
              
              // Title
              Text(
                'Connect with',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.055,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray,
                ),
              ),
              SizedBox(height: dvph * 0.008),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: dvpw * 0.03,
                      vertical: dvph * 0.006,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLime,
                      borderRadius: BorderRadius.circular(dvpw * 0.02),
                    ),
                    child: Text(
                      'Google',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.07,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: dvph * 0.02),
              
              // Coming Soon badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dvpw * 0.04,
                  vertical: dvph * 0.008,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(dvpw * 0.05),
                  border: Border.all(
                    color: AppColors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: dvpw * 0.04,
                      color: AppColors.orange,
                    ),
                    SizedBox(width: dvpw * 0.02),
                    Text(
                      'Coming Soon',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.035,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: dvph * 0.025),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: dvpw * 0.08),
                child: Text(
                  'Link your Google account to sync your data across devices and access premium features.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.038,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gray,
                    height: 1.5,
                  ),
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Google Sign In button
              SizedBox(
                width: dvpw,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.grayLight,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: dvph * 0.018),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(dvpw * 0.04),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: dvpw * 0.055,
                          height: dvpw * 0.055,
                          child: const CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(dvpw * 0.012),
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                'G',
                                style: GoogleFonts.lato(
                                  fontSize: dvpw * 0.035,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            SizedBox(width: dvpw * 0.025),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.038,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              SizedBox(height: dvph * 0.02),
              
              // Skip button
              TextButton(
                onPressed: _skipForNow,
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.04,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray,
                  ),
                ),
              ),
              
              SizedBox(height: dvph * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}

