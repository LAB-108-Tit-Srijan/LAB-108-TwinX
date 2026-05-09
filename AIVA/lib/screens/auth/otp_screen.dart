import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/gradient_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  final _auth = Get.find<AuthController>();
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _auth.startResendTimer();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final f in _nodes) f.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onChange(String v, int i) {
    if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
    final otp = _ctrls.map((c) => c.text).join();
    if (otp.length == 6) _auth.verifyOtp(otp);
  }

  String get _maskedPhone {
    final p = _auth.phoneNumber.value;
    if (p.length >= 4) {
      return '+91 ••••••${p.substring(p.length - 4)}';
    }
    return '+91 ••••••••••';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
                onPressed: Get.back,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              Text('Verify OTP', style: AppTextStyles.displayMedium)
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Obx(() => Text('Sent to $_maskedPhone',
                      style: AppTextStyles.bodyMedium)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)),
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(
                    _shakeAnim.value *
                        ((_shakeCtrl.value * 10).round().isEven ? 1 : -1),
                    0,
                  ),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (i) => _OtpBox(
                      controller: _ctrls[i],
                      focusNode: _nodes[i],
                      onChanged: (v) => _onChange(v, i),
                      onBackspace: () {
                        if (_ctrls[i].text.isEmpty && i > 0) {
                          _nodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 32),
              Center(
                child: Obx(() => _auth.resendTimer.value > 0
                    ? Text(
                        'Resend in ${_auth.resendTimer.value}s',
                        style: AppTextStyles.bodyMedium,
                      )
                    : TextButton(
                        onPressed: () {
                          _auth.startResendTimer();
                          for (final c in _ctrls) c.clear();
                          _nodes[0].requestFocus();
                        },
                        child: Text('Resend OTP',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.accentPrimary,
                                fontWeight: FontWeight.w600)),
                      )),
              ),
              const SizedBox(height: 32),
              Obx(() => GradientButton(
                    text: 'Verify',
                    isLoading: _auth.isLoading.value,
                    onTap: () {
                      final otp = _ctrls.map((c) => c.text).join();
                      if (otp.length == 6) {
                        _auth.verifyOtp(otp);
                      } else {
                        _shakeCtrl.forward(from: 0);
                        Get.snackbar(
                          'Incomplete OTP',
                          'Please enter all 6 digits',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      }
                    },
                  )).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Hint: enter 123456',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ).animate().fadeIn(delay: 500.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        onChanged: onChanged,
        style: AppTextStyles.headingMedium
            .copyWith(color: AppColors.accentPrimary),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.backgroundSecondary,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.accentPrimary, width: 2),
          ),
        ),
      ),
    );
  }
}
