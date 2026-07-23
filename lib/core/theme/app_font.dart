import 'package:flutter/material.dart';

/// Centralized text styles for the Public Pulse app.
/// All styles use the Poppins font family.
class AppTextStyles {
  AppTextStyles._();



  // ── Heading Styles ────────────────────────────────────────────────────
  /// Splash logo text - large italic brand name
static const TextStyle splashLogo = TextStyle(
  fontSize: 34,
  fontWeight: FontWeight.w900,
  fontStyle: FontStyle.italic,
  letterSpacing: -1.2,
);

  /// Onboarding slide title
 static const TextStyle onboardTitle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w900,
  height: 1.25,
  letterSpacing: -0.3,
);

  /// Login welcome heading
 static const TextStyle loginHeading = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

  /// Page-level heading (e.g. "Notifications")
 static const TextStyle pageHeading = TextStyle(
  fontSize: 30,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.5,
);

  /// Section heading within a page (e.g. "New", "Earlier")
 static const TextStyle sectionHeading = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
);

  // ── Button text Styles ─────────────────────────────────────────────────────
  /// Primary button text (Login, Next, Get Started)
static const TextStyle buttonText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
);
  /// Next button text on onboarding
static const TextStyle nextButtonText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

  // ── Body Styles ───────────────────────────────────────────────────────
  /// Onboarding slide description
  static const TextStyle onboardDescription = TextStyle(
      fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );

  /// Regular body text
 static const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

  /// Button-style text (forgot password, sign up)
  static const TextStyle linkText = TextStyle(
   
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Subtitle text (login subtitle)
  static const TextStyle subtitle = TextStyle(
    
    fontSize: 14,
  );

  /// Skip text on onboarding
  static const TextStyle skipText = TextStyle(
    
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Don't have account text
  static const TextStyle footerText = TextStyle(
    
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// Sign up link
  static const TextStyle signUpLink = TextStyle(
    
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  /// Text field input text
  static const TextStyle inputText = TextStyle(
    
    fontSize: 14,
  );

  /// Tab bar item label (e.g. All / Likes / Comments / Follows)
  static const TextStyle tabLabel = TextStyle(
    
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Tab bar item label when active/selected
  static const TextStyle tabLabelActive = TextStyle(
    
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  /// Notification list item primary text (name + action)
  static const TextStyle notificationText = TextStyle(
    
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  /// Notification list item timestamp
  static const TextStyle notificationTime = TextStyle(
    
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  // ── Small / Label Styles ──────────────────────────────────────────────
  /// Divider label text (OR CONTINUE WITH)
  static const TextStyle dividerLabel = TextStyle(
    
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
  );

  /// Splash tagline
  static const TextStyle tagline = TextStyle(
    
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.4,
  );

  /// Splash syncing text
  static const TextStyle syncingText = TextStyle(
    
    fontSize: 9,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.2,
  );
}