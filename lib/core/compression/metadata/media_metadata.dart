import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:geolocator/geolocator.dart';

class MediaMetadataExtractor {
  /// Extracts all available metadata for an image.
  /// [originalPath] = the file BEFORE compression (has EXIF intact)
  /// [compressedFile] = the file AFTER compression (what actually got uploaded)
  /// [mediaId] = the id of the post_media row this metadata belongs to
  static Future<Map<String, dynamic>> extractImageMetadata({
    required String mediaId,
    required String originalPath,
    required File compressedFile,
  }) async {
    final originalFile = File(originalPath);
    final originalBytes = await originalFile.readAsBytes();
    final compressedBytes = await compressedFile.readAsBytes();

    // --- Basic file info ---
    final originalFileName = originalPath.split(RegExp(r'[/\\]')).last;
    final originalSize = originalBytes.length;
    final compressedSize = compressedBytes.length;
    final extension = compressedFile.path.split('.').last;
    final mimeType = lookupMimeType(compressedFile.path) ?? 'image/webp';

    // --- Dimensions (from compressed file, since that's what's stored) ---
    int? width;
    int? height;
    try {
      final decoded = img.decodeImage(compressedBytes);
      width = decoded?.width;
      height = decoded?.height;
    } catch (_) {
      // Leave null if decoding fails
    }

    // --- EXIF data (from ORIGINAL, since compression strips it) ---
    // These are the coordinates where the photo was actually CAPTURED.
    DateTime? takenAt;
    double? latitude;
    double? longitude;
    String? deviceMake;
    String? deviceModel;

    try {
      final exifData = await readExifFromBytes(originalBytes);

      if (exifData.isNotEmpty) {
        final dateTag =
            exifData['EXIF DateTimeOriginal'] ?? exifData['Image DateTime'];
        if (dateTag != null) {
          takenAt = _parseExifDate(dateTag.printable);
        }

        deviceMake = exifData['Image Make']?.printable.trim();
        deviceModel = exifData['Image Model']?.printable.trim();

        final gpsLat = exifData['GPS GPSLatitude'];
        final gpsLatRef = exifData['GPS GPSLatitudeRef'];
        final gpsLon = exifData['GPS GPSLongitude'];
        final gpsLonRef = exifData['GPS GPSLongitudeRef'];

        if (gpsLat != null && gpsLon != null) {
          latitude = _convertGpsToDecimal(
            gpsLat.values.toList().cast<num>(),
            gpsLatRef?.printable,
          );
          longitude = _convertGpsToDecimal(
            gpsLon.values.toList().cast<num>(),
            gpsLonRef?.printable,
          );
        }
      }
    } catch (_) {
      // No EXIF data available — leave all as null
    }

    // --- Upload location ---
    // These are the coordinates of the DEVICE at the moment of upload,
    // regardless of where/when the photo was originally taken.
    double? uploadLatitude;
    double? uploadLongitude;
    try {
      final position = await _getCurrentPosition();
      uploadLatitude = position?.latitude;
      uploadLongitude = position?.longitude;
    } catch (_) {
      // Leave null if location unavailable/denied
    }

    // --- Device / app info (current device, not necessarily the capture device) ---
    String? osName;
    String? appVersion;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        osName = 'Android ${info.version.release}';
        deviceMake ??= info.manufacturer;
        deviceModel ??= info.model;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        osName = 'iOS ${info.systemVersion}';
        deviceMake ??= 'Apple';
        deviceModel ??= info.utsname.machine;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {
      // Leave null if unavailable
    }

    // --- Compression ratio ---
    double? compressionRatio;
    if (originalSize > 0) {
      compressionRatio = double.parse(
        (100 - (compressedSize / originalSize * 100)).toStringAsFixed(2),
      );
    }

    // --- Checksum (of the uploaded/compressed file) ---
    final checksum = sha256.convert(compressedBytes).toString();

    return {
      'media_id': mediaId,
      'original_filename': originalFileName,
      'original_file_size': originalSize,
      'compressed_file_size': compressedSize,
      'mime_type': mimeType,
      'extension': extension,
      'width': width,
      'height': height,
      'duration_seconds': null,
      'bitrate': null,
      'frame_rate': null,
      'taken_at': takenAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'upload_latitude': uploadLatitude,
      'upload_longitude': uploadLongitude,
      'device_make': deviceMake,
      'device_model': deviceModel,
      'os_name': osName,
      'app_version': appVersion,
      'compression_ratio': compressionRatio,
      'checksum_sha256': checksum,
    };
  }

  /// Fetches the device's current GPS position at upload time,
  /// handling service/permission checks safely.
  /// Returns null if location can't be obtained for any reason.
  static Future<Position?> _getCurrentPosition() async {
    // 1. Check if location services are enabled on the device at all.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // 2. Check current permission status.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Ask the user for permission.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied — can't ask again, must go to app settings.
      return null;
    }

    // 3. Fetch current position.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseExifDate(String exifDate) {
    try {
      // EXIF format: "2024:07:29 14:30:00"
      final parts = exifDate.split(' ');
      final datePart = parts[0].replaceAll(':', '-');
      final timePart = parts.length > 1 ? parts[1] : '00:00:00';
      return DateTime.parse('${datePart}T$timePart');
    } catch (_) {
      return null;
    }
  }

  static double? _convertGpsToDecimal(List<num> values, String? ref) {
    try {
      final degrees = values[0].toDouble();
      final minutes = values[1].toDouble();
      final seconds = values[2].toDouble();
      double decimal = degrees + (minutes / 60) + (seconds / 3600);

      if (ref == 'S' || ref == 'W') {
        decimal = -decimal;
      }
      return decimal;
    } catch (_) {
      return null;
    }
  }
}
