import 'package:stundenplan/week_subsitutions.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

void compareWeekSubstitutions(WeekSubstitutions actual, WeekSubstitutions target) {
  expect(actual.weekSubstitutions!.length, target.weekSubstitutions!.length, reason: "Week substitutions have different lengths");
  for (final daySubstitutionsEntry in target.weekSubstitutions!.entries) {
    expect(actual.weekSubstitutions!.containsKey(daySubstitutionsEntry.key), true, reason: "Key ${daySubstitutionsEntry.key} was expected, but is not present");
    final actualDaySubstitutions = actual.weekSubstitutions![daySubstitutionsEntry.key]!;
    expect(actualDaySubstitutions.item2, daySubstitutionsEntry.value.item2, reason: "Dates do not match (wtf ?)");
    for (var i = 0; i < daySubstitutionsEntry.value.item1.length; i++) {
      final targetSubstitution = daySubstitutionsEntry.value.item1[i];
      final actualSubstitution = actualDaySubstitutions.item1[i];
      expect(actualSubstitution.item2, targetSubstitution.item2, reason: "Integration names do not match; day: ${daySubstitutionsEntry.key} index: $i");
      expect(actualSubstitution.item1, targetSubstitution.item1, reason: "Substitution data does not match; day: ${daySubstitutionsEntry.key} index: $i");
    }
  }
}

void main() {
  test("Merge test separate days", () {
    final weekSubstitutionsA = WeekSubstitutions(null, "A");
    final substADate = DateTime.parse("2022-03-23");
    weekSubstitutionsA.setDay([{"a" : "a"}], substADate, "A");
    final weekSubstitutionsB = WeekSubstitutions(null, "B");
    final substBDate = DateTime.parse("2022-03-24");
    weekSubstitutionsB.setDay([{"b" : "b"}], substBDate, "B");
    weekSubstitutionsA.merge(weekSubstitutionsB, "B");

    final weekSubstitutionsTarget = WeekSubstitutions(null, "");
    weekSubstitutionsTarget.setDay([{"a" : "a"}], substADate, "A");
    weekSubstitutionsTarget.setDay([{"b" : "b"}], substBDate, "B");
    compareWeekSubstitutions(weekSubstitutionsA, weekSubstitutionsTarget);
  });

  test("Merge test same day", () {
    final weekSubstitutionsA = WeekSubstitutions(null, "A");
    final substDate = DateTime.parse("2022-03-23");
    weekSubstitutionsA.setDay([{"Stunde" : "1-2"}], substDate, "A");
    final weekSubstitutionsB = WeekSubstitutions(null, "B");
    weekSubstitutionsB.setDay([{"Stunde" : "3-4"}, {"Stunde" : "10-11"}], substDate, "B");
    weekSubstitutionsA.merge(weekSubstitutionsB, "B");

    final weekSubstitutionsTarget = WeekSubstitutions(null, "");
    weekSubstitutionsTarget.weekSubstitutions![substDate.weekday.toString()] = Tuple2([
      const Tuple2({"Stunde" : "1-2"}, "A"),
      const Tuple2({"Stunde" : "3-4"}, "B"),
      const Tuple2({"Stunde" : "10-11"}, "B"),
    ], substDate.toString());
    compareWeekSubstitutions(weekSubstitutionsA, weekSubstitutionsTarget);
  });

  test("Merge test same hours", () {
    final weekSubstitutionsA = WeekSubstitutions(null, "A");
    final substDate = DateTime.parse("2022-03-23");
    weekSubstitutionsA.setDay([{"Stunde" : "3-4"}], substDate, "A");
    final weekSubstitutionsB = WeekSubstitutions(null, "B");
    weekSubstitutionsB.setDay([{"Stunde" : "3-4", "Text" : "Something"}], substDate, "B");
    weekSubstitutionsA.merge(weekSubstitutionsB, "B");

    final weekSubstitutionsTarget = WeekSubstitutions(null, "");
    weekSubstitutionsTarget.weekSubstitutions![substDate.weekday.toString()] = Tuple2([
      const Tuple2({"Stunde" : "3-4", "Text" : "Something"}, "B"),
    ], substDate.toString());
    compareWeekSubstitutions(weekSubstitutionsA, weekSubstitutionsTarget);
  });

  test("Merge test overlapping hour range", () {
    final weekSubstitutionsA = WeekSubstitutions(null, "A");
    final substDate = DateTime.parse("2022-03-23");
    weekSubstitutionsA.setDay([{"Stunde" : "1-6"}, {"Stunde" : "8-9"}], substDate, "A");
    final weekSubstitutionsB = WeekSubstitutions(null, "B");
    weekSubstitutionsB.setDay([{"Stunde" : "3-4"}], substDate, "B");
    weekSubstitutionsA.merge(weekSubstitutionsB, "B");

    final weekSubstitutionsTarget = WeekSubstitutions(null, "");
    weekSubstitutionsTarget.weekSubstitutions![substDate.weekday.toString()] = Tuple2([
      const Tuple2({"Stunde" : "1"}, "A"),
      const Tuple2({"Stunde" : "2"}, "A"),
      const Tuple2({"Stunde" : "3"}, "B"),
      const Tuple2({"Stunde" : "4"}, "B"),
      const Tuple2({"Stunde" : "5"}, "A"),
      const Tuple2({"Stunde" : "6"}, "A"),
      const Tuple2({"Stunde" : "8"}, "A"),
      const Tuple2({"Stunde" : "9"}, "A"),
    ], substDate.toString());
    compareWeekSubstitutions(weekSubstitutionsA, weekSubstitutionsTarget);
  });

  test("Merge test overlapping higher hour range", () {
    final weekSubstitutionsA = WeekSubstitutions(null, "A");
    final substDate = DateTime.parse("2022-03-23");
    weekSubstitutionsA.setDay([{"Stunde" : "3-4"}, {"Stunde" : "8-9"}], substDate, "A");
    final weekSubstitutionsB = WeekSubstitutions(null, "B");
    weekSubstitutionsB.setDay([{"Stunde" : "4-6"}], substDate, "B");
    weekSubstitutionsA.merge(weekSubstitutionsB, "B");

    final weekSubstitutionsTarget = WeekSubstitutions(null, "");
    weekSubstitutionsTarget.weekSubstitutions![substDate.weekday.toString()] = Tuple2([
      const Tuple2({"Stunde" : "3"}, "A"),
      const Tuple2({"Stunde" : "4"}, "B"),
      const Tuple2({"Stunde" : "5"}, "B"),
      const Tuple2({"Stunde" : "6"}, "B"),
      const Tuple2({"Stunde" : "8"}, "A"),
      const Tuple2({"Stunde" : "9"}, "A"),
    ], substDate.toString());
    compareWeekSubstitutions(weekSubstitutionsA, weekSubstitutionsTarget);
  });

  test("Merge test overlapping lower hour range", () {
    final weekSubstitutionsA = WeekSubstitutions(null, "A");
    final substDate = DateTime.parse("2022-03-23");
    weekSubstitutionsA.setDay([{"Stunde" : "3-4"}, {"Stunde" : "8-9"}], substDate, "A");
    final weekSubstitutionsB = WeekSubstitutions(null, "B");
    weekSubstitutionsB.setDay([{"Stunde" : "1-3"}], substDate, "B");
    weekSubstitutionsA.merge(weekSubstitutionsB, "B");

    final weekSubstitutionsTarget = WeekSubstitutions(null, "");
    weekSubstitutionsTarget.weekSubstitutions![substDate.weekday.toString()] = Tuple2([
      const Tuple2({"Stunde" : "1"}, "B"),
      const Tuple2({"Stunde" : "2"}, "B"),
      const Tuple2({"Stunde" : "3"}, "B"),
      const Tuple2({"Stunde" : "4"}, "A"),
      const Tuple2({"Stunde" : "8"}, "A"),
      const Tuple2({"Stunde" : "9"}, "A"),
    ], substDate.toString());
    compareWeekSubstitutions(weekSubstitutionsA, weekSubstitutionsTarget);
  });

  test("Merge test full overlapping hour range", () {
    final weekSubstitutionsA = WeekSubstitutions(null, "A");
    final substDate = DateTime.parse("2022-03-23");
    weekSubstitutionsA.setDay([{"Stunde" : "3-4"}, {"Stunde" : "8-9"}], substDate, "A");
    final weekSubstitutionsB = WeekSubstitutions(null, "B");
    weekSubstitutionsB.setDay([{"Stunde" : "2-6"}], substDate, "B");
    weekSubstitutionsA.merge(weekSubstitutionsB, "B");

    final weekSubstitutionsTarget = WeekSubstitutions(null, "");
    weekSubstitutionsTarget.weekSubstitutions![substDate.weekday.toString()] = Tuple2([
      const Tuple2({"Stunde" : "2"}, "B"),
      const Tuple2({"Stunde" : "3"}, "B"),
      const Tuple2({"Stunde" : "4"}, "B"),
      const Tuple2({"Stunde" : "5"}, "B"),
      const Tuple2({"Stunde" : "6"}, "B"),
      const Tuple2({"Stunde" : "8"}, "A"),
      const Tuple2({"Stunde" : "9"}, "A"),
    ], substDate.toString());
    compareWeekSubstitutions(weekSubstitutionsA, weekSubstitutionsTarget);
  });

  test("Merge test overlapping single range", () {
    final weekSubstitutionsA = WeekSubstitutions(null, "A");
    final substDate = DateTime.parse("2022-03-23");
    weekSubstitutionsA.setDay([{"Stunde" : "2-6"}, {"Stunde" : "8-9"}], substDate, "A");
    final weekSubstitutionsB = WeekSubstitutions(null, "B");
    weekSubstitutionsB.setDay([{"Stunde" : "4"}], substDate, "B");
    weekSubstitutionsA.merge(weekSubstitutionsB, "B");

    final weekSubstitutionsTarget = WeekSubstitutions(null, "");
    weekSubstitutionsTarget.weekSubstitutions![substDate.weekday.toString()] = Tuple2([
      const Tuple2({"Stunde" : "2"}, "A"),
      const Tuple2({"Stunde" : "3"}, "A"),
      const Tuple2({"Stunde" : "4"}, "B"),
      const Tuple2({"Stunde" : "5"}, "A"),
      const Tuple2({"Stunde" : "6"}, "A"),
      const Tuple2({"Stunde" : "8"}, "A"),
      const Tuple2({"Stunde" : "9"}, "A"),
    ], substDate.toString());
    compareWeekSubstitutions(weekSubstitutionsA, weekSubstitutionsTarget);
  });
}
