import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle body = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.primary.withValues(alpha: 0.87),
  );

  static TextStyle hint = GoogleFonts.poppins(
    fontSize: 13.5,
    color: AppColors.grey,
  );

  static TextStyle button = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
}
