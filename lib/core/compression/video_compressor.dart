import 'dart:io';
import 'dart:typed_data';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/foundation.dart';

class VideoCompressor {
  static bool debugLogging = false;

  Subscription listenToProgress(void Function(double) onProgress) {
    return VideoCompress.compressProgress$.subscribe(onProgress);
  }

  Future<File?> compressVideo(String inputPath) async {
    final originalFile = File(inputPath);  
    final originalSize = await originalFile.length();

    final MediaInfo? result = await VideoCompress.compressVideo(
      inputPath,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
      frameRate: 30,
    );

    if (result?.path == null) return null;

    final compressedFile = File(result!.path!);
    await _stripMetadataInPlace(compressedFile);         
    await _normalizeFileTimestamp(compressedFile);

    final compressedSize = await compressedFile.length();
    if (compressedSize >= originalSize) return originalFile;
    return compressedFile;
  }

  void dispose() => VideoCompress.cancelCompression();

  Future<void> _normalizeFileTimestamp(File file) async {
    try {
      await file.setLastModified(DateTime.utc(1970, 1, 1));
    } catch (_) {}
  }

  // ===========================================================================
  // METADATA STRIPPING + CHUNK-OFFSET REPAIR

  static const _metadataBoxTypes = {'udta', 'meta', 'uuid'};
  static const _containerBoxTypes = {
    'moov',
    'trak',
    'mdia',
    'minf',
    'stbl',
    'edts',
    'mvex',
    'moof',
    'traf',
    'dinf',
  };
  static const _timestampBoxTypes = {'mvhd', 'tkhd', 'mdhd'};

  Future<void> _stripMetadataInPlace(File file) async {
    try {
      final original = await file.readAsBytes();
      final cleaned = _processFile(original);
      await file.writeAsBytes(cleaned, flush: true);
    } catch (e) {
      if (debugLogging) {
        debugPrint('VideoCompressor: metadata stripping skipped — $e');
      }
    }
  }

  /// Entry point: walks the file once, then repairs chunk offsets if moov
  /// shrank and originally sat before mdat (moov/mdat are always top-level
  /// per the ISOBMFF spec, so a single tracker suffices — no separate
  /// top-level pass is needed).
  Uint8List _processFile(Uint8List data) {
    final tracker = _MoovTracker();
    final result = _walkBoxes(data, tracker: tracker);

    if (tracker.delta != 0 &&
        tracker.moovOrigStart != null &&
        tracker.mdatOrigStart != null &&
        tracker.moovOrigStart! < tracker.mdatOrigStart!) {
      _shiftChunkOffsets(
        result,
        tracker.moovOutputStart,
        tracker.moovOutputLength,
        tracker.delta,
      );
    }
    return result;
  }

  /// Single recursive walker used for every level of the box tree.
  /// - Deletes udta/meta/uuid (privacy metadata) wherever they appear.
  Uint8List _walkBoxes(Uint8List data, {_MoovTracker? tracker}) {
    final output = BytesBuilder(copy: false);
    int offset = 0;

    while (offset < data.length) {
      final header = _readBoxHeader(data, offset);
      if (header == null) {
        output.add(_view(data, offset, data.length - offset));
        break;
      }
      final type = header.type;
      final boxSize = header.boxSize;
      final headerSize = header.headerSize;

      if (_metadataBoxTypes.contains(type)) {
        offset += boxSize;
        continue;
      }

      if (type == 'mdat') {
        tracker?.mdatOrigStart ??= offset;
        output.add(_view(data, offset, boxSize));
        offset += boxSize;
        continue;
      }

      if (_timestampBoxTypes.contains(type)) {
        final boxBytes = data.sublist(offset, offset + boxSize);
        output.add(_zeroTimestamps(boxBytes, headerSize));
        offset += boxSize;
        continue;
      }

      if (_containerBoxTypes.contains(type)) {
        final children = _walkBoxes(
          _view(data, offset + headerSize, boxSize - headerSize),
        );
        final newBox =
            (BytesBuilder()
                  ..add(
                    _buildBoxHeader(
                      type,
                      headerSize + children.length,
                      use64: header.use64,
                    ),
                  )
                  ..add(children))
                .takeBytes();

        if (tracker != null && type == 'moov') {
          tracker.moovOrigStart = offset;
          tracker.moovOutputStart = output.length;
          tracker.moovOutputLength = newBox.length;
          tracker.delta = boxSize - newBox.length;
        }

        output.add(newBox);
        offset += boxSize;
        continue;
      }

      output.add(_view(data, offset, boxSize)); // ftyp, free, wide, etc.
      offset += boxSize;
    }

    return output.takeBytes();
  }

  /// Shifts every stco/co64 entry in data[start..start+length] back by [delta].
  /// Mutates in place — safe, since `data` is a freshly assembled buffer.
  void _shiftChunkOffsets(Uint8List data, int start, int length, int delta) {
    int offset = start;
    final end = start + length;

    while (offset < end) {
      final header = _readBoxHeader(data, offset);
      if (header == null) break;

      if (header.type == 'stco') {
        _rewriteOffsets(data, offset + header.headerSize, delta, is64: false);
      } else if (header.type == 'co64') {
        _rewriteOffsets(data, offset + header.headerSize, delta, is64: true);
      } else if (_containerBoxTypes.contains(header.type)) {
        _shiftChunkOffsets(
          data,
          offset + header.headerSize,
          header.boxSize - header.headerSize,
          delta,
        );
      }
      offset += header.boxSize;
    }
  }

  void _rewriteOffsets(
    Uint8List data,
    int bodyStart,
    int delta, {
    required bool is64,
  }) {
    final entryCount = _readUint32(data, bodyStart + 4);
    final entrySize = is64 ? 8 : 4;
    int pos = bodyStart + 8;

    for (int i = 0; i < entryCount; i++) {
      if (is64) {
        _writeUint64(data, pos, _readUint64(data, pos) - delta);
      } else {
        _writeUint32(data, pos, _readUint32(data, pos) - delta);
      }
      pos += entrySize;
    }
  }

  Uint8List _zeroTimestamps(Uint8List boxBytes, int headerSize) {
    final versionOffset = headerSize;
    if (boxBytes.length < versionOffset + 4) return boxBytes;
    final version = boxBytes[versionOffset];
    final fieldSize = version == 1 ? 8 : 4;
    final creationOffset = versionOffset + 4;
    final modificationOffset = creationOffset + fieldSize;
    if (boxBytes.length < modificationOffset + fieldSize) return boxBytes;

    for (int i = 0; i < fieldSize; i++) {
      boxBytes[creationOffset + i] = 0;
      boxBytes[modificationOffset + i] = 0;
    }
    return boxBytes;
  }

  // ---- shared low-level helpers ----

  ({String type, int boxSize, int headerSize, bool use64})? _readBoxHeader(
    Uint8List data,
    int offset,
  ) {
    if (offset + 8 > data.length) return null;
    final size32 = _readUint32(data, offset);
    final type = String.fromCharCodes(
      data.buffer.asUint8List(data.offsetInBytes + offset + 4, 4),
    );

    int boxSize = size32;
    int headerSize = 8;
    bool use64 = false;

    if (size32 == 1) {
      if (offset + 16 > data.length) return null;
      boxSize = _readUint64(data, offset + 8);
      headerSize = 16;
      use64 = true;
    } else if (size32 == 0) {
      boxSize = data.length - offset;
    }
    if (boxSize < headerSize || offset + boxSize > data.length) return null;

    return (type: type, boxSize: boxSize, headerSize: headerSize, use64: use64);
  }

  Uint8List _view(Uint8List data, int offset, int length) =>
      Uint8List.view(data.buffer, data.offsetInBytes + offset, length);

  int _readUint32(Uint8List d, int o) =>
      (d[o] << 24) | (d[o + 1] << 16) | (d[o + 2] << 8) | d[o + 3];
  int _readUint64(Uint8List d, int o) =>
      (_readUint32(d, o) << 32) | _readUint32(d, o + 4);

  void _writeUint32(Uint8List d, int o, int value) {
    d[o] = (value >> 24) & 0xFF;
    d[o + 1] = (value >> 16) & 0xFF;
    d[o + 2] = (value >> 8) & 0xFF;
    d[o + 3] = value & 0xFF;
  }

  void _writeUint64(Uint8List d, int o, int value) {
    _writeUint32(d, o, (value >> 32) & 0xFFFFFFFF);
    _writeUint32(d, o + 4, value & 0xFFFFFFFF);
  }

  Uint8List _buildBoxHeader(String type, int size, {bool use64 = false}) {
    final b = BytesBuilder();
    if (!use64) {
      b.add(_u32(size));
      b.add(type.codeUnits);
    } else {
      b.add(_u32(1));
      b.add(type.codeUnits);
      b.add(_u64(size));
    }
    return b.takeBytes();
  }

  List<int> _u32(int v) => [
    (v >> 24) & 0xFF,
    (v >> 16) & 0xFF,
    (v >> 8) & 0xFF,
    v & 0xFF,
  ];
  List<int> _u64(int v) => [
    (v >> 56) & 0xFF,
    (v >> 48) & 0xFF,
    (v >> 40) & 0xFF,
    (v >> 32) & 0xFF,
    (v >> 24) & 0xFF,
    (v >> 16) & 0xFF,
    (v >> 8) & 0xFF,
    v & 0xFF,
  ];
}

/// Tracks moov/mdat positions during the top-level walk so the chunk-offset
/// repair step knows whether a shift is needed and by how much.
class _MoovTracker {
  int? moovOrigStart;
  int? mdatOrigStart;
  int moovOutputStart = 0;
  int moovOutputLength = 0;
  int delta = 0;
}
