import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static const int _smallFileThreshold = 40 * 1024; // 40 KB
  static const int _targetMinBytes = 70 * 1024; // 70 KB
  static const int _targetMaxBytes = 80 * 1024; // 80 KB
  static const int _maxDimension = 1600;
  static const int _minDimension = 800;
  static const int _minQuality = 35;
  static const int _maxAttempts = 5;

  Future<File?> compressImage(String inputPath) async {
    final originalFile = File(inputPath);

    Uint8List originalBytes;
    try {
      originalBytes = await originalFile.readAsBytes();
    } catch (_) {
      return null;
    }

    final originalSize = originalBytes.length;
    final dir = await getTemporaryDirectory();
    final sessionId = DateTime.now().millisecondsSinceEpoch;

    if (originalSize <= _smallFileThreshold) {
      return _stripMetadataOnly(originalBytes, dir.path, sessionId, originalSize, originalFile);
    }

    //compression  70-80 KB target
    int quality = 70;
    int dimension = _maxDimension;

    Uint8List? bestBytes;
    int bestDiff = 1 << 30;

    for (int attempt = 0; attempt < _maxAttempts; attempt++) {
      final Uint8List? resultBytes = await _safeCompress(
        originalBytes,
        quality: quality,
        minWidth: dimension,
        minHeight: dimension,
      );

      // Decoder couldn't process this format at all (e.g. HEIC on an
      // unsupported Android device) — stop trying, fall back below.
      if (resultBytes == null) break;

      final size = resultBytes.length;

      if (size >= _targetMinBytes && size <= _targetMaxBytes) {
        bestBytes = resultBytes;
        break;
      }

      final diff = size < _targetMinBytes
          ? _targetMinBytes - size
          : size - _targetMaxBytes;

      if (diff < bestDiff) {
        bestDiff = diff;
        bestBytes = resultBytes;
      }

      if (size > _targetMaxBytes) {
        final overshootRatio = (size - _targetMaxBytes) / size;
        final step = (overshootRatio * 40).clamp(5, 25).round();

        if (quality - step >= _minQuality) {
          quality -= step;
        } else if (dimension > _minDimension) {
          dimension -= 200;
          quality = 60;
        } else {
          break;
        }
      } else if (size < _targetMinBytes) {
        final undershootRatio = (_targetMinBytes - size) / _targetMinBytes;
        final step = (undershootRatio * 20).clamp(3, 15).round();

        if (quality + step <= 95) {
          quality += step;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    // Nothing usable came out of Tier 2 — try a plain metadata-only strip
    if (bestBytes == null) {
      return _stripMetadataOnly(originalBytes, dir.path, sessionId, originalSize, originalFile);
    }

    if (bestBytes.length >= originalSize) {
      return _stripMetadataOnly(originalBytes, dir.path, sessionId, originalSize, originalFile);
    }

    final finalPath = '${dir.path}/${sessionId}_compressed.webp';
    final finalFile = File(finalPath);
    await finalFile.writeAsBytes(bestBytes, flush: true);
    return finalFile;
  }

  /// Re-encodes at near-lossless quality purely to remove EXIF metadata.
  Future<File?> _stripMetadataOnly(
    Uint8List originalBytes,
    String dirPath,
    int sessionId,
    int originalSize,
    File originalFile,
  ) async {
    final resultBytes = await _safeCompress(originalBytes, quality: 95);

    if (resultBytes == null || resultBytes.length > originalSize) {
      return originalFile;
    }

    final strippedPath = '$dirPath/${sessionId}_stripped.webp';
    final file = File(strippedPath);
    await file.writeAsBytes(resultBytes, flush: true);
    return file;
  }

  /// Wraps compressWithList so an unsupported input format
  Future<Uint8List?> _safeCompress(
    Uint8List bytes, {
    required int quality,
    int? minWidth,
    int? minHeight,
  }) async {
    try {
      return await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: minWidth ?? 0,
        minHeight: minHeight ?? 0,
        format: CompressFormat.webp,
        keepExif: false,
      );
    } catch (_) {
      return null;
    }
  }
}