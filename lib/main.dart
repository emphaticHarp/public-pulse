import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'view/auth/splash_screen_page.dart';

import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/controller/network_controller.dart';
import 'package:public_pulse/controller/notification_controller.dart';
import 'package:public_pulse/controller/profile_controller.dart';
import 'package:public_pulse/controller/login_controller.dart';

import 'package:public_pulse/core/cache/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final url = dotenv.env['SUPABASE_URL'];
  final key = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

  if (url == null || key == null) {
    throw Exception('Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY in .env');
  }

  await Supabase.initialize(url: url, anonKey: key);
  // Initialize Hive and open cache boxes for offline storage.
  await HiveService.init();

  Get.put(AuthService(), permanent: true);

  Get.put(NetworkController());
  Get.lazyPut<HomeController>(() => HomeController());
  Get.lazyPut<LoginController>(() => LoginController());
  Get.lazyPut<NotificationController>(() => NotificationController());
  Get.lazyPut<ProfileController>(() => ProfileController());
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
      home: SplashScreenPage(),
    );
  }
}
