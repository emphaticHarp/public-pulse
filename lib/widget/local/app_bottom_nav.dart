import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/view/create_post/create_post_page.dart';
import 'package:public_pulse/controller/create_post_controller.dart';

/// Reusable bottom navigation bar used across the app.
///
/// This is a controlled widget — the parent owns [currentIndex] and
/// is notified of taps via [onTap]. The center "create post" action
/// is reported separately via [onCreatePost].
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _barHeight = 60;

  static const List<_NavItemData> _items = [
    _NavItemData(index: 0, icon: Icons.home_rounded, label: 'Home'),
    _NavItemData(index: 1, icon: Icons.groups_rounded, label: 'Community'),
    _NavItemData(
      index: 2,
      icon: Icons.slow_motion_video_rounded,
      label: 'Reels',
    ),
    _NavItemData(index: 3, icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: _barHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _navItem(_items[0])),
              Expanded(child: _navItem(_items[1])),
              Expanded(child: _createPostButton()),
              Expanded(child: _navItem(_items[2])),
              Expanded(child: _navItem(_items[3])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(_NavItemData item) {
    final bool isActive = currentIndex == item.index;
    final Color color = isActive ? AppColors.loginAccentRed : AppColors.gray500;

    return InkWell(
      onTap: () => onTap(item.index),
      customBorder: const CircleBorder(),
      child: SizedBox(
        height: _barHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 26, color: color),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createPostButton() {
    return SizedBox(
      width: double.infinity,
      height: _barHeight,
      child: Center(
        child: InkWell(
          onTap: () {
            if (!Get.isRegistered<CreatePostController>()) {
              Get.put(CreatePostController());
            }
            Get.to(
              () => const CreatePostPage(),
              transition: Transition.downToUp,
              duration: const Duration(milliseconds: 300),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.loginAccentRed,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.loginAccentRed.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.index,
    required this.icon,
    required this.label,
  });

  final int index;
  final IconData icon;
  final String label;
}
