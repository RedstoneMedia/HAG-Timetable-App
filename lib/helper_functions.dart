import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:stundenplan/shared_state.dart';
import 'pages/setup_page.dart';

Future<bool> isInternetAvailable(Connectivity connectivity) async {
  final result = await connectivity.checkConnectivity();
  return result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi;
}

void showSettingsWindow(BuildContext context, SharedState sharedState) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SetupPage(sharedState)),
  );
}
