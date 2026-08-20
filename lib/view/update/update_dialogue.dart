import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:public_pulse/model/app_version_model.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/widget/local/app_alerts.dart';

Future<void> showUpdateDialog(AppVersionModel update) async {
  await Get.dialog(
    PopScope(
      canPop: !update.forceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                size: 70,
                color: AppColors.loginAccentRed,
              ),

              const SizedBox(height: 20),

              Text(
                update.updateTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                update.updateMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.darkText),
              ),

              const SizedBox(height: 20),

              if (update.releaseNotes != null &&
                  update.releaseNotes!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    update.releaseNotes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

              const SizedBox(height: 25),

              Row(
                children: [
                  if (!update.forceUpdate)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text("Later"),
                      ),
                    ),

                  if (!update.forceUpdate) const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final uri = Uri.parse(update.downloadUrl);

                        final launched = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );

                        if (!launched) {
                          CustomAlert.error(
                            title: 'Update Failed',
                            message: 'Unable to open download link.',
                          );

                          return;
                        }

                        if (!update.forceUpdate) {
                          Get.back();
                        }
                      },
                      child: const Text("Update Now"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: !update.forceUpdate,
  );
}
