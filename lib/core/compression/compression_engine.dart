import 'dart:io';
import 'package:video_compress/video_compress.dart' show Subscription;
import 'image_compressor.dart';
import 'video_compressor.dart';

/// THE BRAIN.
class CompressionEngine {
  final ImageCompressor _imageCompressor = ImageCompressor();
  final VideoCompressor _videoCompressor = VideoCompressor();

  Subscription listenToVideoProgress(void Function(double) onProgress) {
    return _videoCompressor.listenToProgress(onProgress);
  }

  Future<CompressionResult?> compress(String path, bool isVideo) async {
    final originalFile = File(path);
    final originalSize = await originalFile.length();

    final File? compressedFile = isVideo
        ? await _videoCompressor.compressVideo(path)
        : await _imageCompressor.compressImage(path);

    if (compressedFile == null) return null;

    final compressedSize = await compressedFile.length();

    return CompressionResult(
      originalFile: originalFile,
      compressedFile: compressedFile,
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedSize,
      isVideo: isVideo,
    );
  }

  void dispose() {
    _videoCompressor.dispose();
  }
}

/// Holds everything the UI needs to show a before/after comparison.
class CompressionResult {
  final File originalFile;
  final File compressedFile;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final bool isVideo;

  CompressionResult({
    required this.originalFile,
    required this.compressedFile,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.isVideo,
  });

  double get originalMB => originalSizeBytes / 1024 / 1024;
  double get compressedMB => compressedSizeBytes / 1024 / 1024;

  double get percentSaved {
    if (originalSizeBytes == 0) return 0;
    return 100 - (compressedSizeBytes / originalSizeBytes * 100);
  }
}