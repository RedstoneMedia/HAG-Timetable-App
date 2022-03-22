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
    // TODO: write unit tests for this (im unsure if this works)
    final otherWeekSubstitutions = integratedValue as WeekSubstitutions;
    for (final entry in otherWeekSubstitutions.weekSubstitutions!.entries) {
      final weekDay = entry.key;
      if (!weekSubstitutions!.containsKey(weekDay)) {
        weekSubstitutions![weekDay] = entry.value;
      } else {
        final newDaySubstitutions = [];
        final currentDaySubstitutions = weekSubstitutions![weekDay]!;
        for (final newSubstitution in entry.value.item1) {
          final newClassHours = (newSubstitution.item1["Stunde"]! as String).split("-");
          final oldSubstitutionIndex = currentDaySubstitutions.item1.indexWhere((substitution) {
            final oldSplitClassHour = (substitution.item1["Stunde"]! as String).split("-");
            return oldSplitClassHour.any((classHour) => newClassHours.any((newClassHour) => newClassHour == classHour));
          });
          if (oldSubstitutionIndex == -1) {
            weekSubstitutions![weekDay]!.item1.add(newSubstitution);
            continue;
          }
          var daySubstitutionsList = currentDaySubstitutions.item1;
          final oldSubstitution = daySubstitutionsList[oldSubstitutionIndex].item1;
          final oldClassHours = (oldSubstitution["Stunde"]! as String).split("-");
          if (oldClassHours != newClassHours) {
            final newClassHourStart = int.parse(newClassHours[0]);
            final newClassHourEnd = int.parse(newClassHours[1]);
            // Split hour ranges in current substitution (5-6, 8-9, etc.) into smaller substitution (5-6 -> 5,6; 8-9 -> 8,9). This is done, so that the index in the day substitution list matches the classHour offset by 1 and can then easily be replaced by the new substitution
            final List<Tuple2<Map<String, dynamic>, String>> newDaySubstitutionsList = [];
            for (final substitution in daySubstitutionsList) {
              final classHourSplit = (substitution.item1["Stunde"]! as String).split("-");
              if (classHourSplit.length == 1) {
                newDaySubstitutionsList.add(substitution);
                continue;
              }
              final hourStart = int.parse(classHourSplit[0]);
              final hourEnd = int.parse(classHourSplit[1]);
              for (var i = hourStart; i < hourEnd + 1; i++) {
                final modifiedSubstitution = substitution.item1;
                modifiedSubstitution["Stunde"] = i.toString();
                newDaySubstitutionsList.add(Tuple2(modifiedSubstitution, substitution.item2));
              }
            }
            daySubstitutionsList.sort((a, b) => (int.parse(a.item1["Stunde"]! as String)).compareTo(int.parse(b.item1["Stunde"]! as String)));
            for (var i = newClassHourStart; i < newClassHourEnd + 1; i++) {
              final modifiedSubstitution = newSubstitution.item1;
              modifiedSubstitution["Stunde"] = i.toString();
              daySubstitutionsList[i-1] = Tuple2(modifiedSubstitution, newSubstitution.item2);
            }
            daySubstitutionsList = newDaySubstitutionsList;
          } else {
            daySubstitutionsList[oldSubstitutionIndex] = newSubstitution;
            weekSubstitutions![weekDay] = Tuple2(daySubstitutionsList, currentDaySubstitutions.item2);
          }
        }
        setDay(newDaySubstitutions, DateTime.parse(entry.value.item2), integrationName);
      }
    }
  }

}