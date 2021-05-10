class Holiday {
  bool doesDependOnEaster = false;
  int? daysAfterEaster = 0;
  int? day = 0;
  int? month = 0;

  Holiday({int? month, int? day, int? daysAfterEaster}) {
    doesDependOnEaster = daysAfterEaster != null;
    this.month = month; // ignore: prefer_initializing_formals
    this.day = day; // ignore: prefer_initializing_formals
    this.daysAfterEaster = daysAfterEaster; // ignore: prefer_initializing_formals
  }

  bool isDate(DateTime date, DateTime easterDate) {
    if (!doesDependOnEaster) return day == date.day && month == date.month;
    final int daysAfterEaster = date.difference(easterDate).inDays;
    return daysAfterEaster == this.daysAfterEaster;
  }
}


DateTime getEasterDate(int year) {
  final double locationInMetonicCyle = year % 19;
  final double numberOfLeapYears = year % 4;
  final double nonLeapYear = year % 7;
  final int century = (year / 100).floor();
  final int magicNumber = ((13 + 8 * century) / 25).floor();
  final double centuryNumber = (15 - magicNumber + century - (century / 4)) % 30;
  final double diffLeapYearsJulianGergorian = (4 + century - (century / 4)) % 7;
  final double numberOfDaysToSpringStart = (19*locationInMetonicCyle + centuryNumber) % 30;
  final double numberOfDaysToNextSunday = (diffLeapYearsJulianGergorian + 2*numberOfLeapYears + 4*nonLeapYear + 6*numberOfDaysToSpringStart) % 7;

  if (numberOfDaysToSpringStart == 29 && numberOfDaysToNextSunday == 6) return DateTime(year, 04, 19);
  if (numberOfDaysToSpringStart == 28 && numberOfDaysToNextSunday == 6) return DateTime(year, 04, 18);
  final int days = (22 + numberOfDaysToSpringStart + numberOfDaysToNextSunday).floor();
  if (days > 31) return DateTime(year, 4, days - 31);
  return DateTime(year, 3, days);
}


List<int> getHolidayWeekDays() {
  final List<Holiday> holidays =
  [
    Holiday(day : 01, month: 01),
    Holiday(day : 01, month: 05),
    Holiday(day : 03, month: 10),
    Holiday(day : 31, month: 10),
    Holiday(day : 24, month: 12),
    Holiday(day : 25, month: 12),
    Holiday(day : 26, month: 12),
    Holiday(day : 31, month: 12),
    Holiday(daysAfterEaster : -2),
    Holiday(daysAfterEaster : 1),
    Holiday(daysAfterEaster : 39),
    Holiday(daysAfterEaster : 50),

  ]; // TODO : Put this list somewhere else

  final now = DateTime.now();
  final easterDate = getEasterDate(now.year);
  final weekStartDate = now.subtract(Duration(days: now.weekday-1));
  final List<int> holidayWeekDays = [];
  for (int i = 0; i < 5; i++) {
    final currentDate = weekStartDate.add(Duration(days: i));
    for (final holiday in holidays) {
      if (holiday.isDate(currentDate, easterDate)) {
        holidayWeekDays.add(i + 1);
        // Check if the holiday is on a Thursday -> Friday is a bridge day
        if(i == 3) holidayWeekDays.add(i + 2);
        // Check if the holiday is on a Tuesday -> Monday is a bridge day
        if(i == 1) holidayWeekDays.add(i);
      }
    }
  }
  return holidayWeekDays;
}