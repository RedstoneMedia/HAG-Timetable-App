import 'dart:collection';
import 'dart:math';

import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:http/http.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/parsing/parsing_util.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:tuple/tuple.dart'; // Contains a client for making API calls

Future<void> overwriteContentWithSubsitutionPlan(
    SharedState sharedState,
    Client client,
    Content content,
    List<String> subjects,
    String schoolClassName) async
{
  final ret = await getCourseSubstitutionPlan(schoolClassName, Constants.substitutionLinkBase, client);
  final mainPlan = ret.item1;
  final weekDayMain = ret.item2;
  writeSubstitutionPlan(mainPlan, weekDayMain, content, subjects);
  if (!Constants.displayFullHeightSchoolGrades.contains(sharedState.profileManager.schoolGrade)) {
    final courseRet = await getCourseSubstitutionPlan(
        "${sharedState.profileManager.schoolGrade}K",
        Constants.substitutionLinkBase,
        client);
    final coursePlan = courseRet.item1;
    final weekDayCourse = courseRet.item2;
    writeSubstitutionPlan(coursePlan, weekDayCourse, content, subjects);
  }
}

void writeSubstitutionPlan(List<HashMap<String, String>> plan, int weekDay,
    Content content, List<String> subjects)
{
  for (var i = 0; i < plan.length; i++) {
    final hours = strip(plan[i]["Stunde"]).split("-");

    // Fill cell
    final cell = Cell();
    cell.subject = strip(plan[i]["Fach"]);
    cell.originalSubject = strip(plan[i]["statt Fach"]);
    if (!subjects.contains(cell.originalSubject)) {
      // If user dose not have that subject skip that class
      continue;
    }
    cell.teacher = strip(plan[i]["Vertretung"]);
    cell.originalTeacher = strip(plan[i]["statt Lehrer"]);
    cell.room = strip(plan[i]["Raum"]);
    cell.originalRoom = strip(plan[i]["statt Raum"]);
    cell.text = plan[i]["Text"];
    cell.isDropped = strip(plan[i]["Entfall"]) == "x";
    if (!cell.isDropped) {
      cell.isSubstitute = true;
    }

    if (hours.length == 1) {
      // No hour range (5)
      final hour = int.parse(hours[0]);
      cell.footnotes = content.cells[hour - 1][weekDay].footnotes;
      content.setCell(hour - 1, weekDay, cell);
    } else if (hours.length == 2) {
      // Hour range (5-6)
      final hourStart = int.parse(hours[0]);
      final hourEnd = int.parse(hours[1]);
      for (var i = hourStart; i < hourEnd + 1; i++) {
        cell.footnotes = content.cells[i - 1][weekDay].footnotes;
        content.setCell(i - 1, weekDay, cell);
      }
    }
  }
}

Future<Tuple2<List<HashMap<String, String>>, int>> getCourseSubstitutionPlan(String course, String linkBase, Client client) async {
  final response = await client.get('${linkBase}_$course.htm');
  if (response.statusCode != 200) {
    return const Tuple2(<HashMap<String, String>>[], 1);
  }

  final document = parse(response.body);
  if (document.outerHtml.contains("Fatal error")) {
    return const Tuple2(<HashMap<String, String>>[], 1);
  }

  // Get weekday for that substitute table
  final headerText = strip(document
      .getElementsByTagName("body")[0]
      .children[0]
      .children[0]
      .children[2]
      .text
      .replaceAll("  ", "/"));
  final regexp = RegExp(r"^\w+\/(?<day>\d+).(?<month>\d+).");
  final match = regexp.firstMatch(headerText);
  var substituteWeekday = DateTime(
          DateTime.now().year,
          int.parse(match.namedGroup("month")),
          int.parse(match.namedGroup("day")))
      .weekday;
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
  final subsituions = <HashMap<String, String>>[];

  for (final row in rows) {
    final substituion = HashMap<String, String>();
    final coloumns = row.getElementsByTagName("td");
    for (var i = 0; i < coloumns.length; i++) {
      substituion[headerInformation[i]] =
          coloumns[i].text.replaceAll("\n", " ");
    }
    subsituions.add(substituion);
  }

  return Tuple2(subsituions, substituteWeekday);
}
