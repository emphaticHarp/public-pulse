import 'dart:io';

/// Represents a media item that has been selected but may not yet be
/// compressed or have metadata extracted. Used during the create-post
/// flow so each stage (compression, metadata, upload) can attach its
/// result to the same object.
class PendingMedia {
  /// Absolute local path to the original file the user picked.
  final String originalPath;

  /// Populated after compression. Null means "use the original".
  File? compressedFile;

  /// Populated after metadata extraction. Null means not yet extracted.
  Map<String, dynamic>? metadata;

  PendingMedia({
    required this.originalPath,
    this.compressedFile,
    this.metadata,
  });
}
