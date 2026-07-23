import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.gray100,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/no_internet.webp',
            height: 80,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 12),

          const Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Please check your network settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
