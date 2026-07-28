import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class CustomAlert extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const CustomAlert({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  static void show({
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    Color color = AppColors.loginAccentRed,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(Get.overlayContext!);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AnimatedAlert(
        child: CustomAlert(
          title: title,
          message: message,
          icon: icon,
          color: color,
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(duration, () {
      entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          width: MediaQuery.of(context).size.width * .92,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
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

  const _AnimatedAlert({required this.child});

  @override
  State<_AnimatedAlert> createState() => _AnimatedAlertState();
}

class _AnimatedAlertState extends State<_AnimatedAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    animation = Tween(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animation,
      child: widget.child,
    );
  }
}