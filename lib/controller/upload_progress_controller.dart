import 'package:get/get.dart';

class UploadProgressController extends GetxController {
  /// Overall upload progress from 0.0 to 1.0
  final RxDouble uploadProgress = 0.0.obs;

  /// Display string like "12.5 MB / 50 MB"
  final RxString uploadedSize = '0 MB / 0 MB'.obs;

  /// Display string like "2.3 MB/s"
  final RxString uploadSpeed = '0 MB/s'.obs;

  /// Display string like "Est. 15s remaining"
  final RxString remainingTime = 'Estimating...'.obs;

  /// Current file being uploaded, e.g. "Uploading image 1 of 5"
  final RxString currentFile = ''.obs;

  /// Total number of files to upload
  int _totalFiles = 0;

  /// Index of the current file (1-based)
  int _currentFileIndex = 0;

  /// Type of the current file ("image" or "video")
  String _currentFileType = 'image';

  /// Simulate upload progress for demo / placeholder usage
  void startSimulatedUpload(int totalFiles, {String fileType = 'image'}) {
    _totalFiles = totalFiles;
    _currentFileIndex = 1;
    _currentFileType = fileType;
    _updateCurrentFileLabel();
    uploadProgress.value = 0.0;
  }

  /// Update progress for the current file chunk.
  /// [fileIndex] is 1-based, [progress] is 0.0–1.0 for that single file.
  void updateFileProgress(int fileIndex, double progress, {
    String? fileType,
    int? totalFiles,
  }) {
    if (totalFiles != null) _totalFiles = totalFiles;
    if (fileType != null) _currentFileType = fileType;
    _currentFileIndex = fileIndex;
    _updateCurrentFileLabel();

    // Overall progress: each file contributes 1/totalFiles of the bar
    final overall =
        ((fileIndex - 1) / _totalFiles) + (progress / _totalFiles);
    uploadProgress.value = overall.clamp(0.0, 1.0);
  }

  /// Set uploaded size display
  void updateUploadedSize(String uploaded, String total) {
    uploadedSize.value = '$uploaded / $total';
  }

  /// Set upload speed display
  void updateUploadSpeed(String speed) {
    uploadSpeed.value = speed;
  }

  /// Set remaining time display
  void updateRemainingTime(String time) {
    remainingTime.value = time;
  }

  void _updateCurrentFileLabel() {
    final type = _currentFileType[0].toUpperCase() + _currentFileType.substring(1);
    currentFile.value = 'Uploading $type $_currentFileIndex of $_totalFiles';
  }

  /// Mark the upload as fully complete
  void markComplete() {
    uploadProgress.value = 1.0;
    currentFile.value = 'Upload complete!';
    uploadedSize.value = 'Done';
    uploadSpeed.value = '—';
    remainingTime.value = '—';
  }
}
