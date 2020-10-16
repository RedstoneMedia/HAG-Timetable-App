import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/profile_manager.dart';
import 'package:stundenplan/theme.dart';

class SharedState {
  SharedPreferences preferences;

  Theme theme = darkTheme;
  int height = Constants.defaultHeight;
  Content content;
  ProfileManager profileManager = ProfileManager();

  SharedState(this.preferences);

  void saveState() {
    preferences.setString("theme", theme.themeName);

    // Profiles
    profileManager.renameAllProfiles();
    preferences.setString(
        "jsonProfileManagerData", jsonEncode(profileManager.getJsonData()));

    preferences.setInt("height", height);
  }

  bool loadStateAndCheckIfFirstTime() {
    setThemeFromThemeName(preferences.getString("theme") ?? "dark");
    height = preferences.getInt("height");

    // If first time using app
    if (height == null) {
      height = Constants.defaultHeight;
      return true;
    }

    profileManager = ProfileManager.fromJsonData(
        jsonDecode(preferences.getString("jsonProfileManagerData")));
    return false;
  }

  // Content

  void saveContent() {
    content.updateLastUpdated();
    // ignore: avoid_print
    print("[SAVED] lastUpdated: ${content.lastUpdated}");
    final encodedContent = jsonEncode(content.toJsonData());
    preferences.setString("cachedContent", encodedContent);
  }

  void loadContent() {
    final contentJsonString = preferences.get("cachedContent").toString();
    if (contentJsonString == null) return;
    final decodedJson = jsonDecode(contentJsonString) as List<dynamic>;
    content = Content.fromJsonData(decodedJson);
    // ignore: avoid_print
    print("[LOADED] lastUpdated: ${content.lastUpdated}");
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
