import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/screens/phone_login_screen.dart';
import '../models/onboarding_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onGetStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == onboardingData.length - 1;
    
    // Get viewport dimensions
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;
    
    // Responsive font sizes
    final titleFontSize = dvpw * 0.065; // ~6.5% of screen width
    final descFontSize = dvpw * 0.038; // ~3.8% of screen width
    final buttonFontSize = dvpw * 0.042; // ~4.2% of screen width

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Top image area (55% of screen)
          SizedBox(
            height: dvph * 0.55,
            width: dvpw,
            child: Stack(
              children: [
                // Page view for images
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) {
                    return _buildImageSection(index);
                  },
                ),

                // Navigation header overlay
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: dvpw * 0.05,
                      vertical: dvph * 0.02,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Menu icon
                        Container(
                          padding: EdgeInsets.all(dvpw * 0.03),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(dvpw * 0.03),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            size: dvpw * 0.05,
                            color: AppColors.white,
                          ),
                        ),

                        // Skip button
                        GestureDetector(
                          onTap: _onGetStarted,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: dvpw * 0.05,
                              vertical: dvph * 0.012,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(dvpw * 0.06),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.035,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom content area (45% of screen)
          Expanded(
            child: Container(
              width: dvpw,
              padding: EdgeInsets.fromLTRB(
                dvpw * 0.07,
                dvph * 0.035,
                dvpw * 0.07,
                dvph * 0.02,
              ),
              child: Column(
                children: [
                  // Title with highlighted word
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(_currentPage),
                      children: [
                        // First line of title
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            onboardingData[_currentPage].titleLine1,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(height: dvph * 0.008),
                        // Second line with highlighted word - wrapped in FittedBox
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Highlighted word with lime background
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: dvpw * 0.03,
                                  vertical: dvph * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLime,
                                  borderRadius: BorderRadius.circular(dvpw * 0.02),
                                ),
                                child: Text(
                                  onboardingData[_currentPage].highlightedWord,
                                  style: GoogleFonts.lato(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              SizedBox(width: dvpw * 0.02),
                              // Rest of the title
                              Text(
                                onboardingData[_currentPage].titleLine2,
                                style: GoogleFonts.lato(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: dvph * 0.018),

                  // Description
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      key: ValueKey('desc$_currentPage'),
                      padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
                      child: Text(
                        onboardingData[_currentPage].description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: descFontSize,
                          fontWeight: FontWeight.w400,
                          color: AppColors.gray,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(onboardingData.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: dvpw * 0.01),
                        width: isActive ? dvpw * 0.07 : dvpw * 0.02,
                        height: dvpw * 0.02,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryLime
                              : AppColors.grayLight,
                          borderRadius: BorderRadius.circular(dvpw * 0.01),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: dvph * 0.03),

                  // Action button
                  SizedBox(
                    width: dvpw,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: dvph * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(dvpw * 0.08),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Get Started' : 'Next',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.04,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Bottom safe area padding
                  SizedBox(height: MediaQuery.of(context).padding.bottom + dvph * 0.01),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(int index) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cached network image - loads from cache
          CachedNetworkImage(
            imageUrl: onboardingData[index].imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => _buildImagePlaceholder(index),
            errorWidget: (context, url, error) => _buildImagePlaceholder(index),
          ),
          // Subtle gradient overlay at bottom for smooth transition
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(int index) {
    // Beautiful gradient placeholders using the new theme
    final gradients = [
      [AppColors.primaryDark, const Color(0xFF2D3A42)],
      [AppColors.purple, const Color(0xFFB794F6)],
      [AppColors.primaryLime, const Color(0xFFD4FF6B)],
    ];

    final icons = [
      Icons.menu_book_rounded,
      Icons.trending_up_rounded,
      Icons.groups_rounded,
    ];

    final iconColors = [
      AppColors.primaryLime,
      AppColors.white,
      AppColors.primaryDark,
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradients[index],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColors[index].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icons[index],
                size: 64,
                color: iconColors[index],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryLime,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                'AIVA',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
