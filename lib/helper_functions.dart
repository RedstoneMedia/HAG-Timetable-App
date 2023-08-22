import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/pages/setup_page.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:tuple/tuple.dart';

Future<bool> isInternetAvailable(Connectivity connectivity) async {
  //TODO: Check on Windows
  if (!kIsWeb && Platform.isWindows) return true;
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

Future<PermissionStatus> requestStorage() async {
  final info = await DeviceInfoPlugin().androidInfo;
  if (info.version.sdkInt >= 30) {
    return Permission.manageExternalStorage.request();
  } else {
    return Permission.storage.request(); // Deprecated but needed for older phones
  }
}

Future<void> tryMoveFile(String from, String to) async {
  try {
    final String oldData = await loadFromFile(from);
    await saveToFile(oldData, to);
    await File(from).delete();
  } catch (e) {
    log("Error while moving from '$from' to '$to'", name: "file", error: e);
  }
}

Future<void> saveToFile(String data, String path) async {
  // This function uses root-level file access, which is only available on android
  if (kIsWeb) return;
  if (!Platform.isAndroid) return;
  // Check if we have the storage Permission
  if (await requestStorage().isDenied) return;

  try {
    final File saveFile = File(path);
    if (!(await saveFile.exists())) {
      await saveFile.create();
    }
    await saveFile.writeAsString(data);
  } catch (e) {
    log("Error while writing to file at '$path'", name: "file", error: e);
  }
}

Future<String> loadFromFile(String path) async {
  // This function uses root-level file access, which is only available on android
  if (kIsWeb) throw const OSError("Root-level file access is only available on android");
  if (!Platform.isAndroid) throw const OSError("Root-level file access is only available on android");
  // Check if we have the storage Permission
  if (await requestStorage().isDenied) throw const OSError("Storage access is denied");

  // Create a reference to the File
  final File saveFile = File(path);
  // Read from the File
  return saveFile.readAsString();
}

Future<void> saveToFileArchived(String data, String path) async {
  if (kIsWeb) return;
  if (!Platform.isAndroid) return;
  // Check if we have the storage Permission
  if (await requestStorage().isDenied) return;
  // Compress data with gzip
  final compressedData = GZipEncoder().encode(utf8.encode(data));
  // Save to file: same code as `loadFromFile`
  try {
    final File saveFile = await File(path).create(recursive: true);
    await saveFile.writeAsBytes(compressedData!);
  } catch (e) {
    log("Error while writing archive to file at '$path'", name: "file", error: e);
  }
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

bool canUseSecureStorage() {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isWindows;
}

Future<void> setIServSessionCookies(String sessionCookies) async {
  if (canUseSecureStorage()) {
    const storage = FlutterSecureStorage();
    return storage.write(key: "sessionCookies", value: sessionCookies);
  }
}

Future<String?> getIServSessionCookies() async {
  if (canUseSecureStorage()) {
    const storage = FlutterSecureStorage();
    final lastLoadedTime = await updateLastLoaded(storage);
    if (lastLoadedTime == null) return null;
    // Session cookies are too old
    if (DateTime.now().difference(lastLoadedTime) > Constants.loginSessionExpireDuration) {
      await storage.delete(key: "sessionCookies");
      return null;
    }
    return storage.read(key: "sessionCookies");
  }
  return null;
}

Future<void> setSchulmanagerJWT(String jwt) async {
  if (canUseSecureStorage()) {
    const storage = FlutterSecureStorage();
    return storage.write(key: "schulmanagerJWT", value: jwt);
  }
}

Future<String?> getSchulmanagerJWT() async {
  if (canUseSecureStorage()) {
    const storage = FlutterSecureStorage();
    final jwt = await storage.read(key: "schulmanagerJWT");
    if (jwt == null) return null;
    final jwtComponents = jwt.split(".");
    if (jwtComponents.length != 3) return null;
    var jwtBase64String = jwtComponents[1];
    Uint8List? payloadBytes = null;
    // I honestly have no Idea how base64 padding works so this will just have to do
    for (var i = 0; i <= 2; i++) {
      try {
        payloadBytes = base64Decode(jwtBase64String);
      } on FormatException {
        jwtBase64String += "=";
      }
    }
    if (payloadBytes == null) {
      log("Could not decode jwt base64 payload", name: "credential", level: 2);
      return null;
    }
    final payloadJson = String.fromCharCodes(payloadBytes);
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    final expireUNIXTimestamp = payload["exp"] as int;
    final expireTime = DateTime.fromMillisecondsSinceEpoch(expireUNIXTimestamp * 1000);
    if (DateTime.now().isAfter(expireTime)) {
      log("Schulmanager JWT has expired", name: "credentials");
      await storage.delete(key: "schulmanagerJWT");
      return null;
    }
    return jwt;
  }
  return null;
}

Future<DateTime?> updateLastLoaded(FlutterSecureStorage storage) async {
  final lastLoadedString = await storage.read(key: "credentialsLastLoaded");
  if (lastLoadedString == null) return null;
  // Delete credentials if they haven't been loaded in roughly half a year
  final lastLoaded = DateTime.parse(lastLoadedString);
  if (DateTime.now().difference(lastLoaded) > Constants.credentialExpireDuration) {
    log("Credentials have expired", name: "credentials");
    if (kIsWeb) await storage.deleteAll();
    if (Platform.isWindows) {
      await storage.delete(key: "username");
      await storage.delete(key: "password");
      await storage.delete(key: "sessionCookies");
      await storage.delete(key: "schulmanagerJWT");
      await storage.delete(key: "credentialsLastLoaded");
    } else {
      await storage.deleteAll();
    }
    return null;
  }
  await storage.write(key: "credentialsLastLoaded", value: DateTime.now().toIso8601String());
  return lastLoaded;
}

Future<Tuple2<String, String>?> getIServCredentials() async {
  if (canUseSecureStorage()) {
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
  if (canUseSecureStorage()) {
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