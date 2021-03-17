import 'dart:developer';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stundenplan/shared_state.dart';
import 'pages/setup_page.dart';

Future<bool> isInternetAvailable(Connectivity connectivity) async {
  //TODO: Check on Windows
  if(Platform.isWindows) return true;
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

Future<void> saveToFile(String data, String path) async {
  // This function uses root-level file access, which is only available on android
  if (!Platform.isAndroid) return;
  // Check if we have the storage Permission
  if (await Permission.storage.request().isDenied) return;

  try {
    final File saveFile = File(path);
    await saveFile.writeAsString(data);
  } catch (e) {
    log("Error while writing to file at '$path'", name: "file", error: e);
  }
}

Future<String> loadFromFile(String path) async {
  // This function uses root-level file access, which is only available on android
  if (!Platform.isAndroid) throw const OSError("Root-level file access is only available on android");
  // Check if we have the storage Permission
  if (await Permission.storage.request().isDenied) throw const OSError("Storage access is denied");

  // Create a reference to the File
  final File saveFile = File("/storage/emulated/0/Android/data/stundenplan-data.save");
  // Read from the File
  return saveFile.readAsString();
}