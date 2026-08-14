import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // ============================================================
  // CAMERA PERMISSION
  // ============================================================

  static Future<bool> requestCameraPermission() async {
    if (await Permission.camera.isGranted) {
      return true;
    }

    final status = await Permission.camera.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  // ============================================================
  // GALLERY ACCESS
  // ============================================================

  static Future<bool> requestGalleryAccess(BuildContext context) async {
    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gallery Access'),
          content: const Text(
            'Public Pulse needs access to your gallery so you can select photos for your post.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );

    return allowed ?? false;
  }
}
