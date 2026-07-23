import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


import 'view/auth/splash_screen_page.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/controller/network_controller.dart';
import 'package:public_pulse/controller/notification_controller.dart';
import 'package:public_pulse/controller/login_controller.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

   await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Get.put(NetworkController()); //This creates the NetworkController.
  Get.put(HomeController()); //This creates the HomeController.
  Get.lazyPut<LoginController>(() => LoginController());

 Get.put(NotificationController()); 
  runApp(const PublicPulseApp());
}

class PublicPulseApp extends StatelessWidget {
  const PublicPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Public Pulse',
      theme: ThemeData(fontFamily: 'Poppins', useMaterial3: true),
      home: const SplashScreenPage(),
    );
  }

  
}
