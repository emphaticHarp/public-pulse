import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';

import '../../controller/comment_controller.dart';
import '../../model/comment_model.dart';

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

  void _confirmDelete(BuildContext context, CommentController controller) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Delete Comment?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                "This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.deleteComment(comment.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommentController>();
    final isOwner = controller.currentProfileId == comment.profileId;

    final tileContent = Row(
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
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const TextSpan(text: "  "),
                    TextSpan(
                      text: comment.content,
                      style: const TextStyle(
                        color: Colors.black87,
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  if (comment.isPending) ...[
                    const SizedBox(width: 8),
                    Text(
                      "Sending...",
                      style: TextStyle(
                        color: Colors.grey.shade500,
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

        const SizedBox(width: 10),

        const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
      ],
    );

    // Only the comment owner gets edit/delete, and never on a pending comment
    if (!isOwner || comment.isPending) {
      return tileContent;
    }

    return PieMenu(
      actions: [
        PieAction(
          tooltip: const Text("Edit"),
          buttonTheme: const PieButtonTheme(
            backgroundColor: Color(0xFF2563EB),
            iconColor: Colors.white,
          ),
          onSelect: () => controller.startEditing(comment),
          child: const Icon(Icons.edit_rounded),
        ),

        PieAction(
          tooltip: const Text("Delete"),
          buttonTheme: const PieButtonTheme(
            backgroundColor: Color(0xFFDC2626),
            iconColor: Colors.white,
          ),
          onSelect: () => _confirmDelete(context, controller),
          child: const Icon(Icons.delete_rounded),
        ),
      ],
      child: tileContent,
    );
  }
}
