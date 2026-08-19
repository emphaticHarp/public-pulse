import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class PostCaption extends StatelessWidget {
  final String username;
  final String caption;

  const PostCaption({super.key, required this.username, required this.caption});

  @override
  Widget build(BuildContext context) {
    final text = caption.trim();

    // If caption is empty, show nothing.
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: AppColors.gray900),
          children: [
            TextSpan(
              text: '$username  ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
