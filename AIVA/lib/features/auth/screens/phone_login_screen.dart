import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'otp_verification_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+91';
  bool _isLoading = false;
  bool _isPhoneFocused = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() => _isPhoneFocused = _phoneFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final fullPhone =
          '$_selectedCountryCode${_phoneController.text.replaceAll(' ', '')}';
      try {
        final result = await AuthService.sendOtp(fullPhone);
        if (!mounted) return;
        if (result['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: '$_selectedCountryCode ${_phoneController.text}',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ??
                    result['error']?.toString() ??
                    'Failed to send OTP',
              ),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;
    final hasPhoneValue = _phoneController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dvpw * 0.07),
            child: Form(
              key: _formKey,
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
                    'Welcome to',
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.06,
                      fontWeight: FontWeight.w400,
                      color: AppColors.gray,
                    ),
                  ),
                  SizedBox(height: dvph * 0.005),
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
                          'AIVA',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.08,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      SizedBox(width: dvpw * 0.02),
                      Text(
                        '👋',
                        style: TextStyle(fontSize: dvpw * 0.08),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: dvph * 0.015),
                  
                  Text(
                    'Enter your phone number to continue',
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.038,
                      fontWeight: FontWeight.w400,
                      color: AppColors.gray,
                      height: 1.5,
                    ),
                  ),
                  
                  SizedBox(height: dvph * 0.05),
                  
                  // Phone number label
                  Text(
                    'Phone Number',
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.038,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  
                  SizedBox(height: dvph * 0.012),
                  
                  // Improved Phone input field
                  Container(
                    decoration: BoxDecoration(
                      color: _isPhoneFocused || hasPhoneValue 
                          ? AppColors.primaryLime.withOpacity(0.08)
                          : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(dvpw * 0.04),
                      border: Border.all(
                        color: _isPhoneFocused 
                            ? AppColors.primaryLime 
                            : hasPhoneValue
                                ? AppColors.primaryLime.withOpacity(0.5)
                                : AppColors.grayLight,
                        width: _isPhoneFocused ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Country code dropdown
                        GestureDetector(
                          onTap: () => _showCountryCodePicker(context, dvpw, dvph),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: dvpw * 0.04,
                              vertical: dvph * 0.02,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: _isPhoneFocused 
                                      ? AppColors.primaryLime.withOpacity(0.3)
                                      : AppColors.grayLight,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getFlagEmoji(_selectedCountryCode),
                                  style: TextStyle(fontSize: dvpw * 0.05),
                                ),
                                SizedBox(width: dvpw * 0.015),
                                Text(
                                  _selectedCountryCode,
                                  style: GoogleFonts.lato(
                                    fontSize: dvpw * 0.04,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                SizedBox(width: dvpw * 0.01),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.gray,
                                  size: dvpw * 0.05,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Phone number input
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.045,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                              letterSpacing: 1,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                              _PhoneNumberFormatter(),
                            ],
                            decoration: InputDecoration(
                              hintText: '00000 00000',
                              hintStyle: GoogleFonts.lato(
                                fontSize: dvpw * 0.042,
                                color: AppColors.gray.withOpacity(0.5),
                                letterSpacing: 1,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: dvpw * 0.04,
                                vertical: dvph * 0.02,
                              ),
                              suffixIcon: hasPhoneValue
                                  ? IconButton(
                                      onPressed: () {
                                        _phoneController.clear();
                                        setState(() {});
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: dvpw * 0.05,
                                        color: AppColors.gray,
                                      ),
                                    )
                                  : null,
                            ),
                            onChanged: (value) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              }
                              final digitsOnly = value.replaceAll(' ', '');
                              if (digitsOnly.length < 10) {
                                return 'Enter valid 10-digit phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: dvph * 0.04),
                  
                  // Continue button
                  SizedBox(
                    width: dvpw,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onContinue,
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
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Continue',
                                  style: GoogleFonts.lato(
                                    fontSize: dvpw * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: dvpw * 0.02),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: dvpw * 0.045,
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  SizedBox(height: dvph * 0.04),
                  
                  // Divider with OR
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.grayLight,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
                        child: Text(
                          'OR',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.035,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.grayLight,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: dvph * 0.04),
                  
                  // Google Sign In button with Coming Soon
                  SizedBox(
                    width: dvpw,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Google Sign In - Coming Soon!',
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.grayLight, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: dvph * 0.018),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(dvpw * 0.04),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: dvpw * 0.03),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(dvpw * 0.012),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBg,
                                  borderRadius: BorderRadius.circular(dvpw * 0.012),
                                ),
                                child: Text(
                                  'G',
                                  style: GoogleFonts.lato(
                                    fontSize: dvpw * 0.04,
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
                              SizedBox(width: dvpw * 0.015),
                              // Coming Soon badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: dvpw * 0.015,
                                  vertical: dvph * 0.003,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(dvpw * 0.01),
                                ),
                                child: Text(
                                  'Soon',
                                  style: GoogleFonts.lato(
                                    fontSize: dvpw * 0.022,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: dvph * 0.05),
                  
                  // Terms and conditions
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.032,
                          color: AppColors.gray,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'By continuing, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.032,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: '\nand '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.032,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }

  String _getFlagEmoji(String countryCode) {
    switch (countryCode) {
      case '+91':
        return '🇮🇳';
      case '+1':
        return '🇺🇸';
      case '+44':
        return '🇬🇧';
      case '+61':
        return '🇦🇺';
      case '+81':
        return '🇯🇵';
      default:
        return '🌍';
    }
  }

  void _showCountryCodePicker(BuildContext context, double dvpw, double dvph) {
    final countries = [
      {'code': '+91', 'name': 'India', 'flag': '🇮🇳'},
      {'code': '+1', 'name': 'United States', 'flag': '🇺🇸'},
      {'code': '+44', 'name': 'United Kingdom', 'flag': '🇬🇧'},
      {'code': '+61', 'name': 'Australia', 'flag': '🇦🇺'},
      {'code': '+81', 'name': 'Japan', 'flag': '🇯🇵'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(dvpw * 0.06),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(dvpw * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: dvpw * 0.1,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: dvph * 0.02),
              Text(
                'Select Country',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.05,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: dvph * 0.02),
              ...countries.map((country) {
                final isSelected = _selectedCountryCode == country['code'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCountryCode = country['code']!);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: dvpw * 0.04,
                      vertical: dvph * 0.015,
                    ),
                    margin: EdgeInsets.only(bottom: dvph * 0.01),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLime.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(dvpw * 0.03),
                      border: isSelected
                          ? Border.all(color: AppColors.primaryLime)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          country['flag']!,
                          style: TextStyle(fontSize: dvpw * 0.06),
                        ),
                        SizedBox(width: dvpw * 0.03),
                        Expanded(
                          child: Text(
                            country['name']!,
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.04,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        Text(
                          country['code']!,
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.04,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray,
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: dvpw * 0.02),
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryLime,
                            size: dvpw * 0.055,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: dvph * 0.02),
            ],
          ),
        );
      },
    );
  }
}

// Custom formatter for phone number (adds space after 5 digits)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(' ', '');
    if (digitsOnly.length <= 5) {
      return TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
    } else {
      final formatted = '${digitsOnly.substring(0, 5)} ${digitsOnly.substring(5)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }
}
