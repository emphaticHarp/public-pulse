import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
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
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: AppTextStyles.loginHeading.copyWith(
        fontSize: 20,
        color: AppColors.slate900,
      ),
      decoration: BoxDecoration(
        color: AppColors.pinInputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.pinInputBorder, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.pureBlack, width: 2),
    );

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
                    color: AppColors.lockIconBgTint.withValues(alpha: 0.05),
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
                        text: "Verification",
                        style: AppTextStyles.loginHeading.copyWith(
                          fontSize: 28,
                          color: AppColors.verificationAccent,
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
                  "Your account is currently pending approval.\n"
                  "Please enter the 6-character verification code",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 14,
                    color: AppColors.slate500,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 42),

                /// Pin Input
                Pinput(
                  controller: controller.pinController,
                  length: 6,
                  autofocus: true,
                  keyboardType: TextInputType.visiblePassword,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    UpperCaseTextFormatter(),
                  ],
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: focusedPinTheme,
                ),

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
                        backgroundColor: AppColors.verificationAccent,
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
