import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:public_pulse/controller/home_controller.dart';

import 'package:public_pulse/view/home/home_page.dart';
import 'package:public_pulse/view/notification/notification_page.dart';
import 'package:public_pulse/view/explore/explore_page.dart';
import 'package:public_pulse/view/profile/profile_page.dart';

import 'package:public_pulse/widget/local/app_bottom_nav.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  final HomeController controller = Get.find<HomeController>();

  /// Home is created immediately.
  /// Other pages are created only when opened for the first time.
  final List<Widget?> pages = [HomePage(), null, null, null];

  Widget _getPage(int index) {
    if (pages[index] != null) {
      return pages[index]!;
    }

    switch (index) {
      case 1:
        pages[1] = ExplorePage();
        break;

      case 2:
        pages[2] = NotificationPage();
        break;

      case 3:
        pages[3] = ProfilePage();
        break;
    }

    return pages[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;

      // Create the selected page only when it is first opened.
      _getPage(index);

      return PopScope(
        canPop: index == 0,

        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            return;
          }

          if (controller.currentIndex.value != 0) {
            controller.currentIndex.value = 0;
          }
        },

        child: Scaffold(
          body: IndexedStack(
            index: index,
            children: pages
                .map((page) => page ?? const SizedBox.shrink())
                .toList(),
          ),

          bottomNavigationBar: AppBottomNavBar(
            currentIndex: index,
            onTap: (newIndex) {
              if (newIndex == index) return;

              controller.currentIndex.value = newIndex;
            },
          ),
        ),
      );
    });
  }
}
