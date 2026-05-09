import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/gradient_button.dart';
import '../splash/splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _auth = Get.find<AuthController>();
  bool _focused = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          CustomPaint(
            painter: _DotGridPainter(),
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AivaLogo(size: 40)
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(width: 12),
                      Text('AIVA',
                          style: AppTextStyles.headingLarge
                              .copyWith(fontSize: 22))
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 600.ms),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text('Welcome back', style: AppTextStyles.displayMedium)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your phone number to continue',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  const SizedBox(height: 48),
                  FocusScope(
                    child: Focus(
                      onFocusChange: (f) => setState(() => _focused = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _focused
                                ? AppColors.accentPrimary
                                : AppColors.borderColor,
                            width: _focused ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: AppColors.borderColor),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text('🇮🇳',
                                      style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text('+91',
                                      style: AppTextStyles.labelLarge),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                style: AppTextStyles.bodyLarge,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '9876543210',
                                  counterText: '',
                                  filled: false,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  const SizedBox(height: 24),
                  Obx(() => GradientButton(
                        text: 'Send OTP',
                        isLoading: _auth.isLoading.value,
                        onTap: () {
                          if (_phoneCtrl.text.length == 10) {
                            _auth.sendOtp(_phoneCtrl.text);
                            Get.toNamed('/otp');
                          } else {
                            Get.snackbar(
                              'Invalid Number',
                              'Enter a valid 10-digit phone number',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: AppColors.error,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 12,
                            );
                          }
                        },
                      )).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  const SizedBox(height: 24),
                  Text(
                    'By continuing you agree to our Terms of Service\nand Privacy Policy',
                    style: AppTextStyles.hint,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
