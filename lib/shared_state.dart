import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/holiday_calculator.dart';
import 'package:stundenplan/calendar_data.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/profile_manager.dart';
import 'package:stundenplan/theme.dart';

import 'integration.dart';

class SharedState {
  SharedPreferences preferences;

  Theme theme = darkTheme;
  int? height = Constants.defaultHeight;
  Content content;
  bool sendNotifications = true;
  ProfileManager profileManager = ProfileManager();
  List<int> holidayWeekdays = getHolidayWeekDays();
  CalendarData calendarData = CalendarData();

  SharedState(this.preferences, this.content);

  void saveState() {
    final saveFileData = <String, dynamic>{};

    // Theme
    final themeData = theme.getJsonData();
    saveFileData["theme"] = themeData;
    preferences.setString("theme", jsonEncode(themeData));

    // Profiles
    profileManager.renameAllProfiles();
    final jsonProfileManagerData = profileManager.getJsonData();
    saveFileData["jsonProfileManagerData"] = jsonProfileManagerData;
    preferences.setString("jsonProfileManagerData", jsonEncode(jsonProfileManagerData));

    // Notifications
    preferences.setBool("sendNotifications", sendNotifications);
    saveFileData["sendNotifications"] = true;

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

    sendNotifications = preferences.getBool("sendNotifications") ?? true;

    // Register integrations
    Integrations.instance.registerIntegration(IServUnitsSubstitutionIntegration(this));
    Integrations.instance.registerIntegration(SchulmangerIntegration(this));

    loadThemeProfileManagerAndSendNotificationsFromJson(jsonDecode(themeDataString), jsonDecode(preferences.getString("jsonProfileManagerData")!));
    return false;
  }

  void loadThemeProfileManagerAndSendNotificationsFromJson(dynamic themeData, dynamic jsonProfileManagerData) {
    theme = Theme.fromJsonData(themeData);
    profileManager = ProfileManager.fromJsonData(jsonProfileManagerData);
  }

  // Content

  void saveCache() {
    // Save calendar data
    preferences.setString("calendarData", jsonEncode(calendarData.toJson()));
    // Save integrations
    preferences.setString("integrationsValues", jsonEncode(Integrations.instance.saveIntegrationValuesToJson()));
    // Save content
    content.updateLastUpdated();
    log("[SAVED] lastUpdated: ${content.lastUpdated}", name: "cache");
    final encodedContent = jsonEncode(content.toJsonData());
    preferences.setString("cachedContent", encodedContent);
  }

  void loadCache() {
    // Load calendar data
    final String calendarDataJsonString = preferences.get("calendarData").toString();
    if (calendarDataJsonString != "") {
      calendarData = CalendarData.fromJson(jsonDecode(calendarDataJsonString) as List<dynamic>);
    }
    // Load integrations
    if (preferences.containsKey("integrationsValues")) {
      Integrations.instance.loadIntegrationValuesFromJson(jsonDecode(preferences.getString("integrationsValues")!) as Map<String, dynamic>);
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
