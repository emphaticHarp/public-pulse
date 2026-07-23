import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Gallery Permission
  static Future<bool> requestGalleryPermission() async {
    Permission permission;

    if (await Permission.photos.isGranted ||
        await Permission.storage.isGranted) {
      return true;
    }

    if (Permission.photos != Permission.storage) {
      permission = Permission.photos;
    } else {
      permission = Permission.storage;
    }

    final status = await permission.request();

    return status.isGranted;
  }

  /// Camera Permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();

    return status.isGranted;
  }
}