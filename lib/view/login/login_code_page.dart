import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/controller/login_code_controller.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/theme/app_font.dart';
import 'package:flutter/services.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class LoginCodePage extends StatelessWidget {
  LoginCodePage({super.key});

  final LoginCodeController controller = Get.put(LoginCodeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmLightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Lock Icon
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.loginAccentRed.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 42,
                    color: AppColors.lockIconTint,
                  ),
                ),

                const SizedBox(height: 32),

                /// Title
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Referal",
                        style: AppTextStyles.loginHeading.copyWith(
                          fontSize: 28,
                          color: AppColors.loginAccentRed,
                        ),
                      ),
                      TextSpan(
                        text: " Code",
                        style: AppTextStyles.loginHeading.copyWith(
                          fontSize: 28,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                /// Subtitle
                Text(
                  "Got a referral code from a friend?\n"
                  "Enter the 6-character code below to continue.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 14,
                    color: AppColors.slate500,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 42),

                /// Verification Code Input
                Obx(() {
                  final hasError = controller.codeError.value.isNotEmpty;

                  return _ShakeWidget(
                    trigger: controller.shakeTrigger.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: controller.pinController,
                          autofocus: true,
                          maxLength: 6,
                          keyboardType: TextInputType.visiblePassword,
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,

                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                            UpperCaseTextFormatter(),
                            LengthLimitingTextInputFormatter(6),
                          ],

                          onChanged: (_) => controller.clearCodeError(),

                          style: AppTextStyles.loginHeading.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                            letterSpacing: 10,
                          ),

                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '------',
                            hintStyle: AppTextStyles.loginHeading.copyWith(
                              fontSize: 20,
                              color: AppColors.slate400,
                              letterSpacing: 10,
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: hasError
                                    ? AppColors.loginAccentRed
                                    : AppColors.loginAccentRed,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.loginAccentRed,
                                width: 1.5,
                              ),
                            ),
                          ),

                          onSubmitted: (_) {
                            if (!controller.isLoading.value) {
                              controller.verifyCode();
                            }
                          },
                        ),

                        // ─────────────────────────────────────
                        // INLINE ERROR MESSAGE
                        // ─────────────────────────────────────

                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: hasError
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                    left: 6,
                                    top: 7,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        size: 15,
                                        color: AppColors.loginAccentRed,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        controller.codeError.value,
                                        style: AppTextStyles.subtitle.copyWith(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.loginAccentRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 42),

                /// Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.loginAccentRed,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              "Verify Code",
                              style: AppTextStyles.buttonText.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShakeWidget extends StatefulWidget {
  final int trigger;
  final Widget child;

  const _ShakeWidget({required this.trigger, required this.child});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final sineValue =
            math.sin(_animation.value * 3 * math.pi) *
            (1 - _animation.value);
        return Transform.translate(
          offset: Offset(sineValue * 8, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
