import 'dart:developer';
import 'package:stundenplan/integration.dart';
import 'package:tuple/tuple.dart';

class WeekSubstitutions extends IntegratedValue {
  Map<String, Tuple2<List<Tuple2<Map<String, dynamic>, String>>, String>>? weekSubstitutions;

  WeekSubstitutions(dynamic savedSubstitutions, String integrationName) : super(save: true) {
    // Remove old substitutions
    weekSubstitutions = <String, Tuple2<List<Tuple2<Map<String, dynamic>, String>>, String>>{};
    if (savedSubstitutions == null) {return;}
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
          setDay(daySubstitution[0]! as List<dynamic>, substitutionDate, integrationName);
        }
      } catch (e) {
        log("Using old week substitution format", name: "week substitutions");
        final weekDay = int.parse(weekDayString as String);
        if (weekDay < nowWeekDay) {
          setDay(daySubstitution! as List<dynamic>, now.subtract(Duration(days: nowWeekDay-weekDay)), integrationName);
        }
      }
    }
  }

  void setDay(List<dynamic> daySubstitutions, DateTime substituteDate, String integrationName) {
    log(daySubstitutions.toString(), name : "s");
    final weekDay = substituteDate.weekday;
    if (!weekSubstitutions!.containsKey(weekDay.toString())) {
      weekSubstitutions![weekDay.toString()] = Tuple2([], substituteDate.toString());
    }
    for (final substitution in daySubstitutions) {
      weekSubstitutions![weekDay.toString()]!.item1.add(Tuple2(substitution as Map<String, dynamic>, integrationName));
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final outputJson = <String, dynamic>{};
    for (final weekDayString in weekSubstitutions!.keys) {
      final daySubstitution = weekSubstitutions![weekDayString]!;
      final daySubstitutionList = <dynamic>[];
      daySubstitutionList.add(daySubstitution.item1.map((e) => e.item1).toList());
      daySubstitutionList.add(daySubstitution.item2);
      outputJson[weekDayString] = daySubstitutionList;
    }
    return outputJson;
  }

  @override
  void merge(IntegratedValue integratedValue, String integrationName) {
    // TODO: implement merge
  }

}