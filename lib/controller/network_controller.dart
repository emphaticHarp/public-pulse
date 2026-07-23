import 'dart:async';

import 'package:get/get.dart';
import 'package:public_pulse/core/services/network_service.dart';

class NetworkController extends GetxController {
  final NetworkService _networkService = NetworkService();

  final RxBool isConnected = true.obs;

  late StreamSubscription<bool> _connectionSubscription;

  @override
  void onInit() {
    super.onInit();

    _checkInitialConnection();
    _listenToConnectionChanges();
  }

  Future<void> _checkInitialConnection() async {
    isConnected.value = await _networkService.hasInternetConnection();
  }

  void _listenToConnectionChanges() {
    _connectionSubscription =
        _networkService.connectionStream.listen((status) {
      isConnected.value = status;
    });
  }

  @override
  void onClose() {
    _connectionSubscription.cancel();
    super.onClose();
  }
}