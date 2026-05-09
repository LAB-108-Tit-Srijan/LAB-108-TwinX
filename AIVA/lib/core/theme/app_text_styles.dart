import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary);

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary);

  static TextStyle get hint => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textHint);

  static TextStyle get codeBlock => GoogleFonts.jetBrainsMono(
        fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white);

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);
}
