import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:public_pulse/controller/home_controller.dart';

import 'package:public_pulse/view/home/home_page.dart';
import 'package:public_pulse/view/notification/notification_page.dart';
import 'package:public_pulse/view/community/community_page.dart';
import 'package:public_pulse/view/profile/profile_page.dart';

import 'package:public_pulse/widget/local/app_bottom_nav.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  final HomeController controller = Get.find<HomeController>();

  // Lazily create each page only when it is opened for the first time, then keep it in memory.
  final List<Widget?> pages = [HomePage(), null, null, null];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: Builder(
          builder: (_) {
            final index = controller.currentIndex.value;

            // Create the page only the first time it is opened.
            if (pages[index] == null) {
              switch (index) {
                case 1:
                  pages[1] = const CommunityPage();
                  break;

                case 2:
                  pages[2] =  NotificationPage(); // was ReelsPage
                  break;

                case 3:
                  pages[3] = const ProfilePage();
                  break;
              }
            }

            return IndexedStack(
              index: index,
              children: pages.map((page) => page ?? const SizedBox()).toList(),
            );
          },
        ),

        bottomNavigationBar: AppBottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: (index) {
            controller.currentIndex.value = index;
          },
        ),
      ),
    );
  }
}