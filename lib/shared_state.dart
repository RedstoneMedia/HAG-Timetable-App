import 'dart:collection';

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
  String currentProfileName = "11e";
  Content content;
  LinkedHashMap<String, Profile> profiles = {"11e" : Profile()} as LinkedHashMap<String, Profile>;

  SharedState(this.preferences);

  void saveState() {
    preferences.setString("theme", theme.themeName);

    // Profiles
    renameAllProfiles();
    Map<String, Map> jsonProfileData = new Map<String, Map>();
    for (String profileName in profiles.keys) {
      Profile profile = profiles[profileName];
      jsonProfileData[profileName] = profile.getJsonData();
    }
    preferences.setString("jsonProfileData", jsonEncode(jsonProfileData));
    preferences.setString("currentProfileName", currentProfileName);

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

    currentProfileName = preferences.getString("currentProfileName");
    profiles = new LinkedHashMap<String, Profile>();
    var jsonProfilesData = jsonDecode(preferences.getString("jsonProfileData"));
    for (var profileName in jsonProfilesData.keys) {
      var jsonProfileData = jsonProfilesData[profileName];
      profiles[profileName] = Profile.fromJsonData(jsonProfileData);
    }
    return false;
  }

  // Content

  void saveContent() {
    var encoded = jsonEncode(content.toJsonData());
    preferences.setString("cachedContent", encoded);
  }

  void loadContent() {
    String contentJsonString = preferences.get("cachedContent");
    if (contentJsonString == null) return;
    content = Content.fromJsonData(jsonDecode(contentJsonString));
  }

  // Profiles

  String findProfileName(String profileName) {
    int counter = 1;
    String currentProfileName = profileName;
    while (profiles.containsKey(currentProfileName)) {
      currentProfileName = "$profileName-$counter";
      counter++;
    }
    return currentProfileName;
  }

  void addAndSwitchToProfileWithName(String profileName) {
    profiles[profileName] = new Profile();
    currentProfileName = profileName;
  }

  void renameAllProfiles() {
    for (String profileName in List.from(profiles.keys)) {
      Profile profile = profiles[profileName];
      String newProfileName = findProfileName(profile.toString());
      if (profileName == currentProfileName) {
        currentProfileName = newProfileName;
      }
      profiles[newProfileName] = profile;
      profiles.remove(profileName);
    }
  }

  Profile get currentProfile {
    return profiles[currentProfileName];
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

  // Theme

  void setThemeFromThemeName(String themeName) {
    this.theme = Theme.getThemeFromThemeName(themeName);
  }

  // Default subjects

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
}

