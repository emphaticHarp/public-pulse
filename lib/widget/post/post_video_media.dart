import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostVideoMedia extends StatefulWidget {
  final String videoUrl;

  const PostVideoMedia({super.key, required this.videoUrl});

  @override
  State<PostVideoMedia> createState() => _PostVideoMediaState();
}

class _PostVideoMediaState extends State<PostVideoMedia> {
  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 4 / 5,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Toggle play and pause when the user taps the video.

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: GestureDetector(
        onTap: () {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }

          setState(() {});
        },
        child: VideoPlayer(_controller),
      ),
    );
  }

  // Controls video playback (play, pause, seek, etc.).
  late VideoPlayerController _controller;

  // Runs once when the widget is created.
  @override
  void initState() {
    super.initState();

    // Create a video controller using the network video URL.
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    // Keep replaying the video automatically after it finishes.
    _controller.setLooping(true);

    // Load the video, then rebuild the widget when it's ready.
    _controller.initialize().then((_) {
      _controller.play();

      setState(() {});
    });
  }

  // Release the video player resources when the widget is removed.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
