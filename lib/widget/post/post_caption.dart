import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class PostCaption extends StatelessWidget {
  final String username;
  final String caption;
  final String commentCount;

  const PostCaption({
    super.key,
    required this.username,
    required this.caption,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: AppColors.gray900),
              children: [
                TextSpan(
                  text: '$username  ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: caption),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View all comments ($commentCount)',
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}