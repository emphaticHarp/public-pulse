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
    _NavItemData(index: 1, icon: Icons.explore_rounded, label: 'Explore'),
    _NavItemData(
      index: 2,
      icon: Icons.notifications_none_rounded,
      label: 'Notifications',
    ),
    _NavItemData(index: 3, icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isCompact = mediaQuery.size.height < 680;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
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
              Expanded(child: _navItem(_items[0], isCompact: isCompact)),
              Expanded(child: _navItem(_items[1], isCompact: isCompact)),
              Expanded(
                child: _createPostButton(
                  barHeight: _barHeight,
                  isCompact: isCompact,
                ),
              ),
              Expanded(child: _navItem(_items[2], isCompact: isCompact)),
              Expanded(child: _navItem(_items[3], isCompact: isCompact)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(_NavItemData item, {required bool isCompact}) {
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
              Icon(item.icon, size: isCompact ? 24 : 26, color: color),

              SizedBox(height: isCompact ? 2 : 4),

              // Prevent "Notifications" from overflowing
              // on small phones.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: isCompact ? 9 : 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CREATE POST BUTTON
  // ============================================================

  Widget _createPostButton({
    required double barHeight,
    required bool isCompact,
  }) {
    final double buttonSize = isCompact ? 42 : 48;
    final double radius = isCompact ? 14 : 16;

    return SizedBox(
      height: barHeight,
      width: double.infinity,
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
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: AppColors.loginAccentRed,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.loginAccentRed.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.add,
              color: AppColors.white,
              size: isCompact ? 24 : 26,
            ),
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
