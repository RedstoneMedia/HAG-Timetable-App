import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/theme.dart';
import 'dart:convert';

import 'profile.dart';

class SharedState {
  SharedPreferences preferences;

  Theme theme = darkTheme;
  int height = Constants.defaultHeight;
  int currentProfileIndex = 0;
  Content content;
  List<Profile> profiles = [Profile()];

  SharedState(this.preferences);

  void saveState() {
    preferences.setString("theme", theme.themeName);
    preferences.setInt("currentProfileIndex", currentProfileIndex);
    List<Map> jsonProfileData = new List<Map>();
    for (Profile profile in profiles) {
      jsonProfileData.add(profile.getJsonData());
    }
    preferences.setString("jsonProfileData", jsonEncode(jsonProfileData));
    preferences.setInt("height", height);
  }

  void saveContent() {
    var encoded = jsonEncode(content.toJsonData());
    preferences.setString("cachedContent", encoded);
  }

  void loadContent() {
    String contentJsonString = preferences.get("cachedContent");
    if (contentJsonString == null) return;
    content = Content.fromJsonData(jsonDecode(contentJsonString));
  }

  bool loadStateAndCheckIfFirstTime() {
    setThemeFromThemeName(preferences.getString("theme") ?? "dark");
    height = preferences.getInt("height");

    // If first time using app
    if (height == null) {
      height = Constants.defaultHeight;
      return true;
    }

    profiles = [];
    var jsonProfilesData = jsonDecode(preferences.getString("jsonProfileData"));
    for (var jsonProfileData in jsonProfilesData) {
      profiles.add(Profile.fromJsonData(jsonProfileData));
    }
    loadContent();
    return false;
  }


  void setThemeFromThemeName(String themeName) {
    this.theme = Theme.getThemeFromThemeName(themeName);
  }

  List<String> get defaultSubjects {
    for (var schoolGradeList in Constants.defaultSubjectsMap.keys) {
      if (schoolGradeList.contains(schoolGrade)) {
        var defaultSubjects = new List<String>.from(Constants.defaultSubjectsMap[schoolGradeList]);
        defaultSubjects.addAll(Constants.alwaysDefaultSubjects);
        return defaultSubjects;
      }
    }
    return Constants.alwaysDefaultSubjects;
  }

  Profile get currentProfile {
    return profiles[currentProfileIndex];
  }

  String get schoolGrade {
    return currentProfile.schoolGrade;
  }

  set schoolGrade(String schoolGrade) {
    currentProfile.schoolGrade = schoolGrade;
  }

  String get subSchoolClass {
    return currentProfile.subSchoolClass;
  }

  set subSchoolClass(String subSchoolClass) {
    currentProfile.subSchoolClass = subSchoolClass;
  }

  List<String> get subjects {
    return currentProfile.subjects;
  }

  set subjects(List<String> subjects) {
    currentProfile.subjects = subjects;
  }
}

