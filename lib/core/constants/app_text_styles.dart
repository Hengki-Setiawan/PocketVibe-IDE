import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white,
  );
  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white,
  );
  static TextStyle get headline => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
  );
  static TextStyle get title => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
  );
  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF),
  );
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFF1F1F1),
  );
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF9CA3AF),
  );
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF6B7280),
  );
  static TextStyle get code => GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFFF1F1F1),
  );
  static TextStyle get codeSmall => GoogleFonts.jetBrainsMono(
    fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF9CA3AF),
  );
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
  );
}
