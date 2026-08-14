import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Brand Colors ──────────────────────────────────────────────
  /// Login accent red - used for buttons and links on login page
  static const Color loginAccentRed = Color.fromRGBO(226, 29, 72, 1);

  /// Onboarding/Splash accent red - used for buttons and highlights
  static const Color accentRed = Color.fromRGBO(217, 33, 52, 0.83);

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
  static const Color createPostGray800 = Color.fromARGB(224, 15, 15, 16);

  // ── Login Page Specific Colors ───────────────────────────────────────
  /// Pure black - used for Apple sign-in button and dark UI elements
  static const Color pureBlack = Color.fromARGB(0, 34, 33, 33);

  /// Login box shadow color (black at ~8% opacity)
  static const Color loginBoxShadow = Color.fromARGB(0, 18, 17, 17);

  static const Color slate500 = Color.fromARGB(255, 0, 0, 0);

  // ── Profile Page Colors ───────────────────────────────────────────────
  /// Success green - used for "username available" status on Edit Profile
  static const Color profileSuccessGreen = Color.fromARGB(255, 59, 207, 153);

  /// Fully transparent - used for inactive tab underline on Profile Screen
  static const Color transparent = Color.fromARGB(0, 23, 22, 22);

  // setting page Colors ──────────────────────────────────────
  /// Background - used for the main setting page background
  static const Color background = Color(0xFFFAFAFA);

  /// Surface - used for cards, dialogs, and container backgrounds
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary text - used for main headings and titles
  static const Color primaryText = Color(0xFF111827);

  /// Secondary text - used for subtitles and descriptive text
  static const Color secondaryText = Color(0xFF6B7280);

  /// Icon color - standard color for icons
  static const Color iconColor = Color(0xFF374151);

  /// Divider color - used for lines between list items
  static const Color dividerColor = Color(0xFFE5E7EB);

  /// Icon background - circular background behind icons
  static const Color iconBackground = Color(0xFFF3F4F6);

  /// Success - used for active or success status indicators
  static const Color success = Color(0xFF10B981);

  /// Toggle red - used for destructive toggle switches
  static const Color toggleRed = Color(0xFFEF4444);

  /// Danger - used for destructive actions like delete, deactivate, or logout buttons
  static const Color danger = Color(0xFFEF4444);
  static const Color grayshade200 = Color(0xFFEEEEEE);

  static const Color gray700 = Color(0xFF374151);

  static const Color black54 = Color(0x8A000000);

  static const Color gray600 = Color.fromRGBO(158, 158, 158, 1);

  // ── Semantic / Named Colors ─────────────────────────────────────────────

  // -- White & Transparent --
  /// Pure white - used for card surfaces, overlays, and text on dark backgrounds
  static const Color white = Color(0xFFFFFFFF);

  /// Fully transparent
  static const Color transparentFull = Colors.transparent;

  // -- Black & Overlay Colors --
  /// Pure black
  static const Color black = Color(0xFF000000);

  /// Black at 55% opacity - modal barrier and heavy overlay
  static const Color overlayBlack55 = Color(0x8C000000);

  /// Black at 50% opacity - modal barrier
  static const Color overlayBlack50 = Color(0x80000000);

  /// Black at 45% opacity - upload overlay
  static const Color overlayBlack45 = Color(0x73000000);

  /// Black at 40% opacity - image counter badge background
  static const Color overlayBlack40 = Color(0x66000000);

  /// Black at 26% opacity - shadow color
  static const Color shadowBlack26 = Color(0x42000000);

  /// Black at 38% opacity - card shadow
  static const Color shadowBlack38 = Color(0x61000000);

  /// Black at 20% opacity - notification card shadow
  static const Color shadowBlack20 = Color(0x33000000);

  /// Black at 12% opacity - card box shadow
  static const Color shadowBlack12 = Color(0x1F000000);

  /// Black at 18% opacity - blur backdrop
  static const Color overlayBlack18 = Color(0x2E000000);

  /// Black at 10% opacity - tight contact shadow
  static const Color shadowBlack10 = Color(0x1A000000);

  /// Black at 8% opacity - alert card shadow
  static const Color shadowBlack8 = Color(0x14000000);

  /// Black at 87% opacity - comment content text
  static const Color black87 = Color(0xDE000000);

  /// Black at 5% opacity - tab shadow
  static const Color shadowBlack5 = Color(0x0D000000);

  /// Black at 3% opacity - caption section shadow
  static const Color shadowBlack3 = Color(0x08000000);

  // -- White Opacity Variants --
  /// White at 70% opacity - upload failed subtitle
  static const Color white70 = Color(0xB3FFFFFF);

  // -- Grey Scale Colors --
  /// Grey 100 - drag handle, input fill, search bar
  static const Color greyShade100 = Color(0xFFF5F5F5);

  /// Grey 200 - image placeholder background
  static const Color greyShade200 = Color(0xFFE0E0E0);

  /// Grey 400 - secondary text, empty state icons
  static const Color greyShade400 = Color(0xFFBDBDBD);

  /// Grey 500 - muted text, time labels
  static const Color greyShade500 = Color(0xFF9E9E9E);

  /// Grey 600 - secondary text in comments, alerts
  static const Color greyShade600 = Color(0xFF757575);

  /// Grey 700 - app name in notification toast
  static const Color greyShade700 = Color(0xFF616161);

  /// Grey 800 - message text in notification toast
  static const Color greyShade800 = Color(0xFF424242);

  /// Grey (default) - disabled/placeholder icons
  static const Color grey = Color(0xFF9E9E9E);

  // -- Semantic Status Colors --
  /// Red - destructive actions, delete, error indicators
  static const Color semanticRed = Color(0xFFF44336);

  /// Red shade 400 - dismiss background
  static const Color redShade400 = Color(0xFFEF5350);

  /// Orange - warning, report indicators
  static const Color semanticOrange = Color(0xFFFF9800);

  /// Blue - informational, unfollow indicators
  static const Color semanticBlue = Color(0xFF2196F3);

  /// Green - success, confirmation indicators
  static const Color semanticGreen = Color(0xFF4CAF50);

  // -- Shadow Colors for AppShadow --
  /// Black at 4% opacity - small shadow
  static const Color shadowSm = Color(0x0C000000);

  /// Black at 4% opacity - medium shadow
  static const Color shadowMd = Color(0x0C000000);

  /// Black at 3% opacity - card shadow
  static const Color shadowCard = Color(0x0A000000);

  // -- Profile & Login Specific Colors --
  /// Warm light background - followers/following page, login code page
  static const Color warmLightBg = Color(0xFFF6F1EF);

  /// Dark near-black - followers/following title
  static const Color darkNearBlack = Color(0xFF161617);

  /// Username text in edit profile
  static const Color editProfileTextDark = Color(0xFF151616);

  /// Bio text in edit profile
  static const Color editProfileBioDark = Color(0xE8131314);

  /// Error text in edit profile
  static const Color editProfileErrorRed = Color(0xFFE51D5C);

  /// Hint text in edit profile fields
  static const Color editProfileHint = Color(0xFF4B4E53);

  /// Camera icon on avatar change button
  static const Color cameraIconGrey = Color(0xFFA8ACB3);

  /// Verification title accent red - login code page
  static const Color verificationAccent = Color(0xFFDE375B);

  /// Lock icon background tint
  static const Color lockIconBgTint = Color(0xFFD1255E);

  /// Pin input background
  static const Color pinInputBg = Color(0xFF666565);

  /// Pin input border
  static const Color pinInputBorder = Color(0xFF797B7E);

  /// Bottom nav active icon color
  static const Color navActiveIcon = Color(0xFFE21D48);

  /// Bottom nav create button shadow
  static const Color createButtonShadow = Color(0x59E21D48);

  /// Alert card background
  static const Color alertCardBg = Color(0xFFF5F5F7);

  /// Lock icon tint for login code
  static const Color lockIconTint = Color(0xFF000000);
}
