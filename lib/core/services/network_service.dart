// // This file should only manage connectivity.

// it will check only the internet true or false

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  Future<bool> hasInternetConnection() {
    return _internetChecker.hasInternetAccess;
  }

  Stream<bool> get connectionStream async* {
    await for (final _ in _connectivity.onConnectivityChanged) {
      yield await _internetChecker.hasInternetAccess;
    }
  }
}