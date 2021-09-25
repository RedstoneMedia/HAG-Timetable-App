import 'dart:developer';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:tuple/tuple.dart';
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

String? getCharAt(String string, int index, {bool ignoreLength = false}) {
  if (ignoreLength && string.length <= index) {
    return null;
  }
  return string.substring(index, index+1);
}

int getRightLettersCount(String a, String b) {
  final rightLetters = List.generate(a.length > b.length ? a.length : b.length, (i) => i)
      .where((i) => getCharAt(a, i, ignoreLength: true) == getCharAt(b, i, ignoreLength: true))
      .length;
  return rightLetters;
}

String findClosestStringInList(List<String> stringList, String string) {
  final clonedStringList = List<String>.from(stringList);
  clonedStringList.sort((String a, String b) {
    final aRightLetters = getRightLettersCount(string, a);
    final bRightLetters = getRightLettersCount(string, b);
    if (aRightLetters > bRightLetters) return -1;
    return 1;
  });
  return clonedStringList.first;
}

Future<Tuple2<String, String>?> getIServCredentials() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isLinux) {
    FlutterSecureStorage? storage = FlutterSecureStorage();
    final lastSavedString = await storage.read(key: "credentialsLastSaved");
    if (lastSavedString == null) return null; // No credentials are defined
    final lastSaved = DateTime.parse(lastSavedString);
    if (DateTime.now().difference(lastSaved).inDays > 30) {
      await storage.deleteAll();
      return null;
    }
    final userName = await storage.read(key: "username");
    final password = await storage.read(key: "password");
    storage = null;
    return Tuple2(userName!, password!);
  }
}

Future<bool> areIServCredentialsSet() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isLinux) {
    FlutterSecureStorage? storage = FlutterSecureStorage();
    final lastSavedString = await storage.read(key: "credentialsLastSaved");
    if (lastSavedString == null) return false; // No credentials are defined
    storage = null;
    return true;
  }
  return false;
}