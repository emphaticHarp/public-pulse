import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class CustomAlert extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String appName;

  const CustomAlert({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.appName = 'Public Pulse',
  });

  /// Shows a confirmation dialog with Cancel and Confirm buttons.
  static Future<bool> showConfirm({
    required String title,
    required String message,
    IconData icon = Icons.help_outline,
    Color color = AppColors.loginAccentRed,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color confirmColor = Colors.red,
  }) async {
    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      child: Text(cancelText),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                      ),
                      onPressed: () => Get.back(result: true),
                      child: Text(
                        confirmText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  static void show({
    required String title,
    required String message,
    IconData icon = Icons.notifications_none,
    Color color = AppColors.loginAccentRed,
    String appName = 'Public Pulse',
    Duration duration = const Duration(seconds: 3),
  }) {
    // Safely get overlay context - may be null during early app initialization
    final overlayContext = Get.overlayContext;
    if (overlayContext == null) {
      debugPrint('[CustomAlert] Overlay context is null, skipping alert: $title - $message');
      return;
    }

    final overlay = Overlay.of(overlayContext);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AnimatedAlert(
        onDismissed: () => entry.remove(),
        duration: duration,
        child: CustomAlert(
          title: title,
          message: message,
          icon: icon,
          color: color,
          appName: appName,
        ),
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('\u00b7', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(width: 4),
                  Text('now', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedAlert extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismissed;
  final Duration duration;

  const _AnimatedAlert({
    required this.child,
    required this.onDismissed,
    required this.duration,
  });

  @override
  State<_AnimatedAlert> createState() => _AnimatedAlertState();
}

class _AnimatedAlertState extends State<_AnimatedAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> slideAnimation;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 220),
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: GestureDetector(
          onTap: _dismiss,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
              _dismiss();
            }
          },
          child: widget.child,
        ),
      ),
    );
  }
}