import 'dart:collection';

import 'package:stundenplan/profile.dart';


class ProfileManager {
  String currentProfileName = "11e";
  LinkedHashMap<String, Profile> profiles = {"11e" : Profile()} as LinkedHashMap<String, Profile>;

  Map<String, dynamic> getJsonData() {
    Map<String, dynamic> jsonProfileManagerData = new Map<String, dynamic>();
    Map<String, Map> jsonProfilesData = new Map<String, Map>();
    for (String profileName in profiles.keys) {
      Profile profile = profiles[profileName];
      jsonProfilesData[profileName] = profile.getJsonData();
    }
    jsonProfileManagerData["profiles"] = jsonProfilesData;
    jsonProfileManagerData["currentProfileName"] = currentProfileName;
    return jsonProfileManagerData;
  }

  static void fromJsonData(dynamic jsonProfileManagerData) {
    ProfileManager profileManager = new ProfileManager();
    profileManager.profiles = new LinkedHashMap<String, Profile>();
    profileManager.currentProfileName = jsonProfileManagerData["currentProfileName"];
    var jsonProfilesData = jsonProfileManagerData["profiles"];
    for (var profileName in jsonProfilesData.keys) {
      var jsonProfileData = jsonProfilesData[profileName];
      profileManager.profiles[profileName] = Profile.fromJsonData(jsonProfileData);
    }
  }

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


  // Current Profile attributes

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