import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class PostHeader extends StatelessWidget {
  final String profileImage;
  final String username;
  final String location;

  const PostHeader({
    super.key,
    required this.profileImage,
    required this.username,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(profileImage),
                      onBackgroundImageError: (error, stackTrace) {},
                      backgroundColor: AppColors.gray100,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppColors.gray500,
                            ),
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: AppColors.gray500),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'unfollow',
                      child: Text('Unfollow'),
                    ),

                    const PopupMenuItem(value: 'report', child: Text('Report')),

                    const PopupMenuItem(value: 'block', child: Text('Block')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
