import 'dart:developer';
import 'dart:io';
import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

Future<void> setIServSessionCookies(String sessionCookies) async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isLinux) {
    const storage = FlutterSecureStorage();
    return storage.write(key: "sessionCookies", value: sessionCookies);
  }
}

Future<String?> getIServSessionCookies() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isLinux) {
    const storage = FlutterSecureStorage();
    final lastLoadedTime = await updateLastLoaded(storage);
    if (lastLoadedTime == null) return null;
    // Session cookies are too old
    if (lastLoadedTime.difference(DateTime.now()).inHours > 3) {
      await storage.delete(key: "sessionCookies");
      return null;
    }
    return storage.read(key: "sessionCookies");
  }
  return null;
}

Future<DateTime?> updateLastLoaded(FlutterSecureStorage storage) async {
  final lastLoadedString = await storage.read(key: "credentialsLastLoaded");
  if (lastLoadedString == null) return null;
  // Delete credentials if they haven't been loaded in roughly half a year
  final lastLoaded = DateTime.parse(lastLoadedString);
  if (DateTime.now().difference(lastLoaded).inDays > 178) {
    log("Credentials have expired", name: "credentials");
    await storage.deleteAll();
    return null;
  }
  await storage.write(key: "credentialsLastLoaded", value: DateTime.now().toIso8601String());
  return lastLoaded;
}

Future<Tuple2<String, String>?> getIServCredentials() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isLinux) {
    FlutterSecureStorage? storage = const FlutterSecureStorage();
    if (await updateLastLoaded(storage) == null) return null;
    final userName = await storage.read(key: "username");
    final password = await storage.read(key: "password");
    storage = null;
    return Tuple2(userName!, password!);
  }
  return null;
}

Future<bool> areIServCredentialsSet() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isLinux) {
    FlutterSecureStorage? storage = const FlutterSecureStorage();
    final lastSavedString = await storage.read(key: "credentialsLastLoaded");
    if (lastSavedString == null) return false; // No credentials are defined
    storage = null;
    return true;
  }
  return false;
}

Tuple2<DateTime, DateTime> getCurrentWeekStartEndDates() {
  DateTime now = clock.now();
  if (now.weekday > 5) now = now.add(const Duration(days: 2));
  DateTime weekStartDate = now.subtract(Duration(days: now.weekday-1));
  weekStartDate = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day); // Strip out time, to just keep the date
  return Tuple2(weekStartDate, weekStartDate.add(const Duration(days: 6)));
}

extension StringExtension on String {
  /// Truncate a string if it's longer than [maxLength] and add an [ellipsis].
  String truncate(int maxLength, [String ellipsis = "…"]) => length > maxLength
      ? '${substring(0, maxLength - ellipsis.length)}$ellipsis'
      : this;
}