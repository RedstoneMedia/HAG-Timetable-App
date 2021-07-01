import 'dart:developer';
import 'package:tuple/tuple.dart';

class WeekSubstitutions {
  Map<String, Tuple2<List<Map<String, dynamic>>, String>>? weekSubstitutions;

  WeekSubstitutions(dynamic savedSubstitutions) {
    // Remove old substitutions
    weekSubstitutions = <String, Tuple2<List<Map<String, dynamic>>, String>>{};
    final DateTime now = DateTime.now();
    int nowWeekDay = DateTime.now().weekday;
    if (nowWeekDay > 5) {
      nowWeekDay = 1;
    }
    for (final weekDayString in savedSubstitutions.keys) {
      final daySubstitution = savedSubstitutions[weekDayString];
      try {
        final substitutionDate =  DateTime.parse(daySubstitution[1]! as String);
        // Ignore if data is stale
        if (now.difference(substitutionDate).inDays >= 7) {
          continue;
        }
        final weekDay = int.parse(weekDayString as String);
        if (weekDay < nowWeekDay) {
          setDay(daySubstitution[0]! as List<dynamic>, substitutionDate);
        }
      } catch (e) {
        log("Using old week substitution format", name: "week substitutions");
        final weekDay = int.parse(weekDayString as String);
        if (weekDay < nowWeekDay) {
          setDay(daySubstitution! as List<dynamic>, now.subtract(Duration(days: nowWeekDay-weekDay)));
        }
      }
    }
  }

  void setDay(List<dynamic> daySubstitutions, DateTime substituteDate) {
    log(daySubstitutions.toString(), name : "s");
    final weekDay = substituteDate.weekday;
    if (!weekSubstitutions!.containsKey(weekDay.toString())) {
      weekSubstitutions![weekDay.toString()] = Tuple2([], substituteDate.toString());
    }
    for (final substitution in daySubstitutions) {
      weekSubstitutions![weekDay.toString()]!.item1.add(substitution as Map<String, dynamic>);
    }
  }

  Map<String, dynamic> toJson() {
    final outputJson = <String, dynamic>{};
    for (final weekDayString in weekSubstitutions!.keys) {
      final daySubstitution = weekSubstitutions![weekDayString]!;
      final daySubstitutionList = <dynamic>[];
      daySubstitutionList.add(daySubstitution.item1);
      daySubstitutionList.add(daySubstitution.item2);
      outputJson[weekDayString] = daySubstitutionList;
    }
    return outputJson;
  }

}