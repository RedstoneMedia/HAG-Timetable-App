import 'dart:convert';
import 'dart:math' as math;
import 'dart:developer';
import 'package:intl/intl.dart';
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
  bool sendNotifications = false;
  ProfileManager profileManager = ProfileManager();
  String? schulmanagerClassName;
  List<int> holidayWeekdays = getHolidayWeekDays();
  CalendarData calendarData = CalendarData();
  // Internal flags
  bool hasChangedCourses = true;
  bool processSpecialAGClass = true;
  bool processSpecialCourseClass = true;

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
    saveFileData["sendNotifications"] = sendNotifications;

    // Save theme and profiles to file
    saveToFile(jsonEncode(saveFileData), Constants.saveDataFileLocation);

    // Internal flags
    saveInternalFlags();

    preferences.setInt("height", height!);
  }

  Theme themeFromJsonData(dynamic jsonThemeData) {
    return Theme.fromJsonData(jsonThemeData);
  }

  bool loadStateAndCheckIfFirstTime({bool fromBackgroundTask = false}) {
    final String themeDataString = preferences.getString("theme") ?? "dark";
    height = preferences.getInt("height");

    // If first time using app
    if (height == null) {
      height = Constants.defaultHeight;
      return true;
    }
    // Load User flags
    sendNotifications = preferences.getBool("sendNotifications") ?? false;
    // Load Internal flags
    loadInternalFlags();
    // Register integrations
    Integrations.instance.registerIntegration(IServUnitsSubstitutionIntegration(this));
    Integrations.instance.registerIntegration(SchulmanagerIntegration.Schulmanager(this));

    loadSchulmangerClassName(fromBackgroundTask: fromBackgroundTask);
    loadThemeProfileManagerFromJson(jsonDecode(themeDataString), jsonDecode(preferences.getString("jsonProfileManagerData")!));
    return false;
  }

  void loadSchulmangerClassName({bool fromBackgroundTask = false}) {
    final now = DateTime.now();
    final lastOpened = DateTime.tryParse(preferences.getString("appLastOpened") ?? "");
    if (lastOpened != null && !fromBackgroundTask && now.difference(lastOpened) > Constants.refreshSchulmanagerClassNameDuration) {
      preferences.remove("schulmanagerClassName");
      schulmanagerClassName = null;
      preferences.setString("appLastOpened", now.toIso8601String());
      return;
    }
    if (!fromBackgroundTask) preferences.setString("appLastOpened", now.toIso8601String());
    schulmanagerClassName = preferences.getString("schulmanagerClassName");
  }

  void loadInternalFlags() {
    hasChangedCourses = preferences.getBool("hasChangedCourses") ?? true;
    processSpecialAGClass = preferences.getBool("processSpecialAGClass") ?? true;
    processSpecialCourseClass = preferences.getBool("processSpecialCourseClass") ?? true;
    // Randomly activate hasChangedCourses to force update the special classes.
    // This is important, since there is a very small probability that teachers accidentally remove courses or classes from the website, without the user actually chaining their courses
    if (math.Random().nextDouble() < Constants.randomUpdateSpecialClassesChance &&
        (!processSpecialAGClass || !processSpecialCourseClass)
    ) {
      hasChangedCourses = true;
    }
  }

  void loadThemeProfileManagerFromJson(dynamic themeData, dynamic jsonProfileManagerData) {
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
    // Save internal flags
    saveInternalFlags();
  }

  Future<void> saveSchulmanagerClassName() async {
    if (schulmanagerClassName != null) {
      await preferences.setString("schulmanagerClassName", schulmanagerClassName!);
    } else {
      await preferences.remove("schulmanagerClassName");
    }
  }

  void saveInternalFlags() {
    preferences.setBool("hasChangedCourses", hasChangedCourses);
    preferences.setBool("processSpecialAGClass", processSpecialAGClass);
    preferences.setBool("processSpecialCourseClass", processSpecialCourseClass);
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

  List<String> get allCurrentSubjects {
    final allSubjects = profileManager.subjects.toList();
    for (final defaultSubject in defaultSubjects) {
      allSubjects.add(defaultSubject);
    }
    return allSubjects;
  }

  // Snapshot
  Future<void> saveSnapshot() async {
    final snapshotData = <String, dynamic>{
      "integrations" : Integrations.instance.saveIntegrationValuesToJson(),
      "content" : content.toJsonData()
    };
    final now = DateTime.now();
    final timeStampString = DateFormat("dd_MM_yyy-HH_mm_ss").format(now);
    final saveFilePath = "${Constants.saveSnapshotFileLocation}/stundenplan_snapshot_$timeStampString.snapshot";
    await saveToFileArchived(jsonEncode(snapshotData), saveFilePath);
  }
}
