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
      weekStartDate = weekStartDate.add(const Duration(days: 7));
    }

    // TODO: Only remove data points with the same name up to a day where they arent continues anymore. Example : P = Point E = Empty "PPEPPP" should turn into "EPEEEP"
    for (final day in days) {
      day.removeWhere((element) => element.name == dataPoint.name);
    }

    // TODO: Handle other date representations, where the startDate is not equal to the endDate

    final weekDay = dataPoint.startDate.weekday-1;
    if (weekDay > 4) return;
    if (dataPoint.startDate.isBefore(weekStartDate)) return;
    if (dataPoint.endDate.isAfter(weekStartDate.add(const Duration(days: 6)))) return;
    days[weekDay].add(dataPoint);
  }

  @override
  String toString() {
    return days.toString();
  }
}