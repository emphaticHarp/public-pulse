import 'package:get/get.dart';
import '../core/repository/profile_repository.dart';
import '../model/profile_model.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  final ProfileRepository _repo = ProfileRepository.instance;

  final profile = Rxn<ProfileModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedTab = ProfileTab.photos.obs;

  // wire to PostRepository once the Posts feature exists.
  // UI only ever reads these — no filtering logic lives in the widget.
  final photoPosts = <String>[].obs;
  final savedPosts = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading(true);
    try {
      profile.value = await _repo.loadProfile();
    } catch (_) {
      errorMessage('Failed to load profile.');
    } finally {
      isLoading(false);
    }
  }

  void changeTab(ProfileTab tab) => selectedTab.value = tab;

  /// Called by EditProfileController right after a successful save so the
  /// Profile Screen reflects the change instantly — no extra network call.
  void applyUpdatedProfile(ProfileModel updated) => profile.value = updated;
}