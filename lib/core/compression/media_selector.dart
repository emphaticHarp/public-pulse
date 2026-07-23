import 'package:image_picker/image_picker.dart';

class MediaSelector {
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery
  Future<PickedMedia?> pickImageFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return PickedMedia(path: file.path, isVideo: false);
  }

  /// Pick a video from gallery
  Future<PickedMedia?> pickVideoFromGallery() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    return PickedMedia(path: file.path, isVideo: true);
  }

  /// Take a photo using camera
  Future<PickedMedia?> captureImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;
    return PickedMedia(path: file.path, isVideo: false);
  }

  /// Record a video using camera
  Future<PickedMedia?> captureVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.camera);
    if (file == null) return null;
    return PickedMedia(path: file.path, isVideo: true);
  }
}

/// Simple data holder returned by MediaSelector
class PickedMedia {
  final String path;
  final bool isVideo;

  PickedMedia({required this.path, required this.isVideo});
}