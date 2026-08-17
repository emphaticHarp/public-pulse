import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // ============================================================
  // CAMERA
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
  // GALLERY / PHOTOS
  // ============================================================

  static Future<bool> requestGalleryPermission() async {
    // On Android < 13 use storage permission;
    // on Android 13+ and iOS use photos permission.
    if (Platform.isAndroid) {
      // Android 13+ (API 33) uses READ_MEDIA_IMAGES via Permission.photos.
      // Older Android uses READ_EXTERNAL_STORAGE via Permission.storage.
      // We try storage first — it covers older devices.
      // On Android 13+ storage is auto-granted for media, so photos is needed.
      if (await Permission.photos.isGranted) {
        return true;
      }

      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) {
        return true;
      }

      // Fallback for older Android versions
      if (await Permission.storage.isGranted) {
        return true;
      }

      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }

      if (storageStatus.isPermanentlyDenied ||
          photosStatus.isPermanentlyDenied) {
        await openAppSettings();
      }

      return false;
    }

    // iOS
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
  // ============================================================
  // LOCATION
  // ============================================================

  // ============================================================
  // LOCATION
  // ============================================================

  static Future<bool> requestLocationPermission() async {
    if (await Permission.locationWhenInUse.isGranted) {
      return true;
    }

    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  // ============================================================
  // INITIAL APP PERMISSIONS
  // ============================================================

  static Future<void> requestInitialPermissions() async {
    await requestCameraPermission();

    await requestGalleryPermission();

    await requestLocationPermission();
  }
}
