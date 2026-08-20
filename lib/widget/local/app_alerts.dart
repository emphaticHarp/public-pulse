import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:public_pulse/core/theme/app_colors.dart';

class CustomAlert {
  CustomAlert._();

  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  // ============================================================
  // NORMAL DYNAMIC ISLAND ALERT
  // ============================================================

  static void show({
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color color = AppColors.loginAccentRed,
    Duration duration = const Duration(seconds: 3),
  }) {
    _removeCurrent();
    final context = Get.context;

    if (context == null) {
      return;
    }

    final navigator = Navigator.maybeOf(context, rootNavigator: true);

    final overlay = navigator?.overlay;

    if (overlay == null) {
      return;
    }
    _currentEntry = OverlayEntry(
      builder: (_) {
        return _DynamicIslandAlert(
          title: title,
          message: message,
          icon: icon,
          color: color,
          onDismiss: _removeCurrent,
        );
      },
    );

    overlay.insert(_currentEntry!);

    _timer = Timer(duration, _removeCurrent);
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  static void success({required String title, required String message}) {
    show(
      title: title,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.success,
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  static void error({required String title, required String message}) {
    show(
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      color: AppColors.loginAccentRed,
    );
  }

  // ============================================================
  // WARNING
  // ============================================================

  static void warning({required String title, required String message}) {
    show(
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      color: AppColors.semanticOrange,
    );
  }

  // ============================================================
  // CONFIRMATION DYNAMIC ISLAND
  // ============================================================

  static Future<bool> showConfirm({
    required String title,
    required String message,
    IconData icon = Icons.warning_amber_rounded,
    Color color = AppColors.loginAccentRed,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final context = Get.context;

    if (context == null) {
      return false;
    }

    final result = await showGeneralDialog<bool>(
      context: context,

      barrierDismissible: true,
      barrierLabel: 'Dismiss',

      barrierColor: AppColors.overlayBlack18,

      transitionDuration: const Duration(milliseconds: 260),

      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Material(
            color: AppColors.transparentFull,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _DynamicIslandConfirm(
                    title: title,
                    message: message,
                    icon: icon,
                    color: color,
                    confirmText: confirmText,
                    cancelText: cancelText,
                  ),
                ),
              ),
            ),
          ),
        );
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.20),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // REMOVE CURRENT ALERT
  // ============================================================

  static void _removeCurrent() {
    _timer?.cancel();
    _timer = null;

    _currentEntry?.remove();
    _currentEntry = null;
  }
}

// ===============================================================
// NORMAL DYNAMIC ISLAND
// ===============================================================

class _DynamicIslandAlert extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  const _DynamicIslandAlert({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<_DynamicIslandAlert> createState() => _DynamicIslandAlertState();
}

class _DynamicIslandAlertState extends State<_DynamicIslandAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(curved);

    _scale = Tween<double>(begin: 0.82, end: 1).animate(curved);

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.45),
      end: Offset.zero,
    ).animate(curved);

    _controller.forward();
  }

  Future<void> _dismiss() async {
    if (!_controller.isAnimating) {
      await _controller.reverse();
    }

    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return SafeArea(
      child: Material(
        color: AppColors.transparentFull,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _scale,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth < 600 ? screenWidth - 24 : 420,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowBlack26,
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // =============================
                            // ICON
                            // =============================

                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                size: 21,
                                color: widget.color,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // =============================
                            // TEXT
                            // =============================
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  if (widget.message.trim().isNotEmpty) ...[
                                    const SizedBox(height: 2),

                                    Text(
                                      widget.message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            const Icon(
                              Icons.close_rounded,
                              color: AppColors.gray500,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// CONFIRMATION DYNAMIC ISLAND
// ===============================================================

class _DynamicIslandConfirm extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String confirmText;
  final String cancelText;

  const _DynamicIslandConfirm({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.confirmText,
    required this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlack26,
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 23),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text(cancelText),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(confirmText, maxLines: 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
