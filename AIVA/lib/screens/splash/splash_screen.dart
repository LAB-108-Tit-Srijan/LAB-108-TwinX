import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: AppConstants.splashDuration),
      () => Get.offAllNamed('/onboarding'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundRadial,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AivaLogo(size: 100)
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: 24),
                  Text(AppConstants.appName, style: AppTextStyles.displayLarge)
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms),
                  const SizedBox(height: 8),
                  Text(AppConstants.tagline,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center)
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              AppConstants.teamName,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

class AivaLogo extends StatelessWidget {
  final double size;
  const AivaLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.33;
    final c1 = Offset(size.width * 0.37, size.height * 0.5);
    final c2 = Offset(size.width * 0.63, size.height * 0.5);

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    canvas.drawCircle(
      c1,
      r,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.accentPrimary, AppColors.accentSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: c1, radius: r)),
    );

    canvas.drawCircle(
      c2,
      r,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.accentSecondary, AppColors.accentPrimary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(Rect.fromCircle(center: c2, radius: r))
        ..blendMode = BlendMode.srcATop,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
