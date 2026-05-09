import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Navigate after splash
    _navigateToOnboarding();
  }

  Future<void> _navigateToOnboarding() async {
    // Ensure minimum splash duration of 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false, // Allow content behind status bar
        bottom: true, // Keep bottom content in safe area
        child: SizedBox(
          width: dvpw,
          height: dvph,
          child: Column(
            children: [
              // Main content - centered logo
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App Logo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(dvpw * 0.06),
                                child: Image.asset(
                                  'assets/images/app_splash.png',
                                  width: dvpw * 0.50,
                                  height: dvpw * 0.50,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback if logo not found
                                    return Container(
                                      width: dvpw * 0.22,
                                      height: dvpw * 0.22,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLime,
                                        borderRadius: BorderRadius.circular(dvpw * 0.055),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.auto_awesome_rounded,
                                          size: dvpw * 0.11,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              SizedBox(height: dvph * 0.05),
                              
                              // App name
                              // Text(
                              //   'AIVA',
                              //   style: GoogleFonts.lato(
                              //     fontSize: dvpw * 0.09,
                              //     fontWeight: FontWeight.w800,
                              //     color: AppColors.primaryDark,
                              //     letterSpacing: 3,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Bottom branding - inside SafeArea
              Padding(
                padding: EdgeInsets.only(bottom: dvph * 0.03),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'from',
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.03,
                              fontWeight: FontWeight.w400,
                              color: AppColors.gray,
                            ),
                          ),
                          SizedBox(height: dvph * 0.005),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: dvpw * 0.045,
                                height: dvpw * 0.045,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(dvpw * 0.01),
                                ),
                                child: Center(
                                  child: Text(
                                    'T',
                                    style: GoogleFonts.lato(
                                      fontSize: dvpw * 0.025,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryLime,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: dvpw * 0.015),
                              Text(
                                'Team TwinX',
                                style: GoogleFonts.lato(
                                  fontSize: dvpw * 0.035,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
