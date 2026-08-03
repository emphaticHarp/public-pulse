import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../model/profile_model.dart';
import '../core/repository/profile_repository.dart';
import 'profile_controller.dart';

/// Owns the Edit Profile form/picker/validation state only. Talks to the
/// same ProfileRepository — there is no separate EditProfileRepository.
class EditProfileController extends GetxController {
  static EditProfileController get to => Get.find();

  final ProfileRepository _repo = ProfileRepository.instance;
  final ImagePicker _picker = ImagePicker();

  late final ProfileModel original = ProfileController.to.profile.value!;

  final usernameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();

  final usernameStatus = ''.obs;
  final errorMessage = ''.obs;
  final isSaving = false.obs;

  final pickedAvatar = Rxn<File>();
  final pickedCover = Rxn<File>();

  /// Existing photo shown while editing, before a new one is picked.
  String? get avatarUrl => original.avatarPath != null
      ? _repo.resolveUrl(original.avatarPath!, bucket: 'avatars')
      : null;

  String? get coverUrl => original.coverPath != null
      ? _repo.resolveUrl(original.coverPath!, bucket: 'covers')
      : null;

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

  Future<void> pickAvatar() => _pick(pickedAvatar);
  Future<void> pickCover() => _pick(pickedCover);

  Future<void> _pick(Rxn<File> target) async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile != null) {
      target.value = File(xfile.path);
    }
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
      final username = usernameCtrl.text.trim().toLowerCase();

      final updated = await _repo.updateProfile(
        username: username == original.username ? null : username,
        bio: bioCtrl.text.trim(),
        avatarFile: pickedAvatar.value,
        coverFile: pickedCover.value,
      );

      ProfileController.to.applyUpdatedProfile(updated);
      Get.back();
    } catch (_) {
      errorMessage(
        'Failed to save. Please check your connection and try again.',
      );
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
      return _fail(
        'Username must be 3–30 chars: letters, numbers, underscores only.',
      );
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
