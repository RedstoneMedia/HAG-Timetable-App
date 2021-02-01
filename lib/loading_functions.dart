import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/update_notify.dart';

import 'pages/setup_page.dart';
import 'profile_manager.dart';

Future<void> openSetupPageAndCheckForFiles(SharedState sharedState, BuildContext context) async {
  await loadProfileManagerAndThemeFromFiles(sharedState, context);
  //Making sure the Frame has been completely drawn and everything has loaded before navigating to new Page
  WidgetsBinding.instance.addPostFrameCallback((_) {
    //Opening the setupPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SetupPage(sharedState)),
    );

  });
}

Future<void> loadProfileManagerAndThemeFromFiles(SharedState sharedState, BuildContext context) async {
  //This function uses root-level file access, which is only available on android
  if (!Platform.isAndroid) return;
  //Check if we have the storage Permission
  if (await Permission.storage.isDenied || await Permission.storage.isUndetermined) {
    //We don't have Permission -> Show a small dialog to explain why we need it
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Einstellungen Speichern"),
            content: const Text(
                "Diese App benötigt zugriff auf den Speicher deines Gerätes um Fächer und Themes verlässlich zu speichern."),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ok'),
              ),

            ],
          );
        });
    //Request Permission -> If Permission denied -> return;
    if (await Permission.storage.request().isDenied) return;
  }
  try {
    //Create a reference to the File
    final File saveFile =
    File("/storage/emulated/0/Android/data/stundenplan-profileData.save");

    //Read from the File
    final String data = await saveFile.readAsString();

    //Parse the data and load it as profileManager
    sharedState.profileManager =
        ProfileManager.fromJsonData(jsonDecode(data));
  } catch (e) {
    print("Error while loading profileData:\n$e");
  }

  try {
    //Create a reference to the File
    final File saveFile =
    File("/storage/emulated/0/Android/data/stundenplan-themeData.save");

    //Read from the File
    final String data = await saveFile.readAsString();

    //Parse the data and load it as theme
    sharedState.theme = sharedState.themeFromJsonData(jsonDecode(data));
  } catch (e) {
    print("Error while loading themeData:\n$e");
  }
}

Future<bool> checkForUpdateAndLoadTimetable(UpdateNotifier updateNotifier, SharedState sharedState, BuildContext context) async {
  //Check for new App-Version -> if yes -> Show dialog
  await updateNotifier.init().then((value) {
    updateNotifier.checkForNewestVersionAndShowDialog(
        context, sharedState);
  });

  //Parse the Timetable
  try {
    await parsePlans(sharedState.content, sharedState)
        .then((value) {
      // ignore: avoid_print
      print(
          "State was set to : ${sharedState.content}"); //TODO: Remove Debug Message

      //Cache the Timetable
      sharedState.saveContent();
      return false;
    });
  } on TimeoutException catch (_) {
      print("Timeout !");
      //Load cached Timetable
      sharedState.loadContent();
      return false;
  }
  return true;
}
