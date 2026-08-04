import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Brand Colors ──────────────────────────────────────────────
  /// Login accent red - used for buttons and links on login page
  static const Color loginAccentRed = Color.fromRGBO(226, 29, 72, 1);

  /// Onboarding/Splash accent red - used for buttons and highlights
  static const Color accentRed = Color.fromARGB(255, 205, 12, 80);

  // ── Surface Colors ────────────────────────────────────────────────────
  /// Primary white - used for card backgrounds and light surfaces
  static const Color primaryWhite = Color(0xFFFFFFFF);

  /// Login page surface color - light warm background
  static const Color loginSurface = Color(0xFFFBF9F8);

  /// Back button background - very light gray
  static const Color buttonBackground = Color(0xFFF1F2F4);

  // ── Text Colors ───────────────────────────────────────────────────────
  /// Slate 900 - dark text color for login page headings
  static const Color slate900 = Color(0xFF0F172A);

  /// Dark text - used for onboarding/splash headings
  static const Color darkText = Color(0xFF1A1A1A);

  /// Gray text - used for secondary text and muted elements
  static const Color grayText = Color(0xFF8A8F98);

  /// Slate 600 - secondary text color for login page
  static const Color slate600 = Color(0xFF475569);

  // ── Gray / Neutral Colors ─────────────────────────────────────────────
  /// Slate 400 - muted text and icon color for login page
  static const Color slate400 = Color(0xFF94A3B8);

  /// Slate 200 - border and divider color for login page
  static const Color slate200 = Color(0xFFE2E8F0);

  /// Gray 200 - Google sign-in button border color for login page
  static const Color gray200 = Color(0xFFE5E7EB);

  /// Inactive dot color - used for unselected pagination dots
  static const Color inactiveDot = Color(0xFFE1E4E8);

  // ── Home Page Colors ────────────────────────────────────────────────
  /// Gray 50 - lightest gray for subtle backgrounds
  static const Color gray50 = Color(0xFFF9FAFB);

  /// Gray 100 - light gray for search bar and input backgrounds
  static const Color gray100 = Color(0xFFF3F4F6);

  /// Gray 400 - muted icons and secondary text
  static const Color gray400 = Color(0xFF9CA3AF);

  /// Gray 500 - medium gray for location text and hints
  static const Color gray500 = Color(0xFF6B7280);

  /// Gray 900 - dark text and icon color
  static const Color gray900 = Color(0xFF111827);

  static const Color brand = Color(0xFFE6192E);

  static const Color surfaceDefault = Color(0xFFFBF9F8);

  static const Color surfaceDim = Color(0xFFDBDAD9);

  static const Color surfaceLowest = Color(0xFFFFFFFF);

  static const Color surfaceLow = Color(0xFFF5F3F3);

  static const Color textPrimary = Color(0xFF0F172A); // slate-900

  static const Color textSecondary = Color(0xFF64748B); // slate-500

  static const Color divider = Color(0xFFF1F5F9); // slate-100

  // ── Create Post Page Colors ─────────────────────────────────────────────
  /// Create Post Red 600 - primary red for create post page
  static const Color createPostRed600 = Color.fromARGB(255, 205, 12, 80);

  /// Create Post Red 700 - darker red for create post buttons
  static const Color createPostRed700 = Color.fromARGB(255, 205, 12, 80);

  /// Create Post Red 800 - darkest red for hover states
  static const Color createPostRed800 = Color.fromARGB(255, 205, 12, 80);

  /// Create Post Gray 300 - light gray for inactive elements
  static const Color createPostGray300 = Color.fromARGB(255, 235, 234, 229);

  /// Create Post Gray 800 - dark gray for text
  static const Color createPostGray800 = Color(0xFF1F2937);

  // ── Login Page Specific Colors ───────────────────────────────────────
  /// Pure black - used for Apple sign-in button and dark UI elements
  static const Color pureBlack = Color.fromARGB(0, 34, 33, 33);

  /// Login box shadow color (black at ~8% opacity)
  static const Color loginBoxShadow = Color.fromARGB(0, 23, 22, 22);

  static const Color slate500 = Color(0xFF64748B);

  // ── Profile Page Colors ───────────────────────────────────────────────
  /// Success green - used for "username available" status on Edit Profile
  static const Color profileSuccessGreen = Color.fromARGB(238, 19, 167, 105);

  /// Fully transparent - used for inactive tab underline on Profile Screen
  static const Color transparent = Color.fromARGB(0, 23, 22, 22);

  static const Color grayshade200 = Color(0xFFEEEEEE);

  static const Color gray700 = Color(0xFF374151);


}