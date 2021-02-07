import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/profile_manager.dart';
import 'package:stundenplan/theme.dart';
import 'package:stundenplan/week_subsitutions.dart';

class SharedState {
  SharedPreferences preferences;

  Theme theme = darkTheme;
  int height = Constants.defaultHeight;
  Content content;
  WeekSubstitutions weekSubstitutions = WeekSubstitutions({});
  ProfileManager profileManager = ProfileManager();

  SharedState(this.preferences);

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

    // Week substitutions
    preferences.setString("weekSubstitutions", jsonEncode(weekSubstitutions.weekSubstitutions));

    // Save theme and profiles to file
    saveToFile(jsonEncode(saveFileData), Constants.saveDataFileLocation);

    preferences.setInt("height", height);
  }

  Theme themeFromJsonData(dynamic jsonThemeData) {
    return Theme.fromJsonData(jsonThemeData);
  }

  bool loadStateAndCheckIfFirstTime() {
    final String themeDataString = preferences.getString("theme");
    if (themeDataString == null) {
      theme = darkTheme;
    }
    height = preferences.getInt("height");

    // If first time using app
    if (height == null) {
      height = Constants.defaultHeight;
      return true;
    }

    // Load week substitutions
    final weekSubstitutionsJsonString = preferences.get("weekSubstitutions").toString();
    if (weekSubstitutionsJsonString != null) {
      weekSubstitutions = WeekSubstitutions(jsonDecode(weekSubstitutionsJsonString));
    }

    loadThemeAndProfileManagerFromJson(jsonDecode(themeDataString), jsonDecode(preferences.getString("jsonProfileManagerData")));
    return false;
  }

  void loadThemeAndProfileManagerFromJson(dynamic themeData, dynamic jsonProfileManagerData) {
    theme = Theme.fromJsonData(themeData);
    profileManager = ProfileManager.fromJsonData(jsonProfileManagerData);
  }

  // Content

  void saveContent() {
    content.updateLastUpdated();
    log("[SAVED] lastUpdated: ${content.lastUpdated}", name: "cache");
    final encodedContent = jsonEncode(content.toJsonData());
    preferences.setString("cachedContent", encodedContent);
  }

  void loadContent() {
    final contentJsonString = preferences.get("cachedContent").toString();
    if (contentJsonString == null) return;
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
            List<String>.from(Constants.defaultSubjectsMap[schoolGradeList]);
        defaultSubjects.addAll(Constants.alwaysDefaultSubjects);
        return defaultSubjects;
      }
    }
    return Constants.alwaysDefaultSubjects;
  }
}
