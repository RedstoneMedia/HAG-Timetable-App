import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/pages/intro/class_selection.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/update_notify.dart';


Future<void> openSetupPageAndCheckForFile(SharedState sharedState, BuildContext context) async {
  // Only load from file when file permissions are granted
  if (await checkForFilePermissionsAndShowDialog(context) == true) {
    await loadProfileManagerAndThemeFromFile(sharedState);
  }
  // Making sure the Frame has been completely drawn and everything has loaded before navigating to new Page
  WidgetsBinding.instance!.addPostFrameCallback((_) {
    // Opening the setupPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ClassSelectionPage(sharedState)),
    );
  });
}

Future<bool> checkForPermissionsAnShowDialog(List<Permission> permissions, String dialogTitle, String dialogText, BuildContext context) async {
  // Most permission are only available on android
  if (!Platform.isAndroid) return false;
  // Check if we have the Permissions
  bool allAccepted = true;
  for (final permission in permissions) {
    allAccepted = allAccepted && await permission.isGranted;
  }
  if (allAccepted) return true;
  // We don't have Permission -> Show a small dialog to explain why we need it
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogText),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ok'),
          ),
        ],
      );
    });
  // Request Permission -> If Permission denied -> return;
  for (final permission in permissions) {
    if (await permission.isDenied) {
      if (await permission.request().isDenied) return false;
    }
  }
  return true;
}

Future<bool> checkForFilePermissionsAndShowDialog(BuildContext context) async {
  return checkForPermissionsAnShowDialog(
      [Permission.storage],
      "Einstellungen Speichern",
      "Diese App benötigt zugriff auf den Speicher deines Gerätes um Fächer und Themes verlässlich zu speichern.",
      context
  );
}

Future<void> loadProfileManagerAndThemeFromFile(SharedState sharedState) async {
  try {
    final String data = await loadFromFile(Constants.saveDataFileLocation);
    // Parse the json
    final jsonData = jsonDecode(data);
    // Load data from json
    sharedState.loadThemeAndProfileManagerFromJson(jsonData["theme"], jsonData["jsonProfileManagerData"]);
  } catch (e) {
    log("Error while loading save data from file", name: "file", error: e);
  }
}

Future<bool> checkForUpdateAndLoadTimetable(UpdateNotifier updateNotifier, SharedState sharedState, BuildContext context) async {
  //TODO: Do something on Windows
  if(!Platform.isWindows) {
    // Check for new App-Version -> if yes -> Show dialog
    await updateNotifier.init().then((value) {
      updateNotifier.checkForNewestVersionAndShowDialog(
          context, sharedState);
    });
  }

  // Parse the Timetable
  try {
    await parsePlans(sharedState)
        .then((value) {
      log("State was set to : ${sharedState.content}", name: "state");
      // Cache the Timetable
      sharedState.saveCache();
    });
  } on TimeoutException catch (e) {
      log("Timeout ! Can't read timetable from Network", name: "network", error: e);
      // Load cached Timetable
      sharedState.loadCache();
      return false;
  } on SocketException catch (e) {
    log("Timeout ! Can't reach page", name: "network", error: e);
    // Load cached Timetable
    sharedState.loadCache();
    return false;
  }
  return true;
}
