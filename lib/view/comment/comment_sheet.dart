import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/comment_controller.dart';
import '../../core/theme/app_colors.dart';
import 'comment_tile.dart';

class CommentSheet extends StatelessWidget {
  final String postId;

  CommentSheet({super.key, required this.postId});

  final CommentController controller = Get.find<CommentController>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * .90,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.greyShade400,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Comments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const Divider(height: 25),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.comments.isEmpty) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.loginAccentRed,
                      ),
                    ),
                  );
                }

                if (controller.comments.isEmpty) {
                  return const Center(
                    child: Text(
                      "No comments yet",
                      style: TextStyle(fontSize: 16, color: AppColors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: controller.comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, index) {
                    return CommentTile(comment: controller.comments[index]);
                  },
                );
              }),
            ),

            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.commentController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        filled: true,
                        fillColor: AppColors.greyShade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  IconButton(
                    onPressed: () {
                      controller.submitComment();
                    },
                    icon: const Icon(
                      Icons.send_rounded,
                      color: AppColors.loginAccentRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
