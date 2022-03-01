import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/holiday_calculator.dart';
import 'package:stundenplan/calendar_data.dart';
import 'package:stundenplan/loading_functions.dart';
import 'package:stundenplan/profile_manager.dart';
import 'package:stundenplan/shared_data_store.dart';
import 'package:stundenplan/theme.dart';
import 'package:stundenplan/week_subsitutions.dart';

class SharedState {
  SharedPreferences preferences;
  BuildContext? buildContext;
  Theme theme = darkTheme;
  int? height = Constants.defaultHeight;
  Content content;
  SharedDataStore? sharedDataStore;
  WeekSubstitutions weekSubstitutions = WeekSubstitutions({});
  ProfileManager profileManager = ProfileManager();
  List<int> holidayWeekdays = getHolidayWeekDays();
  CalendarData calendarData = CalendarData();
  bool doUseSharedDataStore = false;

  SharedState(this.preferences, this.content, this.buildContext);

  void saveState() {
    final saveFileData = <String, dynamic>{};

    // Theme
    final themeData = theme.getJsonData();
    saveFileData["theme"] = themeData;
    preferences.setString("theme", jsonEncode(themeData));

    preferences.setBool("doUseSharedDataStore", doUseSharedDataStore);
    saveFileData["doUseSharedDataStore"] = doUseSharedDataStore;

    // Profiles
    profileManager.renameAllProfiles();
    final jsonProfileManagerData = profileManager.getJsonData();
    saveFileData["jsonProfileManagerData"] = jsonProfileManagerData;
    preferences.setString("jsonProfileManagerData", jsonEncode(jsonProfileManagerData));

    // Save theme and profiles to file
    saveToFile(jsonEncode(saveFileData), Constants.saveDataFileLocation);

    preferences.setInt("height", height!);
  }

  Theme themeFromJsonData(dynamic jsonThemeData) {
    return Theme.fromJsonData(jsonThemeData);
  }

  bool loadStateAndCheckIfFirstTime() {
    final String themeDataString = preferences.getString("theme") ?? "dark";
    height = preferences.getInt("height");

    // If first time using app
    if (height == null) {
      height = Constants.defaultHeight;
      return true;
    }
    loadSharedDataStore();
    loadThemeAndProfileManagerFromJson(jsonDecode(themeDataString), jsonDecode(preferences.getString("jsonProfileManagerData")!));
    loadWeekSubstitutions();
    return false;
  }

  void loadThemeAndProfileManagerFromJson(dynamic themeData, dynamic jsonProfileManagerData) {
    theme = Theme.fromJsonData(themeData);
    profileManager = ProfileManager.fromJsonData(jsonProfileManagerData);
  }

  // Content

  void saveCache() {
    // Save week substitutions
    preferences.setString("weekSubstitutions", jsonEncode(weekSubstitutions.toJson()));
    // Save calendar data
    preferences.setString("calendarData", jsonEncode(calendarData.toJson()));
    // Save content
    content.updateLastUpdated();
    log("[SAVED] lastUpdated: ${content.lastUpdated}", name: "cache");
    final encodedContent = jsonEncode(content.toJsonData());
    preferences.setString("cachedContent", encodedContent);
  }

  Future<void> loadSharedDataStore() async {
    doUseSharedDataStore = preferences.getBool("doUseSharedDataStore") == null ? false : preferences.getBool("doUseSharedDataStore")!;
    if ((Platform.isAndroid || Platform.isIOS) && doUseSharedDataStore) {
      if (
        await checkForPermissionsAnShowDialog(
            [Permission.bluetoothAdvertise, Permission.bluetoothConnect, Permission.bluetoothScan, Permission.location],
            "Bluetooth",
            "Die geteilte Datenbank muss in der lage sein Bluetooth zu verwenden, um Daten an andere zu Teilen",
            buildContext!)
      ) {
        sharedDataStore = SharedDataStore(this);
        final sharedDataStoreDataString = preferences.getString("sharedDataStoreData");
        if (sharedDataStoreDataString != null) {
          sharedDataStore?.loadFromJson(jsonDecode(sharedDataStoreDataString));
        }
        await sharedDataStore?.start();
      }
    }
  }

  void loadWeekSubstitutions() {
    // Load week substitutions
    final String weekSubstitutionsJsonString = preferences.get("weekSubstitutions").toString();
    if (weekSubstitutionsJsonString != "") {
      weekSubstitutions = WeekSubstitutions(jsonDecode(weekSubstitutionsJsonString));
    }
  }

  void loadCache() {
    // Load calendar data
    final String calendarDataJsonString = preferences.get("calendarData").toString();
    if (calendarDataJsonString != "") {
      calendarData = CalendarData.fromJson(jsonDecode(calendarDataJsonString) as List<dynamic>);
    }
    // Load content
    final String contentJsonString = preferences.get("cachedContent").toString();
    if (contentJsonString == "") return;
    final decodedJson = jsonDecode(contentJsonString) as List<dynamic>;
    content = Content.fromJsonData(decodedJson);
    log("[LOADED] lastUpdated: ${content.lastUpdated}", name: "cache");
  }

  // Theme
  void setThemeFromThemeName(String themeName) {
    theme = Theme.getThemeFromThemeName(themeName);
  }

  // Default subjects

  List<String> get defaultSubjects {
    for (final schoolGradeList in Constants.defaultSubjectsMap.keys) {
      if (schoolGradeList.contains(profileManager.schoolGrade)) {
        final defaultSubjects =
            List<String>.from(Constants.defaultSubjectsMap[schoolGradeList]!);
        defaultSubjects.addAll(Constants.alwaysDefaultSubjects);
        return defaultSubjects;
      }
    }
    return Constants.alwaysDefaultSubjects;
  }
}
