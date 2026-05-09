import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      title: 'Stuck at 11PM?',
      subtitle:
          'No instructor replies. Google gives generic answers. Your doubt stays unanswered.',
      icon: Icons.access_time_rounded,
      color1: Color(0xFF6C63FF),
      color2: Color(0xFF8B5CF6),
    ),
    _Slide(
      title: 'AIVA knows your lecture',
      subtitle:
          'Ask any doubt from any timestamp. AIVA answers from your exact lecture — not the internet.',
      icon: Icons.smart_toy_rounded,
      color1: Color(0xFF00D4FF),
      color2: Color(0xFF6C63FF),
    ),
    _Slide(
      title: 'Answer in your language',
      subtitle:
          'English lecture. Hindi explanation. Learn the way you think.',
      icon: Icons.translate_rounded,
      color1: Color(0xFF8B5CF6),
      color2: Color(0xFF00D4FF),
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: TextButton(
                  onPressed: () => Get.offAllNamed('/login'),
                  child: Text('Skip',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _slides.length,
                      effect: const WormEffect(
                        activeDotColor: AppColors.accentPrimary,
                        dotColor: AppColors.borderColor,
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: _page == _slides.length - 1
                          ? 'Get Started'
                          : 'Next  →',
                      onTap: _next,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color1;
  final Color color2;
  const _Slide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color1,
    required this.color2,
  });
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
          height: h * 0.58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: h * 0.07,
                child: Container(
                  width: w * 0.82,
                  height: h * 0.4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        slide.color1.withOpacity(0.12),
                        slide.color2.withOpacity(0.06)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [slide.color1, slide.color2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: slide.color1.withOpacity(0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(slide.icon, color: Colors.white, size: 58),
              ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              Text(slide.title,
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Text(slide.subtitle,
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary, height: 1.6),
                  textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
            ],
          ),
        ),
      ],
    );
  }
}
