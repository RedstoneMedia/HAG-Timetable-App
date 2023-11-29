import 'package:flutter/foundation.dart';

class Constants {
  // The current features of the installation
  static const bool defineHasTesterFeature = bool.fromEnvironment("DEFINE_HAS_TESTER_FEATURE") || !kReleaseMode;
  static const bool defineHasSmallFeature = bool.fromEnvironment("DEFINE_HAS_SMALL_FEATURE");

  // Grid Properties
  static const int width = 6;
  static const int defaultHeight = 10;
  static const int fullHeight = 12;

  static const Duration clientTimeout = Duration(seconds: 15);
  static const List<String> weekDays = ["", "Mo", "Di", "Mi", "Do", "Fr"];
  static const String newestReleaseUrlPart =
      "https://github.com/RedstoneMedia/HAG-Timetable-App/releases/tag/";
  static const String newestReleaseDownloadUrlPart =
      "https://github.com/RedstoneMedia/HAG-Timetable-App/releases/download/";
  static const String iServHost = "https://hag-iserv.de";
  static const String substitutionLinkBase =
      "$iServHost/iserv/public/plan/show/Schüler-Stundenpläne/b006cb5cf72cba5c/svertretung/Druck_Kla";
  static const String timeTableLinkBase =
      "$iServHost/iserv/public/plan/show/Schüler-Stundenpläne/b006cb5cf72cba5c/splan/Kla1A";
  static const String calDavBaseUrl = "$iServHost/caldav";
  static const String calendarIServBaseUrl = "$iServHost/iserv/calendar";
  static const String loginUrlIServ = "$iServHost/iserv/login";
  static const Duration credentialExpireDuration = Duration(days: 178);
  static const Duration loginSessionExpireDuration = Duration(hours: 2);
  static const Duration refreshSchulmanagerClassNameDuration = Duration(days: 14);
  // This url is used instead of loginUrlIServ, because it requires less redirects to know, if the credentials were correct.
  // It however needs additional redirects to get the actual IServ session cookies, that's why this url is only used for credential checks.
  static const String credentialCheckUrlIServ = "$iServHost/iserv/auth/login";

  static const Duration notifyUpdateFrequency = Duration(minutes: 20);
  static const int notifyUpdateDaySleepStartHour = 22;
  static const int notifyUpdateDaySleepEndHour = 4;
  static const bool notifyDebugLogToFile = defineHasTesterFeature;

  static const String publicIServUrl = "$iServHost/iserv/public";
  static const String newestVersionPubspecUrl =
      "https://raw.githubusercontent.com/RedstoneMedia/HAG-Timetable-App/master/pubspec.yaml";

  static const List<String> alwaysDefaultSubjects = [
    "De",
    "Ma",
    "Sp",
    "Ge",
    "Ek",
    "Po"
  ];
  static const Map<List<String>, List<String>> defaultSubjectsMap = {
    ["5", "6", "7", "8", "9", "10"]: ["Bi", "Ch", "Ph", "Ku", "En", "Mu"],
    ["11", "Q1", "Q2"]: []
  };

  static const List<String> startTimes = [
    "7:55",
    "8:45",
    "9:50",
    "10:35",
    "11:40",
    "12:25",
    "13:10",
    "13:50",
    "14:35",
    "15:30",
    "16:15"
  ];
  static const List<String> endTimes = [
    "8:40",
    "9:30",
    "10:35",
    "11:20",
    "12:25",
    "13:10",
    "13:45",
    "14:35",
    "15:20",
    "16:15",
    "17:00"
  ];
  static const List<String> schoolGrades = [
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "11",
    "Q1",
    "Q2"
  ];
  static const List<String> displayFullHeightSchoolGrades = ["Q1", "Q2"];
  static const bool useAGs = true;
  static const String specialClassNameAG = "AG";
  static const double randomUpdateSpecialClassesChance = 0.01; // 1%
  static const String saveDataFileLocation = "/storage/emulated/0/Documents/stundenplan-data.save";
  static const String saveDataFileLocationOld = "/storage/emulated/0/Android/data/stundenplan-data.save";

  static const String saveSnapshotFileLocation = "/storage/emulated/0/Android/data/com.example.stundenplan/files";

  static const String schulmanagerBaseUrl = "https://login.schulmanager-online.de";
  static const String schulmanagerOicdBaseUrl = "https://login.schulmanager-online.de/oidc";
  static const String schulmanagerApiBaseUrl = "https://login.schulmanager-online.de/api";
  static const int schulmanagerSchoolId = 776;

  static const String wikiBaseUrl = "https://github.com/RedstoneMedia/HAG-Timetable-App/wiki";
}
