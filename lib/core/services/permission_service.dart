import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Gallery Permission (images)
  static Future<bool> requestGalleryPermission() async {
    if (await Permission.photos.isGranted) {
      return true;
    }

    final status = await Permission.photos.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  /// Gallery Permission (videos)
  static Future<bool> requestVideoGalleryPermission() async {
    if (await Permission.videos.isGranted) {
      return true;
    }

    final status = await Permission.videos.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  /// Camera Permission
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
}