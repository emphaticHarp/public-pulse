import 'dart:io';
import 'package:flutter/foundation.dart';
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
  // for thumbnail
  static const int _thumbnailTargetMaxBytes = 8 * 1024; // 8 KB
  static const int _thumbnailStartDimension = 100;
  static const int _thumbnailMinDimension = 100;

  // Profile avatar compression
  static const int _avatarDimension = 800;
  static const int _avatarQuality = 80;

  // Small profile avatar used in map markers
  static const int _avatarThumbnailDimension = 160;
  static const int _avatarThumbnailStartQuality = 75;
  static const int _avatarThumbnailMinQuality = 40;
  static const int _avatarThumbnailTargetMaxBytes = 15 * 1024; // 15 KB

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

    // Small files: still convert to webp (metadata strip), regardless of
    // whether the resulting file is smaller than the original.
    if (originalSize <= _smallFileThreshold) {
      return _stripMetadataOnly(originalBytes, dir.path, sessionId);
    }

    // Tier 2 — compress toward the 70-80 KB target
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

    // Nothing usable came out of Tier 2 (decoder failed on every attempt)
    // — still try to produce a webp via the metadata-strip path.
    if (bestBytes == null) {
      return _stripMetadataOnly(originalBytes, dir.path, sessionId);
    }

    // Always save as webp now, even if it's not smaller than the original.
    final finalPath = '${dir.path}/${sessionId}_compressed.webp';
    final finalFile = File(finalPath);
    await finalFile.writeAsBytes(bestBytes, flush: true);
    return finalFile;
  }

  //compression for thumbnail

  Future<File?> createThumbnail(File sourceFile) async {
    try {
      final originalBytes = await sourceFile.readAsBytes();

      if (originalBytes.isEmpty) {
        return null;
      }

      final dir = await getTemporaryDirectory();
      final sessionId = DateTime.now().microsecondsSinceEpoch;

      int dimension = _thumbnailStartDimension;
      int quality = 100;

      Uint8List? bestBytes;

      // Try several times to get a lightweight thumbnail.
      for (int attempt = 0; attempt < 5; attempt++) {
        final resultBytes = await _safeCompress(
          originalBytes,
          quality: quality,
          minWidth: dimension,
          minHeight: dimension,
        );

        if (resultBytes == null) {
          break;
        }

        bestBytes = resultBytes;

        // Small enough.
        if (resultBytes.length <= _thumbnailTargetMaxBytes) {
          break;
        }

        // Reduce size/quality progressively.
        if (quality > 25) {
          quality -= 7;
        } else if (dimension > _thumbnailMinDimension) {
          dimension -= 40;
          quality = 35;
        } else {
          break;
        }
      }

      if (bestBytes == null) {
        return null;
      }

      final thumbnailPath = '${dir.path}/${sessionId}_thumbnail.webp';

      final thumbnailFile = File(thumbnailPath);

      await thumbnailFile.writeAsBytes(bestBytes, flush: true);

      return thumbnailFile;
    } catch (e) {
      return null;
    }
  }

  /// Compress a full-size avatar (800×800) at quality 80
  Future<File?> compressAvatar(String inputPath) async {
    try {
      final originalFile = File(inputPath);
      final originalBytes = await originalFile.readAsBytes();

      if (originalBytes.isEmpty) {
        return null;
      }

      final resultBytes = await _safeCompress(
        originalBytes,
        quality: _avatarQuality,
        minWidth: _avatarDimension,
        minHeight: _avatarDimension,
      );

      if (resultBytes == null) {
        return null;
      }

      final dir = await getTemporaryDirectory();
      final sessionId = DateTime.now().microsecondsSinceEpoch;
      final outputPath = '${dir.path}/${sessionId}_avatar.webp';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(resultBytes, flush: true);

      return outputFile;
    } catch (_) {
      return null;
    }
  }

  /// Create a small avatar thumbnail (160×160) for use in map markers
  Future<File?> createAvatarThumbnail(String inputPath) async {
    try {
      final originalFile = File(inputPath);
      final originalBytes = await originalFile.readAsBytes();

      if (originalBytes.isEmpty) {
        return null;
      }

      int quality = _avatarThumbnailStartQuality;
      Uint8List? bestBytes;

      while (quality >= _avatarThumbnailMinQuality) {
        final resultBytes = await _safeCompress(
          originalBytes,
          quality: quality,
          minWidth: _avatarThumbnailDimension,
          minHeight: _avatarThumbnailDimension,
        );

        if (resultBytes == null) {
          break;
        }

        bestBytes = resultBytes;

        // Already small enough.
        if (resultBytes.length <= _avatarThumbnailTargetMaxBytes) {
          break;
        }

        quality -= 5;
      }

      if (bestBytes == null) {
        return null;
      }

      final dir = await getTemporaryDirectory();
      final sessionId = DateTime.now().microsecondsSinceEpoch;
      final outputPath = '${dir.path}/${sessionId}_avatar_thumbnail.webp';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(bestBytes, flush: true);

      return outputFile;
    } catch (_) {
      return null;
    }
  }

  /// straight format conversion) with EXIF stripped. Used for small files
  /// and as a last-resort fallback. Always writes a webp file if the
  /// encoder succeeds — no longer compares against the original size.
  Future<File?> _stripMetadataOnly(
    Uint8List originalBytes,
    String dirPath,
    int sessionId,
  ) async {
    final resultBytes = await _safeCompress(originalBytes, quality: 100);

    // Only give up and return null if the encoder genuinely can't process
    // this format at all — there's no way to force a webp conversion then.
    if (resultBytes == null) {
      return null;
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
