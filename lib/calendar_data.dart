enum CalendarType {
  exercise,
  holiday,
  exam,
  public,
  schoolClass,
  students,
  personal
}

const pluginCalendarTypes = [CalendarType.exam, CalendarType.exercise, CalendarType.holiday];

extension CalendarTypeExtension on CalendarType {

  String name() {
    switch (this) {
      case CalendarType.exam:
        return "Klausur";
      case CalendarType.exercise:
        return "Aufgabe";
      case CalendarType.holiday:
        return "Feiertag";
      case CalendarType.public:
        return "Öffentlich";
      case CalendarType.schoolClass:
        return "Klasse";
      case CalendarType.students:
        return "Schüler";
      case CalendarType.personal:
        return "Persönlich";
    }
  }

  static CalendarType? fromString(String string) {
    switch (string) {
      case "Klausur":
        return CalendarType.exam;
      case "Aufgabe":
        return CalendarType.exercise;
      case "Feiertag":
        return CalendarType.holiday;
      case "Öffentlich":
        return CalendarType.public;
      case "Klasse":
        return CalendarType.schoolClass;
      case "Schüler":
        return CalendarType.students;
      case "Persönlich":
        return CalendarType.personal;
      default:
        return null;
    }
  }
}

class CalendarDataPoint {
  CalendarType calendarType;
  String name;
  DateTime startDate;
  DateTime endDate;

  CalendarDataPoint(this.calendarType, this.name, this.startDate, this.endDate);

  // ignore: prefer_constructors_over_static_methods
  static CalendarDataPoint fromJson(Map<String, dynamic> jsonData) {
    final calendarType = CalendarTypeExtension.fromString(jsonData["calendarType"] as String);
    final name = jsonData["name"] as String;
    final startDate = DateTime.parse(jsonData["startDate"] as String);
    final endDate = DateTime.parse(jsonData["endDate"] as String);
    return CalendarDataPoint(calendarType!, name, startDate, endDate);
  }

  Map<String, dynamic> toJson() {
    final outputJson = <String, dynamic>{};
    outputJson["calendarType"] = calendarType.name();
    outputJson["name"] = name;
    outputJson["startDate"] = startDate.toIso8601String();
    outputJson["endDate"] = startDate.toIso8601String();
    return outputJson;
  }

  @override
  String toString() {
    return '<"$name" ${startDate.month}.${startDate.day}>';
  }
}

class CalendarData {
  List<List<CalendarDataPoint>> days = List.generate(5, (index) => []);

  void addCalendarDataPoint(CalendarDataPoint dataPoint) {
    final now = DateTime.now();
    var weekStartDate = now.subtract(Duration(days: now.weekday-1));
    if (now.weekday > 5) {
      weekStartDate = weekStartDate.add(const Duration(days: 6));
    }
    // Strip time out of the date so that the current time does not influence the isBefore and isAfter functions
    weekStartDate = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day);
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    // If the data point is not in the current week skip it
    if (dataPoint.startDate.isAfter(weekEndDate)) return;
    if (dataPoint.endDate.isBefore(weekStartDate)) return;
    // Calculate days between start and end date
    final daysBetween = (dataPoint.endDate.difference(dataPoint.startDate).inHours / 24).ceil();
    var daysToAdd = daysBetween;
    if (daysBetween == 0) {
      daysToAdd += 1;
    }

    // Add days between start and end date
    for (var i = 0; i < daysToAdd; i++) {
      final newDate = dataPoint.startDate.add(Duration(days: i));
      final weekDay = newDate.weekday-1;
      if (weekDay > 4) continue;
      if (newDate.isBefore(weekStartDate)) continue;
      if (newDate.isAfter(weekEndDate)) break;
      days[weekDay].add(dataPoint);
    }
  }

  // ignore: prefer_constructors_over_static_methods
  static CalendarData fromJson(List<dynamic> jsonData) {
    final calendarData = CalendarData();
    for (final day in jsonData) {
      for (final dataPointJson in day as List<dynamic>) {
        final dataPoint = CalendarDataPoint.fromJson(dataPointJson as Map<String, dynamic>);
        calendarData.addCalendarDataPoint(dataPoint);
      }
    }
    return calendarData;
  }

  List<dynamic> toJson() {
    final outputJson = <List<dynamic>>[];
    for (final day in days) {
      final dayDataPointsJson =<Map<String, dynamic>>[];
      for (final dataPoint in day) {
        dayDataPointsJson.add(dataPoint.toJson());
      }
      outputJson.add(dayDataPointsJson);
    }
    return outputJson;
  }

  @override
  String toString() {
    return days.toString();
  }
}