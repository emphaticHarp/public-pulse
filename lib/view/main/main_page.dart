import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:public_pulse/controller/home_controller.dart';

import 'package:public_pulse/view/home/home_page.dart';
import 'package:public_pulse/view/reels/reels_page.dart';
import 'package:public_pulse/view/community/community_page.dart';
import 'package:public_pulse/view/profile/profile_page.dart';

import 'package:public_pulse/widget/local/app_bottom_nav.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  final HomeController controller = Get.find<HomeController>();

  final List<Widget> pages = [
    HomePage(),
    const CommunityPage(),
    const ReelsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: pages,
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