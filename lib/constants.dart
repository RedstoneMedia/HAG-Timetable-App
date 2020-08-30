
class Constants {
  //Grid Properties
  static const int width = 6;
  static const int height = 10;
  static const List<String> weekDays = ["", "Mo", "Di", "Mi", "Do", "Fr"];
  static const String substitutionLinkBase = "https://hag-iserv.de/iserv/public/plan/show/Sch%C3%BCler-Stundenpl%C3%A4ne/b006cb5cf72cba5c/svertretung/svertretungen";
  static const String timeTableLinkBase = "https://hag-iserv.de/iserv/public/plan/show/Schüler-Stundenpläne/b006cb5cf72cba5c/splan/Kla1A";
  static const List<String> defaultSubjects = [
    "De",
    "Ma",
    "Sp",
    "Ge",
    "Ek",
    "Po",
    "En",
  ];
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
}
