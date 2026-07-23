import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/controller/network_controller.dart';
import 'package:public_pulse/widget/local/app_no_internet_indicator.dart';

class NetworkWrapper extends StatelessWidget {
  final Widget child;

  const NetworkWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final NetworkController controller = Get.find<NetworkController>();

    return Obx(() {
      return SafeArea(
        child: controller.isConnected.value ? child : const NoInternetWidget(),
      );
    });
  }
}
