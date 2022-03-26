import 'dart:collection';
import 'package:stundenplan/profile.dart';

class ProfileManager {
  String currentProfileName = "11e";
  LinkedHashMap<String, Profile> profiles =
      {"11e": Profile()} as LinkedHashMap<String, Profile>;

  Map<String, dynamic> getJsonData() {
    final jsonProfileManagerData = <String, dynamic>{};
    final jsonProfilesData = <String, Map>{};
    for (final profileName in profiles.keys) {
      final profile = profiles[profileName]!;
      jsonProfilesData[profileName] = profile.getJsonData();
    }
    jsonProfileManagerData["profiles"] = jsonProfilesData;
    jsonProfileManagerData["currentProfileName"] = currentProfileName;
    return jsonProfileManagerData;
  }

  // ignore: prefer_constructors_over_static_methods
  static ProfileManager fromJsonData(dynamic jsonProfileManagerData) {
    final profileManager = ProfileManager();
    // ignore: prefer_collection_literals
    profileManager.profiles = LinkedHashMap<String, Profile>();
    profileManager.currentProfileName = jsonProfileManagerData["currentProfileName"].toString();
    final jsonProfilesData = jsonProfileManagerData["profiles"];
    for (final profileName in jsonProfilesData.keys) {
      final jsonProfileData = jsonProfilesData[profileName];
      profileManager.profiles[profileName.toString()] = Profile.fromJsonData(jsonProfileData);
    }
    return profileManager;
  }

  String findNewProfileName(String profileName) {
    var counter = 1;
    var currentProfileName = profileName;
    while (profiles.keys.contains(currentProfileName)) {
      currentProfileName = "$profileName-$counter";
      counter++;
    }
    return currentProfileName;
  }

  void addProfileWithName(String profileName) {
    profiles[profileName] = Profile();
  }

  void renameAllProfiles() {
    for (final profileName in List.from(profiles.keys)) {
      final profile = profiles[profileName]!;
      profiles.remove(profileName);
      final newProfileName = findNewProfileName(profile.schoolGrade == null ? profileName as String : profile.toString());
      if (profileName == currentProfileName) {
        currentProfileName = newProfileName;
      }
      profiles[newProfileName] = profile;
    }
  }

  Profile get currentProfile {
    return profiles[currentProfileName]!;
  }

  // Current Profile attributes

  String? get schoolGrade {
    return currentProfile.schoolGrade;
  }

  set schoolGrade(String? schoolGrade) {
    currentProfile.schoolGrade = schoolGrade!;
  }

  String get subSchoolClass {
    return currentProfile.subSchoolClass;
  }

  set subSchoolClass(String subSchoolClass) {
    currentProfile.subSchoolClass = subSchoolClass;
  }

  String get schoolClassFullName {
    return currentProfile.schoolGrade! + currentProfile.subSchoolClass;
  }

  List<String> get subjects {
    return currentProfile.subjects;
  }

  set subjects(List<String> subjects) {
    currentProfile.subjects = subjects;
  }

  Map<String, String> get calendarUrls {
    return currentProfile.calendarUrls;
  }
}
