import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:public_pulse/controller/comment_controller.dart';
import 'package:public_pulse/model/comment_model.dart';
import 'package:public_pulse/widget/post/instagram_comment_menu.dart';
import 'package:public_pulse/widget/local/app_alerts.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;

  const CommentTile({super.key, required this.comment});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";

    return "${date.day}/${date.month}/${date.year}";
  }

  void _confirmDelete(BuildContext context, CommentController controller) async {
    final confirmed = await CustomAlert.showConfirm(
      title: 'Delete Comment?',
      message: 'This action cannot be undone.',
      icon: Icons.delete_outline_rounded,
      color: AppColors.loginAccentRed,
      confirmText: 'Delete',
    );
    if (confirmed) {
      controller.deleteComment(comment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommentController>();
    final isOwner = controller.currentProfileId == comment.profileId;

   final tileContent = Padding(
  padding: const EdgeInsets.symmetric(
    vertical: 10,
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
        CircleAvatar(
          radius: 18,
          backgroundImage:
              comment.profileImage != null && comment.profileImage!.isNotEmpty
              ? NetworkImage(comment.profileImage!)
              : null,
          child: (comment.profileImage == null || comment.profileImage!.isEmpty)
              ? const Icon(Icons.person, size: 18)
              : null,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: comment.username,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const TextSpan(text: "  "),
                    TextSpan(
                      text: comment.content,
                      style: const TextStyle(
                        color: AppColors.black87,
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Text(
                    _timeAgo(comment.createdAt),
                    style: TextStyle(fontSize: 12, color: AppColors.greyShade600),
                  ),

                  if (comment.isPending) ...[
                    const SizedBox(width: 8),
                    Text(
                      "Sending...",
                      style: TextStyle(
                        color: AppColors.greyShade500,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

      ],
    ),
  );

    if (comment.isPending) {
      return tileContent;
    }

    return CommentLongPressMenu(
      isOwner: isOwner,
      commentText: comment.content,
      authorName: comment.username,

      avatar: CircleAvatar(
        radius: 18,
        backgroundImage:
            comment.profileImage != null && comment.profileImage!.isNotEmpty
            ? NetworkImage(comment.profileImage!)
            : null,
        child: (comment.profileImage == null || comment.profileImage!.isEmpty)
            ? const Icon(Icons.person, size: 18)
            : null,
      ),

      onEdit: (newText) async {
        await controller.editComment(comment.id, newText);
      },

      onDelete: () async {
        _confirmDelete(context, controller);
      },

      child: tileContent,
    );
  }
}
