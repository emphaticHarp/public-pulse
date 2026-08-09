import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/controller/explore_controller.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/view/profile/user_profile_page.dart';

class ExplorePage extends StatelessWidget {
  ExplorePage({super.key});

  final ExploreController controller = Get.put(ExploreController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Explore",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search users",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() {
                /// Show recent searches when search box is empty
                if (controller.searchText.value.isEmpty) {
                  if (controller.recentSearches.isEmpty) {
                    return const Center(
                      child: Text(
                        "No recent searches",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.recentSearches.length,
                    itemBuilder: (_, index) {
                      final profile = controller.recentSearches[index];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profile.avatarPath != null
                              ? NetworkImage(
                                  controller.avatarUrl(profile.avatarPath),
                                )
                              : null,
                          child: profile.avatarPath == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(profile.displayName ?? ''),
                        subtitle: Text("@${profile.username}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            controller.removeRecentSearch(profile);
                          },
                        ),
                       onTap: () {
  Get.to(
    () => UserProfilePage(
      userId: profile.userId,
    ),
  );
},
                      );
                    },
                  );
                }

                /// Search Results
                if (controller.searchResults.isEmpty) {
                  return const Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.searchResults.length,
                  itemBuilder: (_, index) {
                    final profile = controller.searchResults[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profile.avatarPath != null
                            ? NetworkImage(
                                controller.avatarUrl(profile.avatarPath),
                              )
                            : null,
                        child: profile.avatarPath == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(profile.displayName ?? ''),
                      subtitle: Text("@${profile.username}"),
                      onTap: () {
                        controller.openProfile(profile);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
