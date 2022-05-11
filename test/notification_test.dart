import 'package:stundenplan/notifiy.dart';
import 'package:stundenplan/week_subsitutions.dart';
import 'package:test/test.dart';

void main() {
  test("Test drop out notification message", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-23");
    substitutionsBefore.setDay([{"Stunde" : "3-4", "Raum" : "C2.02"}, {"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "3-4", "statt Fach" : "en2", "Raum" : "C2.02", "Entfall" : "x", "Text" : "Something"}, {"Stunde" : "1-2"}], substDate, "now");

    final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
    expect(result.item1, "en2 fällt aus");
    expect(result.item2, 'Heute fällt en2 aus\nText: "Something"');
  });

  test("Test subject change notification message", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-24");
    substitutionsBefore.setDay([{"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "5-6", "statt Fach" : "en2", "Fach" : "ma5"}, {"Stunde" : "1-2"}], substDate, "now");

    final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
    expect(result.item1, "ma5 anstatt en2");
    expect(result.item2, "Morgen findet statt en2, ma5 statt");
  });

  test("Test reverted subject change notification message, with unspecified original subject", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-24");
    substitutionsBefore.setDay([{"Stunde" : "5-6", "statt Fach" : "\u{00A0}", "Fach" : "ma5"}, {"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "1-2"}], substDate, "now");

    final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
    expect(result.item1, "nicht ma5 in der 5-6");
    expect(result.item2, "Morgen findet doch nicht ma5 in der 5-6 statt");
  });

  test("Test room change notification message", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-24");
    substitutionsBefore.setDay([{"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "5-6", "statt Fach" : "PO2", "statt Raum" : "C2.02", "Raum" : "C1.05"}, {"Stunde" : "1-2"}], substDate, "now");

    final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
    expect(result.item1, "PO2 in C1.05");
    expect(result.item2, "Morgen findet PO2 in C1.05, anstatt in Raum C2.02 statt");
  });

  test("Test room change notification message", () {
    final substitutionsBefore = WeekSubstitutions(null, "before");
    final substDate = DateTime.parse("2022-03-24");
    substitutionsBefore.setDay([{"Stunde" : "1-2"}], substDate, "before");
    final weekSubstitutions = WeekSubstitutions(null, "now");
    weekSubstitutions.setDay([{"Stunde" : "5-6", "statt Fach" : "wn1", "statt Lehrer" : "Sz", "Vertretung" : "Swz"}, {"Stunde" : "1-2"}], substDate, "now");

    final result = getSubstitutionsNotificationText(substitutionsBefore.toJson(), weekSubstitutions.toJson())!;
    expect(result.item1, "wn1 mit Swz");
    expect(result.item2, "wn1 wird Morgen von Swz, anstatt von Sz unterrichtet");
  });
}