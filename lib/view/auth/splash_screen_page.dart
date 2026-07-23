import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/theme/app_font.dart';
import 'onboarding_screen.dart';

const String _logoAsset = 'assets/images/logo.webp';
const Duration _minSplashDuration = Duration(milliseconds: 2500);

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});
  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderFade;

  @override   
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoFade = CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.55, curve: Curves.easeOut));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic)));
    _taglineFade = CurvedAnimation(parent: _entranceController, curve: const Interval(0.35, 0.75, curve: Curves.easeOut));
    _loaderFade = CurvedAnimation(parent: _entranceController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
    _entranceController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndNavigate());
  }

  @override
  void dispose() { _entranceController.dispose(); super.dispose(); }
  Future<void> _checkAndNavigate() async { await Future.delayed(_minSplashDuration); if (mounted) _navigateNext(); }
  void _navigateNext() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut), child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      body: SafeArea(child: Stack(children: [
        Positioned(top: -80, right: -60, child: _GlowCircle(size: 220, color: AppColors.accentRed.withValues(alpha: 0.05))),
        Positioned(bottom: -100, left: -70, child: _GlowCircle(size: 260, color: AppColors.accentRed.withValues(alpha: 0.04))),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          FadeTransition(
            opacity: _logoFade,
            child: SlideTransition(
              position: _logoSlide,
              child: Image.asset(_logoAsset, width: 180, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => RichText(text: TextSpan(style: AppTextStyles.splashLogo, children: [TextSpan(text: 'PUBLIC', style: TextStyle(color: AppColors.accentRed)), TextSpan(text: ' PULSE', style: TextStyle(color: AppColors.darkText))]))),
            ),
          ),
          const SizedBox(height: 14),
          FadeTransition(opacity: _taglineFade, child: Text('YOUR VOICE. YOUR COMMUNITY.', style: AppTextStyles.tagline.copyWith(color: AppColors.grayText))),
        ])),
        Positioned(left: 0, right: 0, bottom: 36, child: FadeTransition(opacity: _loaderFade, child: Column(children: [
          const SizedBox(height: 14),
          Text('SYNCING YOUR FEED', style: AppTextStyles.syncingText.copyWith(color: AppColors.grayText.withValues(alpha: 0.7))),
        ]))),
      ])),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) { return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)); }
}
