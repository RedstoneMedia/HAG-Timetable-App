import 'dart:math';
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:http/http.dart';  // Contains a client for making API calls
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/parsing/parsing_util.dart';
import 'package:stundenplan/shared_state.dart';

Future<void> overwriteContentWithSubsitutionPlan(
    SharedState sharedState,
    Client client,
    Content content,
    List<String> subjects,
    String schoolClassName) async
{
  // Get main substitutions
  final ret = await getCourseSubstitutionPlan(schoolClassName, Constants.substitutionLinkBase, client);
  final mainPlan = ret["substitutions"] as List<Map<String, String>>;
  final mainSubstituteDate = ret["substituteDate"] as DateTime;
  sharedState.weekSubstitutions.setDay(mainPlan, mainSubstituteDate);

  //  Get course substitutions
  if (!Constants.displayFullHeightSchoolGrades.contains(sharedState.profileManager.schoolGrade)) {
    final courseRet = await getCourseSubstitutionPlan(
        "${sharedState.profileManager.schoolGrade}K",
        Constants.substitutionLinkBase,
        client);
    final coursePlan = courseRet["substitutions"] as List<Map<String, String>>;
    final courseSubstituteDate = ret["substituteDate"] as DateTime;
    sharedState.weekSubstitutions.setDay(coursePlan, courseSubstituteDate);
  }

  // Write substitutions to content.
  for (final weekDayString in sharedState.weekSubstitutions.weekSubstitutions!.keys) {
    final weekDay = int.parse(weekDayString);
    final daySubstitution = sharedState.weekSubstitutions.weekSubstitutions![weekDayString]!;
    writeSubstitutionPlan(daySubstitution.item1, weekDay, content, subjects);
  }
}

void writeSubstitutionPlan(List<Map<String, dynamic>> plan, int weekDay,
    Content content, List<String> subjects)
{
  for (var i = 0; i < plan.length; i++) {
    final hours = customStrip(plan[i]["Stunde"] as String).split("-");

    // Fill cell
    final cell = Cell();
    cell.subject = customStrip(plan[i]["Fach"] as String);
    cell.originalSubject = customStrip(plan[i]["statt Fach"] as String);
    if (!subjects.contains(cell.originalSubject)) {
      // Unicode 00A0 (Non breaking space, because that makes sense) indicates that
      // the subject replaces all other lessons taking place in the same time
      if (cell.originalSubject != "\u{00A0}") {
        // If user dose not have that subject skip that class
        continue;
      }
    }
    cell.teacher = customStrip(plan[i]["Vertretung"] as String);
    cell.originalTeacher = customStrip(plan[i]["statt Lehrer"] as String);
    cell.room = customStrip(plan[i]["Raum"] as String);
    cell.originalRoom = customStrip(plan[i]["statt Raum"] as String);
    cell.text = plan[i]["Text"] as String;
    cell.isDropped = customStrip(plan[i]["Entfall"] as String).toLowerCase() == "x";

    // Sometimes a substitution is set, but there is no data set which means that it is dropped.
    if (cell.originalSubject == "\u{00A0}" && cell.subject == "\u{00A0}" && cell.room == "\u{00A0}" && cell.teacher == "\u{00A0}") {
      cell.isDropped = true;
    } else if (!cell.isDropped) {
      cell.isSubstitute = true;
    }

    // Replace non breaking space with three dashes
    // We need to do this because, otherwise the cell will not have any visible text and will just display a solid color.
    if (cell.subject == "\u{00A0}") cell.subject = "---";
    if (cell.teacher == "\u{00A0}") cell.teacher = "---";
    if (cell.room == "\u{00A0}") cell.room = "---";

    if (hours.length == 1) {
      // No hour range (5)
      final hour = int.parse(hours[0]);
      cell.footnotes = content.getCell(hour - 1, weekDay).footnotes;
      content.setCell(hour - 1, weekDay, cell);
    } else if (hours.length == 2) {
      // Hour range (5-6)
      final hourStart = int.parse(hours[0]);
      final hourEnd = int.parse(hours[1]);
      for (var i = hourStart; i < hourEnd + 1; i++) {
        cell.footnotes = content.getCell(i -1, weekDay).footnotes;
        // Check if there is a subject that replaces all other subjects
        // (indicated by Unicode 00A0)
        if(content.getCell(i - 1, weekDay).originalSubject != "\u{00A0}") {
          content.setCell(i - 1, weekDay, cell);
        }
      }
    }
  }
}

Future<Map<String, dynamic>> getCourseSubstitutionPlan(String course, String linkBase, Client client) async {
  final response = await client.get(Uri.parse('${linkBase}_$course.htm'));
  if (response.statusCode != 200) {
    return {
      "substitutions" : <Map<String, String>>[],
      "substituteDate" : DateTime.now(),
      "substituteWeekday" : 1
    };
  }

  final document = parse(response.body);
  if (document.outerHtml.contains("Fatal error")) {
    return {
      "substitutions" : <Map<String, String>>[],
      "substituteDate" : DateTime.now(),
      "substituteWeekday" : 1
    };
  }

  // Get weekday for that substitute table
  final headerText = customStrip(document
      .getElementsByTagName("body")[0]
      .children[0]
      .children[0]
      .children[2]
      .text
      .replaceAll("  ", "/"));
  final regexp = RegExp(r"^\w+\/(?<day>\d+).(?<month>\d+).");
  final match = regexp.firstMatch(headerText)!;

  final substituteDate = DateTime(
      DateTime.now().year,
      int.parse(match.namedGroup("month")!),
      int.parse(match.namedGroup("day")!));
  var substituteWeekday = substituteDate.weekday;
  if (substituteWeekday > 5) {
    substituteWeekday = min(DateTime.now().weekday, 5);
  }

  final tables = document.getElementsByTagName("table");
  for (var i = 0; i < tables.length; i++) {
    if (!tables[i].attributes.containsKey("rules")) {
      tables.removeAt(i);
    }
  }

  final mainTable = tables[0];
  final rows = mainTable.getElementsByTagName("tr");
  final headerInformation = [
    "Stunde",
    "Fach",
    "Vertretung",
    "Raum",
    "statt Fach",
    "statt Lehrer",
    "statt Raum",
    "Text",
    "Entfall"
  ];
  rows.removeAt(0);
  final substitutions = <Map<String, String>>[];

  for (final row in rows) {
    final substitution = <String, String>{};
    final columns = row.getElementsByTagName("td");
    for (var i = 0; i < columns.length; i++) {
      substitution[headerInformation[i]] =
          columns[i].text.replaceAll("\n", " ");
    }
    substitutions.add(substitution);
  }

  return {
    "substitutions" : substitutions,
    "substituteDate" : substituteDate,
    "substituteWeekday" : substituteWeekday
  };
}