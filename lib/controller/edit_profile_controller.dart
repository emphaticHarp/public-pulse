import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/repository/profile_repository.dart';
import '../core/theme/app_colors.dart';
import '../model/profile_model.dart';
import 'profile_controller.dart';

class EditProfileController extends GetxController {
  static EditProfileController get to => Get.find();

  final ProfileRepository _repo = ProfileRepository.instance;
  final ImagePicker _picker = ImagePicker();

  ProfileModel get original {
    if (!Get.isRegistered<ProfileController>()) {
      return const ProfileModel(userId: '', username: '');
    }

    final currentProfile = ProfileController.to.profile.value;
    return currentProfile ?? const ProfileModel(userId: '', username: '');
  }

  final usernameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();

  final usernameStatus = ''.obs;
  final errorMessage = ''.obs;
  final isSaving = false.obs;

  final pickedProfilePhoto = Rxn<File>();
  final pickedCoverPhoto = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    usernameCtrl.text = original.username;
    bioCtrl.text = original.bio ?? '';
  }

  @override
  void onClose() {
    usernameCtrl.dispose();
    bioCtrl.dispose();
    super.onClose();
  }

  Future<void> pickProfilePhoto() => _pick(pickedProfilePhoto);
  Future<void> pickCoverPhoto() => _pick(pickedCoverPhoto);

  Future<void> _pick(Rxn<File> target) async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile != null) target.value = File(xfile.path);
  }

  Future<void> validateUsername(String value) async {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      usernameStatus('');
      return;
    }
    if (trimmed == original.username) {
      usernameStatus('available');
      return;
    }
    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(trimmed)) {
      usernameStatus('invalid');
      return;
    }

    usernameStatus('checking');
    final available = await _repo.isUsernameAvailable(trimmed);
    usernameStatus(available ? 'available' : 'taken');
  }

  Future<void> save() async {
    if (!_isFormValid()) return;
    isSaving(true);
    try {
      final profileUrl = pickedProfilePhoto.value != null
          ? await _repo.uploadProfilePhoto(pickedProfilePhoto.value!)
          : original.profilePhotoUrl;
      final coverUrl = pickedCoverPhoto.value != null
          ? await _repo.uploadCoverPhoto(pickedCoverPhoto.value!)
          : original.coverPhotoUrl;

      final username = usernameCtrl.text.trim().toLowerCase();
      final bio = bioCtrl.text.trim();

      await _repo.updateProfile(
        username: username,
        bio: bio,
        profilePhotoUrl: profileUrl,
        coverPhotoUrl: coverUrl,
      );

      ProfileController.to.applyUpdatedProfile(original.copyWith(
        username: username,
        bio: bio,
        profilePhotoUrl: profileUrl,
        coverPhotoUrl: coverUrl,
      ));

      Get.back();
    } catch (_) {
      errorMessage('Failed to update profile. Please try again.');
    } finally {
      isSaving(false);
    }
  }

  bool _isFormValid() {
    errorMessage('');
    if (usernameCtrl.text.trim().isEmpty) {
      return _fail('Username is required.');
    }
    if (usernameStatus.value == 'invalid') {
      return _fail('Username must be 3–30 chars: letters, numbers, underscores only.');
    }
    if (usernameStatus.value == 'taken') {
      return _fail('This username is already taken.');
    }
    if (usernameStatus.value == 'checking') {
      return _fail('Please wait while we check the username.');
    }
    return true;
  }

  bool _fail(String message) {
    errorMessage(message);
    return false;
  }

  Color get usernameStatusColor => switch (usernameStatus.value) {
        'taken' || 'invalid' => AppColors.loginAccentRed,
        'available' => AppColors.profileSuccessGreen,
        _ => AppColors.gray400,
      };

  String get usernameStatusMessage => switch (usernameStatus.value) {
        'checking' => 'Checking...',
        'available' => '✓ Username available',
        'taken' => '✗ Username already taken',
        'invalid' => '✗ 3–30 chars: letters, numbers, underscores only',
        _ => '',
      };
}