import 'package:flutter/material.dart';
import '../../model/comment_model.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;

  const CommentTile({
    super.key,
    required this.comment,
  });

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: comment.profileImage != null &&
                  comment.profileImage!.isNotEmpty
              ? NetworkImage(comment.profileImage!)
              : null,
          child: (comment.profileImage == null ||
                  comment.profileImage!.isEmpty)
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
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

        const Icon(
          Icons.favorite_border,
          size: 18,
          color: Colors.grey,
        ),
      ],
    );
  }
}