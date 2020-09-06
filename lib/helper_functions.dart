import 'package:flutter/material.dart';
import 'pages/setup_page.dart';
import 'package:connectivity/connectivity.dart';

Future<bool> isInternetAvailable(connectivity) async {
  var result = await connectivity.checkConnectivity();
  return result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;
}

void showSettingsWindow(context, sharedState) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SetupPage(sharedState)),
  );
}