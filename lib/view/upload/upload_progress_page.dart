import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/controller/upload_progress_controller.dart';

class UploadProgressPage extends StatelessWidget {
  const UploadProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('📤 [UploadProgressPage] build() called');
    final UploadProgressController controller =
        Get.find<UploadProgressController>();
    debugPrint('🟢 [UploadProgressPage] UploadProgressController found');
    debugPrint('📤 [UploadProgressPage] Progress: ${controller.uploadProgress.value}');
    debugPrint('📤 [UploadProgressPage] Stage: ${controller.uploadStage.value}');
    debugPrint('📤 [UploadProgressPage] Error: ${controller.hasError.value} - ${controller.errorMessage.value}');

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            children: [
              const SizedBox(height: 50),

              const Icon(
                Icons.cloud_upload_rounded,
                color: AppColors.createPostRed700,
                size: 95,
              ),

              const SizedBox(height: 35),

              const Text(
                "Uploading Your Post",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text(
                "Please don't close the app while your post is uploading.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),

              const SizedBox(height: 45),

              Obx(
                () => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: controller.uploadProgress.value,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    color: AppColors.createPostRed700,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Obx(
                () => Text(
                  "${(controller.uploadProgress.value * 100).toInt()}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Obx(
                () => Column(
                  children: [
                    Text(
                      controller.uploadedSize.value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "⚡ ${controller.uploadSpeed.value}",
                      style: const TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "⏱ ${controller.remainingTime.value}",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              Expanded(
                child: Obx(() {
                  final step = controller.currentStep.value;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepTile(
                        icon: Icons.compress,
                        title: "Compressing Media",
                        completed: step.index > UploadStep.compressing.index,
                        loading: step == UploadStep.compressing,
                      ),

                      const SizedBox(height: 18),

                      _StepTile(
                        icon: Icons.location_on,
                        title: "Extracting Metadata",
                        completed: step.index > UploadStep.metadata.index,
                        loading: step == UploadStep.metadata,
                      ),

                      const SizedBox(height: 18),

                      _StepTile(
                        icon: Icons.cloud_upload,
                        title: "Uploading Files",
                        completed: step.index > UploadStep.uploading.index,
                        loading: step == UploadStep.uploading,
                      ),

                      const SizedBox(height: 18),

                      _StepTile(
                        icon: Icons.storage,
                        title: "Saving Post",
                        completed: step.index > UploadStep.saving.index,
                        loading: step == UploadStep.saving,
                      ),
                    ],
                  );
                }),
              ),

              Obx(() {
                if (!controller.hasError.value) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          debugPrint('📤 [UploadProgressPage] Go Back button pressed');
                          Get.back();
                        },
                        child: const Text("Go Back"),
                      ),
                    ],
                  ),
                );
              }),

              // Current file label at the bottom
              Obx(
                () {
                  if (controller.currentFile.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      controller.currentFile.value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool completed;
  final bool loading;

  const _StepTile({
    required this.icon,
    required this.title,
    this.completed = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget leading;

    if (completed) {
      leading = const CircleAvatar(
        radius: 16,
        backgroundColor: Colors.green,
        child: Icon(Icons.check, color: Colors.white, size: 18),
      );
    } else if (loading) {
      leading = const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    } else {
      leading = CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade200,
        child: Icon(icon, color: Colors.grey, size: 18),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: .05),
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          leading,

          const SizedBox(width: 18),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
