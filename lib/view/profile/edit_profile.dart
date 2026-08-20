import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/edit_profile_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../widget/profile/profile_widget.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EditProfileController.to;

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLowest,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: Get.back,
        ),
      ),
      body: Obx(
        () => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeaderImage(
                coverImage: resolveProfileImage(
                  file: controller.pickedCover.value,
                  url: controller.coverUrl,
                ),
                profileImage: resolveProfileImage(
                  file: controller.pickedAvatar.value,
                  url: controller.avatarUrl,
                ),
                coverAction: ChangePhotoButton(onTap: controller.pickCover),
                avatarAction: ChangePhotoButton(
                  onTap: controller.pickAvatar,
                  circular: true,
                ),
              ),
              const SizedBox(height: 56),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Display Name'),

                    Obx(
                      () => TextField(
                        controller: controller.displayNameCtrl,
                        readOnly:
                            controller.isDisplayNameLockLoading.value ||
                            controller.isDisplayNameLocked.value,
                        textCapitalization: TextCapitalization.words,
                        style: AppTextStyles.inputText.copyWith(
                          color: controller.isDisplayNameLocked.value
                              ? AppColors.gray500
                              : AppColors.editProfileTextDark,
                        ),
                        decoration: _fieldDecoration('Display Name').copyWith(
                          suffixIcon: controller.isDisplayNameLockLoading.value
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.gray400,
                                    ),
                                  ),
                                )
                              : controller.isDisplayNameLocked.value
                                  ? const Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppColors.gray400,
                                      size: 20,
                                    )
                                  : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ============================================================
                    // DISPLAY NAME WARNING
                    // ============================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: controller.isDisplayNameLocked.value
                            ? AppColors.gray100
                            : AppColors.semanticOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            controller.isDisplayNameLocked.value
                                ? Icons.lock_outline_rounded
                                : Icons.info_outline_rounded,
                            size: 17,
                            color: controller.isDisplayNameLocked.value
                                ? AppColors.gray500
                                : AppColors.semanticOrange,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              controller.isDisplayNameLocked.value
                                  ? 'Your display name has already been changed once and is permanently locked.'
                                  : 'You can change your display name only once. After saving the new name, it cannot be changed again.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 12,
                                height: 1.4,
                                color: controller.isDisplayNameLocked.value
                                    ? AppColors.gray500
                                    : AppColors.semanticOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const _FieldLabel('Username'),
                    TextField(
                      controller: controller.usernameCtrl,
                      onChanged: controller.validateUsername,
                      style: AppTextStyles.inputText.copyWith(
                        color: AppColors.editProfileTextDark,
                      ),
                      decoration: _fieldDecoration('Username'),
                    ),
                    if (controller.usernameStatus.value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          controller.usernameStatusMessage,
                          style: AppTextStyles.linkText.copyWith(
                            color: controller.usernameStatusColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Bio'),
                    TextField(
                      controller: controller.bioCtrl,
                      maxLines: 3,
                      style: AppTextStyles.inputText.copyWith(
                        color: AppColors.editProfileBioDark,
                      ),
                      decoration: _fieldDecoration(
                        'Write something about yourself',
                      ),
                    ),
                    if (controller.errorMessage.value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          controller.errorMessage.value,
                          style: AppTextStyles.linkText.copyWith(
                            color: AppColors.loginAccentRed,
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: AppOutlinedButton(
                            label: 'Cancel',
                            onTap: Get.back,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Save',
                            loading: controller.isSaving.value,
                            onTap: controller.save,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.inputText.copyWith(
      color: AppColors.editProfileHint,
    ),
    filled: true,
    fillColor: AppColors.gray100,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),
  );
}
