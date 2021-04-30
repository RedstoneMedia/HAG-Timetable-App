
class WeekSubstitutions {
  // Type is Map<String, List<Map<String, dynamic>>>
  Map<String, List<Map<String, dynamic>>> weekSubstitutions;

  WeekSubstitutions(dynamic savedSubstitutions) {
    // Remove old substitutions
    weekSubstitutions = <String, List<Map<String, dynamic>>>{};
    int nowWeekDay = DateTime.now().weekday;
    if (nowWeekDay > 5) {
      nowWeekDay = 1;
    }
    for (final weekDayString in savedSubstitutions.keys) {
      final weekDay = int.parse(weekDayString as String);
      if (weekDay < nowWeekDay) {
        setDay(savedSubstitutions[weekDayString] as List<dynamic>, weekDay);
      }
    }
  }

  void setDay(List<dynamic> daySubstitutions, int weekDay) {
    if (!weekSubstitutions.containsKey(weekDay.toString())) {
      weekSubstitutions[weekDay.toString()] = [];
    }
    for (final substitution in daySubstitutions) {
      weekSubstitutions[weekDay.toString()].add(substitution as Map<String, dynamic>);
    }
  }
}