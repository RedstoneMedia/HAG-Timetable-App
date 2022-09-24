import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:stundenplan/notifiy.dart';
import 'package:stundenplan/week_subsitutions.dart';
import 'package:test/test.dart';

Map<String, dynamic> getSubstitutionMap({
  required String hour,
  String originalSubject = "---",
  String subject = "---",
  String teacher = "---",
  String room = "---",
  String originalTeacher = "---",
  String originalRoom = "---",
  String text = "",
  String dropOut = "",
}) {
  return {
    "Stunde" : hour,
    "statt Fach" : originalSubject,
    "Fach" : subject,
    "Vertretung" : teacher,
    "Raum" : room,
    "statt Lehrer" : originalTeacher,
    "statt Raum" : originalRoom,
    "Text" : text,
    "Entfall" : dropOut
  };
}

void main() {
  test("Test drop out notification message", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-23");
    substitutionsBefore.setDay([{"Stunde" : "3-4", "Raum" : "C2.02"}, {"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "3-4", "statt Fach" : "en2", "Raum" : "C2.02", "Entfall" : "x", "Text" : "Something"}, {"Stunde" : "1-2"}], substDate, "now");
    withClock(Clock.fixed(substDate), () {
      final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
      expect(result.item1, "en2 fällt aus");
      expect(result.item2, 'Heute fällt en2 aus\nText: "Something"');
    });
  });

  test("Test subject change notification message", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-24");
    substitutionsBefore.setDay([{"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "5-6", "statt Fach" : "en2", "Fach" : "ma5"}, {"Stunde" : "1-2"}], substDate, "now");
    withClock(Clock.fixed(substDate), () {
      final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
      expect(result.item1, "ma5 anstatt en2");
      expect(result.item2, "Heute findet statt en2, ma5 statt");
    });
  });

  test("Test reverted subject change notification message, with unspecified original subject", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-24");
    substitutionsBefore.setDay([{"Stunde" : "5-6", "statt Fach" : "---", "Fach" : "ma5"}, {"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "1-2"}], substDate, "now");

    withClock(Clock.fixed(substDate), () {
      final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
      expect(result.item1, "nicht ma5 in der 5-6");
      expect(result.item2, "Heute findet doch nicht ma5 in der 5-6 statt");
    });
  });

  test("Test room change notification message", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-23");
    substitutionsBefore.setDay([{"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "5-6", "statt Fach" : "PO2", "statt Raum" : "C2.02", "Raum" : "C1.05"}, {"Stunde" : "1-2"}], substDate, "now");
    withClock(Clock.fixed(substDate.add(const Duration(days: 1))), () {
      final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
      expect(result.item1, "PO2 in C1.05");
      expect(result.item2, "Morgen findet PO2 in C1.05, anstatt in Raum C2.02 statt");
    });
  });

  test("Test teacher change notification message", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-24");
    substitutionsBefore.setDay([{"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "5-6", "statt Fach" : "wn1", "statt Lehrer" : "Sz", "Vertretung" : "Swz"}, {"Stunde" : "1-2"}], substDate, "now");
    withClock(Clock.fixed(substDate.add(const Duration(days: 1))), () {
      final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
      expect(result.item1, "wn1 mit Swz");
      expect(result.item2, "wn1 wird Morgen von Swz, anstatt von Sz unterrichtet");
    });
  });

  test("Test no notification message, when nothing changed", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-23");
    substitutionsBefore.setDay([{"Stunde" : "1-2", "statt Fach" : "PO1", "Raum" : "C1.05", "Entfall" : "x"}, {"Stunde" : "5-6", "statt Fach" : "ek1", "Raum" : "C1.03", "Entfall" : "x"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "5-6", "statt Fach" : "ek1", "Raum" : "C1.03", "Entfall" : "---"}, {"Stunde" : "1-2", "statt Fach" : "PO1", "Raum" : "C1.05", "Entfall" : "x"}], substDate, "now");
    withClock(Clock.fixed(substDate), () {
      final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson());
      expect(result, null);
    });
  });

  group("cleanupWeekSubstitutionJson", () {
    test("Test cleanupWeekSubstitutionJson", () {
      final substitutions = WeekSubstitutions(null, "before");
      final substDate = DateTime.parse("2022-03-24");
      substitutions.setDay([
        getSubstitutionMap(hour: "1", originalSubject: "A"),
        getSubstitutionMap(hour: " 2", originalSubject: " B ", teacher: " Swz\t", dropOut: "\nx\n"),
        getSubstitutionMap(hour: "3-4", originalSubject: "C ", room: " C2.01", originalRoom: "\nC2.01 "),
        getSubstitutionMap(hour: "5-6", originalSubject: "  D ", subject: "\t B  ", text: "I'm allowed to have spaces"),
        getSubstitutionMap(hour: "8-9", originalSubject: "\nE\n", originalTeacher: "  Go "),
        getSubstitutionMap(hour: "3-4", originalSubject: "F"),
        getSubstitutionMap(hour: "2", originalSubject: "G"),
        getSubstitutionMap(hour: "1", originalSubject: "H"),
        getSubstitutionMap(hour: "10-11", originalSubject: "\u{00A0}"),
      ], substDate, "before");
      final allSubjects = ["A", "B", "C", "D", "E"];
      final substitutionsJson = substitutions.toJson();
      withClock(Clock.fixed(substDate), () => cleanupWeekSubstitutionJson(substitutionsJson, allSubjects));
      expect(const DeepCollectionEquality().equals(substitutionsJson, {"4" : [[
        getSubstitutionMap(hour: "1", originalSubject: "A"),
        getSubstitutionMap(hour: "2", originalSubject: "B", teacher: "Swz", dropOut: "x"),
        getSubstitutionMap(hour: "3-4", originalSubject: "C", room: "C2.01", originalRoom: "C2.01"),
        getSubstitutionMap(hour: "5-6", originalSubject: "D", subject: "B", text: "I'm allowed to have spaces"),
        getSubstitutionMap(hour: "8-9", originalSubject: "E", originalTeacher: "Go"),
        getSubstitutionMap(hour: "10-11", originalSubject: "\u{00A0}"),
      ], substDate.toString()]}), true, reason: "Substitutions were not cleaned up sufficiently");
    });

    test("Test cleanupWeekSubstitutionJson check day removal mid week", () {
      final substitutions = WeekSubstitutions(null, "before");
      substitutions.setDay([getSubstitutionMap(hour: "1", originalSubject: "A")], DateTime.parse("2022-03-21"), "something");
      substitutions.setDay([getSubstitutionMap(hour: "2", originalSubject: "A")], DateTime.parse("2022-03-25"), "something");
      substitutions.setDay([getSubstitutionMap(hour: "3", originalSubject: "A")], DateTime.parse("2022-03-28"), "something");
      final substitutionsJson = substitutions.toJson();
      withClock(Clock.fixed(DateTime.parse("2022-03-23")), () => cleanupWeekSubstitutionJson(substitutionsJson, ["A"]));
      expect(const DeepCollectionEquality().equals(substitutionsJson, {
        "5" : [[getSubstitutionMap(hour: "2", originalSubject: "A")], DateTime.parse("2022-03-25").toString()]
      }), true);
    });

    test("Test cleanupWeekSubstitutionJson check day removal week start", () {
      final substitutions = WeekSubstitutions(null, "before");
      substitutions.setDay([getSubstitutionMap(hour: "1", originalSubject: "A")], DateTime.parse("2022-03-17"), "something");
      substitutions.setDay([getSubstitutionMap(hour: "2", originalSubject: "A")], DateTime.parse("2022-03-21"), "something");
      substitutions.setDay([getSubstitutionMap(hour: "3", originalSubject: "A")], DateTime.parse("2022-03-25"), "something");
      final substitutionsJson = substitutions.toJson();
      withClock(Clock.fixed(DateTime.parse("2022-03-21")), () => cleanupWeekSubstitutionJson(substitutionsJson, ["A"]));
      expect(const DeepCollectionEquality().equals(substitutionsJson, {
        "1" : [[getSubstitutionMap(hour: "2", originalSubject: "A")], DateTime.parse("2022-03-21").toString()],
        "5" : [[getSubstitutionMap(hour: "3", originalSubject: "A")], DateTime.parse("2022-03-25").toString()]
      }), true);
    });

    test("Test cleanupWeekSubstitutionJson check day removal next week", () {
      final substitutions = WeekSubstitutions(null, "before");
      substitutions.setDay([getSubstitutionMap(hour: "1", originalSubject: "A")], DateTime.parse("2022-03-22"), "something");
      substitutions.setDay([getSubstitutionMap(hour: "2", originalSubject: "A")], DateTime.parse("2022-03-25"), "something");
      substitutions.setDay([getSubstitutionMap(hour: "3", originalSubject: "A")], DateTime.parse("2022-03-28"), "something");
      final substitutionsJson = substitutions.toJson();
      withClock(Clock.fixed(DateTime.parse("2022-03-26")), () => cleanupWeekSubstitutionJson(substitutionsJson, ["A"]));
      expect(const DeepCollectionEquality().equals(substitutionsJson, {
        "1" : [[getSubstitutionMap(hour: "3", originalSubject: "A")], DateTime.parse("2022-03-28").toString()]
      }), true);
    });

    test("Test cleanupWeekSubstitutionJson day boundary", () {
      final substitutions = WeekSubstitutions(null, "before");
      substitutions.setDay([getSubstitutionMap(hour: "5-6", originalSubject: "PO")], DateTime.parse("2022-09-15"), "something");
      final substitutionsJson = substitutions.toJson();
      withClock(Clock.fixed(DateTime.parse("2022-09-17 00:11:53")), () => cleanupWeekSubstitutionJson(substitutionsJson, ["PO"]));
      expect(const DeepCollectionEquality().equals(substitutionsJson, {}), true);
    });
  });
}