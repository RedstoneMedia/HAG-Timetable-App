import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:stundenplan/integration.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:tuple/tuple.dart';

class WeekSubstitutions extends IntegratedValue {
  Map<String, Tuple2<List<Tuple2<Map<String, dynamic>, String>>, String>>? weekSubstitutions;

  WeekSubstitutions(dynamic savedSubstitutions, String integrationName, {bool checkWeekDay = true, bool checkWeek = true}) : super(save: true) {
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
        if (now.difference(substitutionDate).inDays >= 7 && checkWeek) {
          continue;
        }
        final weekDay = int.parse(weekDayString as String);
        if (weekDay < nowWeekDay || !checkWeekDay) {
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

  /// Tries to find all substitutions that overlap with a given substitution
  Iterable<Tuple2<int, Tuple2<Map<String, dynamic>, String>>> findSubstitutionsInRangeOnDay(List<Tuple2<Map<String, dynamic>, String>> daySubstitutions, Tuple2<Map<String, dynamic>, String> checkSubstitution) {
    final checkClassHours = (checkSubstitution.item1["Stunde"]! as String).split("-");
    return daySubstitutions.mapIndexed((index, element) => Tuple2(index, element)).where((element) {
      final substitution = element.item2;
      final oldSplitClassHour = (substitution.item1["Stunde"]! as String).split("-");
      if (oldSplitClassHour.any((classHour) => checkClassHours.any((newClassHour) => newClassHour == classHour))) return true; // If any numbers directly match there is an overlap
      // Check in class hour ranges if both substitutions have ranges
      if (oldSplitClassHour.length > 1 && checkClassHours.length > 1) {
        final newClassHourStart = int.parse(checkClassHours[0]);
        final newClassHourEnd = int.parse(checkClassHours[1]);
        final oldClassHourStart = int.parse(oldSplitClassHour[0]);
        final oldClassHourEnd = int.parse(oldSplitClassHour[1]);
        if (newClassHourStart > oldClassHourStart && newClassHourEnd < oldClassHourEnd || oldClassHourStart > newClassHourStart && oldClassHourStart < newClassHourEnd) return true;
      }
      // Check in class hour ranges if only one substitution has ranges
      else if (oldSplitClassHour.length > 1 || checkClassHours.length > 1) {
        final List<String>? classHourRange;
        final int? classHour;
        if (oldSplitClassHour.length > 1) {classHourRange = oldSplitClassHour; classHour = int.parse(checkClassHours.first);}
        else {classHourRange = checkClassHours; classHour = int.parse(oldSplitClassHour.first);}
        final classHourStart = int.parse(classHourRange[0]);
        final classHourEnd = int.parse(classHourRange[1]);
        if (classHour > classHourStart && classHour < classHourEnd) return true;
      }
      return false;
    });
  }

  /// Removes substitutions, so that only one substitution can occupied a given class hour
  /// Does not preserve partially overlaying substitutions
  /// Preserves substitution order
  bool removeOverlaying() {
    var didRemoveOne = false;
    for (final daySubstitutions in weekSubstitutions!.values) {
      final Set<int> markedSubstitutionsIndices = {};
      // Find the overlaying substations of that day
      for (int i = 0; i < daySubstitutions.item1.length; i++) {
        if (markedSubstitutionsIndices.contains(i)) continue;
        final checkSubstitution = daySubstitutions.item1[i];
        // Get the overlaying substitution indices excluding the current one (since a substitution always overlaps with itself)
        final overlayingSubstitutionsIndices = findSubstitutionsInRangeOnDay(daySubstitutions.item1, checkSubstitution)
          .map((e) => e.item1)
          .toList()
          ..removeWhere((j) => j == i);
        markedSubstitutionsIndices.addAll(overlayingSubstitutionsIndices);
      }
      // Remove the overlaying substitutions
      final markedSubstitutionsIndicesList = markedSubstitutionsIndices.toList(growable: false);
      for (int i = 0; i < markedSubstitutionsIndicesList.length; i++) {
        final markedSubstitutionIndex = markedSubstitutionsIndicesList[i];
        daySubstitutions.item1.removeAt(markedSubstitutionIndex-i);
      }
      didRemoveOne = markedSubstitutionsIndicesList.isNotEmpty;
    }
    return didRemoveOne;
  }

  @override
  void merge(IntegratedValue integratedValue, String integrationName, {bool overwriteEqual = false}) {
    final otherWeekSubstitutions = integratedValue as WeekSubstitutions;
    for (final entry in otherWeekSubstitutions.weekSubstitutions!.entries) {
      final weekDay = entry.key;
      if (!weekSubstitutions!.containsKey(weekDay)) {
        weekSubstitutions![weekDay] = entry.value;
      } else {
        final newDaySubstitutions = [];
        var currentDaySubstitutions = weekSubstitutions![weekDay]!;
        for (final newSubstitution in entry.value.item1) {
          final newClassHours = (newSubstitution.item1["Stunde"]! as String).split("-");
          // Find the old substitution
          final oldSubstitutions = findSubstitutionsInRangeOnDay(currentDaySubstitutions.item1, newSubstitution).toList(growable: false);
          if (oldSubstitutions.isEmpty) {
            weekSubstitutions![weekDay]!.item1.add(newSubstitution);
            continue;
          }
          var daySubstitutionsList = currentDaySubstitutions.item1;
          final oldSubstitution = oldSubstitutions.first.item2.item1;
          if (areSubstitutionsEqual(newSubstitution.item1, oldSubstitution) && !overwriteEqual) {continue;} // If nothing changed, just keep the old substitution
          if (newSubstitution.item1["Stunde"] as String != oldSubstitution["Stunde"]! as String) {
            final newClassHourStart = int.parse(newClassHours[0]);
            final newClassHourEnd = newClassHours.length > 1 ? int.parse(newClassHours[1]) : newClassHourStart;
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
                final modifiedSubstitution = Map<String, dynamic>.from(substitution.item1);
                modifiedSubstitution["Stunde"] = i.toString();
                newDaySubstitutionsList.add(Tuple2(modifiedSubstitution, substitution.item2));
              }
            }
            newDaySubstitutionsList.sort((a, b) => (int.parse(a.item1["Stunde"]! as String)).compareTo(int.parse(b.item1["Stunde"]! as String)));
            // Add missing class hours as placeholders to make index 0 actually be class Hour 1 and replace substitutions new in the new substitution in range
            for (var i = 1; i < newClassHourEnd + 1; i++) {
              // Add placeholder at index if index is not present
              if (!newDaySubstitutionsList.any((substitution) => substitution.item1["Stunde"]! as String == i.toString())) {
                newDaySubstitutionsList.insert(i-1, const Tuple2({"Stunde" : "0"}, "Placeholder"));
              }
              // Overwrite if in range
              if (i >= newClassHourStart) {
                final modifiedSubstitution = Map<String, dynamic>.from(newSubstitution.item1);
                modifiedSubstitution["Stunde"] = i.toString();
                if (areSubstitutionsEqual(modifiedSubstitution, newDaySubstitutionsList[i-1].item1) && !overwriteEqual) {continue;} // If nothing changed, just keep the old substitution
                newDaySubstitutionsList[i-1] = Tuple2(modifiedSubstitution, newSubstitution.item2);
              }
            }
            newDaySubstitutionsList.removeWhere((substitution) => substitution.item2 == "Placeholder");
            daySubstitutionsList = newDaySubstitutionsList;
          } else {
            final oldSubstitutionIndex = oldSubstitutions.first.item1;
            daySubstitutionsList[oldSubstitutionIndex] = newSubstitution;
          }
          // Make sure to update current day substitution, for next iteration or end
          weekSubstitutions![weekDay] = Tuple2(daySubstitutionsList, currentDaySubstitutions.item2);
          currentDaySubstitutions = weekSubstitutions![weekDay]!;
        }
        setDay(newDaySubstitutions, DateTime.parse(entry.value.item2), integrationName);
      }
    }
  }

}

/// Determine if two substitutions are equal
bool areSubstitutionsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
  return const DeepCollectionEquality().equals(equalityProperties(a), equalityProperties(b));
}


/// Returns a substitution with only the properties, that are relevant for determining, if to substitutions are equal
Map<String, dynamic> equalityProperties(Map<String, dynamic> substitution) {
  final shallowSubstitutionCopy = Map<String, dynamic>.from(substitution);
  const irrelevantKeys = IServUnitsSubstitutionIntegration.customSubstitutionProperties;
  shallowSubstitutionCopy.removeWhere((key, _) => irrelevantKeys.contains(key));
  return shallowSubstitutionCopy;
}