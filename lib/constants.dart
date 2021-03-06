class Constants {
  // Grid Properties
  static const int width = 6;
  static const int defaultHeight = 10;
  static const int fullHeight = 12;

  static const Duration clientTimeout = Duration(seconds: 15);
  static const List<String> weekDays = ["", "Mo", "Di", "Mi", "Do", "Fr"];
  static const String newestReleaseUrlPart =
      "https://github.com/RedstoneMedia/HAG-Timetable-App/releases/tag/";
  static const String substitutionLinkBase =
      "https://hag-iserv.de/iserv/public/plan/show/Schüler-Stundenpläne/b006cb5cf72cba5c/svertretung/svertretungen";
  static const String timeTableLinkBase =
      "https://hag-iserv.de/iserv/public/plan/show/Schüler-Stundenpläne/b006cb5cf72cba5c/splan/Kla1A";
  static const String calDavBaseUrl = "https://hag-iserv.de/caldav";
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
  static const String saveDataFileLocation = "/storage/emulated/0/Android/data/stundenplan-data.save";
}
