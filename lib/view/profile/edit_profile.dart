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
                  file: controller.pickedCoverPhoto.value,
                  url: controller.original.coverPhotoUrl,
                ),
                profileImage: resolveProfileImage(
                  file: controller.pickedProfilePhoto.value,
                  url: controller.original.profilePhotoUrl,
                ),
                coverAction: ChangePhotoButton(
                  onTap: controller.pickCoverPhoto,
                ),
                avatarAction: ChangePhotoButton(
                  onTap: controller.pickProfilePhoto,
                  size: 28,
                ),
              ),
              const SizedBox(height: 56),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Display Name'),
                    _ReadOnlyField(controller.original.displayName ?? ''),
                    const SizedBox(height: 16),
                    const _FieldLabel('Username'),
                    TextField(
                      controller: controller.usernameCtrl,
                      onChanged: controller.validateUsername,
                      style: AppTextStyles.inputText.copyWith(
                        color: AppColors.textPrimary,
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
                        color: AppColors.textPrimary,
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
    hintStyle: AppTextStyles.inputText.copyWith(color: AppColors.gray400),
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

class _ReadOnlyField extends StatelessWidget {
  final String value;
  const _ReadOnlyField(this.value);

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.gray50,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      value,
      style: AppTextStyles.inputText.copyWith(color: AppColors.gray500),
    ),
  );
}
