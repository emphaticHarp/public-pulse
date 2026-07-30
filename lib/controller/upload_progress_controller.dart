import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

enum UploadStep { compressing, metadata, uploading, saving, completed }

class UploadProgressController extends GetxController {
  /// Current upload step
  final Rx<UploadStep> currentStep = UploadStep.compressing.obs;

  /// Indicates whether an upload is currently running.
  final RxBool isUploading = false.obs;

  /// Overall upload progress (0.0 -> 1.0)
  final RxDouble uploadProgress = 0.0.obs;

  /// Current upload stage shown to the user.
  final RxString uploadStage = "Preparing Upload".obs;

  /// Current file being uploaded.
  final RxString currentFile = "".obs;

  /// Uploaded data (e.g. 8.4 MB / 25 MB)
  final RxString uploadedSize = "0 MB / 0 MB".obs;

  /// Current upload speed (e.g. 2.5 MB/s)
  final RxString uploadSpeed = "0 MB/s".obs;

  /// Estimated remaining upload time
  final RxString remainingTime = "--".obs;

  /// Whether upload finished successfully.
  final RxBool isCompleted = false.obs;

  /// Whether upload failed.
  final RxBool hasError = false.obs;

  /// Error message if upload fails.
  final RxString errorMessage = "".obs;

  void startUpload() {
    debugPrint('📦 [UploadProgressCtrl] startUpload() - Resetting all state');
    isUploading.value = true;
    isCompleted.value = false;
    hasError.value = false;
    errorMessage.value = "";
    uploadProgress.value = 0.0;
    uploadStage.value = "Preparing Upload";
    currentStep.value = UploadStep.compressing;
    currentFile.value = "";
    uploadedSize.value = "0 MB / 0 MB";
    uploadSpeed.value = "0 MB/s";
    remainingTime.value = "--";
    debugPrint('🟢 [UploadProgressCtrl] Upload started - isUploading: true');
  }

  void updateProgress(double value) {
    final clamped = value.clamp(0.0, 1.0);
    uploadProgress.value = clamped;
  }

  void updateStage(String stage) {
    debugPrint('📦 [UploadProgressCtrl] Stage: $stage');
    uploadStage.value = stage;
  }

  void updateCurrentFile(String fileName) {
    debugPrint('📦 [UploadProgressCtrl] CurrentFile: $fileName');
    currentFile.value = fileName;
  }

  void updateStep(UploadStep step) {
    debugPrint('📦 [UploadProgressCtrl] Step: $step');
    currentStep.value = step;
  }

  void updateUploadStats({
    required String uploaded,
    required String speed,
    required String timeLeft,
  }) {
    uploadedSize.value = uploaded;
    uploadSpeed.value = speed;
    remainingTime.value = timeLeft;
  }

  void completeUpload() {
    debugPrint('🟢 [UploadProgressCtrl] completeUpload() called');
      currentStep.value = UploadStep.completed;
    isUploading.value = false;
    isCompleted.value = true;
    uploadProgress.value = 1.0;
    uploadStage.value = "Upload Completed";
    remainingTime.value = "Done";
    debugPrint('🟢 [UploadProgressCtrl] Upload marked as COMPLETED');
  }

  void failUpload(String message) {
    debugPrint('🔴 [UploadProgressCtrl] failUpload() called');
    debugPrint('🔴 [UploadProgressCtrl] Error: $message');
    isUploading.value = false;
    hasError.value = true;
    errorMessage.value = message;
    uploadStage.value = "Upload Failed";
    debugPrint('🔴 [UploadProgressCtrl] Upload marked as FAILED');
  }

  void reset() {
    debugPrint('🔄 [UploadProgressCtrl] reset() called');
    currentStep.value = UploadStep.compressing;
    isUploading.value = false;
    isCompleted.value = false;
    hasError.value = false;
    errorMessage.value = "";
    uploadProgress.value = 0.0;
    uploadStage.value = "Preparing Upload";
    currentFile.value = "";
    uploadedSize.value = "0 MB / 0 MB";
    uploadSpeed.value = "0 MB/s";
    remainingTime.value = "--";
    debugPrint('🟢 [UploadProgressCtrl] State reset complete');
  }
}
