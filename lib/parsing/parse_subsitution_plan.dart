import 'dart:collection';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:http/http.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/parsing/parsing_util.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:tuple/tuple.dart'; // Contains a client for making API calls
import 'dart:math';

Future<void> overwriteContentWithSubsitutionPlan(SharedState sharedState, Client client, Content content, List<String> subjects, String schoolClassName) async {
  Tuple2<List<HashMap<String, String>>, int> ret = await getCourseSubstitutionPlan(schoolClassName, Constants.substitutionLinkBase, client);
  List<HashMap<String, String>> mainPlan = ret.item1;
  int weekDayMain = ret.item2;
  writeSubstitutionPlan(mainPlan, weekDayMain, content, subjects);
  if (!Constants.displayFullHeightSchoolGrades.contains(sharedState.profileManager.schoolGrade)) {
    Tuple2<List<HashMap<String, String>>, int> courseRet = await getCourseSubstitutionPlan("${sharedState.profileManager.schoolGrade}K", Constants.substitutionLinkBase, client);
    List<HashMap<String, String>> coursePlan = courseRet.item1;
    int weekDayCourse = courseRet.item2;
    writeSubstitutionPlan(coursePlan, weekDayCourse, content, subjects);
  }
}

writeSubstitutionPlan(List<HashMap<String, String>> plan, int weekDay, Content content, List<String> subjects) {
  for (int i = 0; i < plan.length; i++) {
    var hours = strip(plan[i]["Stunde"]).split("-");

    // Fill cell
    Cell cell = new Cell();
    cell.subject = strip(plan[i]["Fach"]);
    cell.originalSubject = strip(plan[i]["statt Fach"]);
    if (!subjects.contains(cell.originalSubject)) {  // If user dose not have that subject skip that class
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
      var hour = int.parse(hours[0]);
      cell.footnotes = content.cells[hour-1][weekDay].footnotes;
      content.setCell(hour-1, weekDay, cell);
    } else if (hours.length == 2) {
      // Hour range (5-6)
      var hourStart = int.parse(hours[0]);
      var hourEnd = int.parse(hours[1]);
      for (var i = hourStart; i < hourEnd + 1; i++) {
        cell.footnotes = content.cells[i-1][weekDay].footnotes;
        content.setCell(i-1, weekDay, cell);
      }
    }
  }
}

Future<Tuple2<List<HashMap<String, String>>, int>> getCourseSubstitutionPlan(String course, String linkBase, client) async {
  Response response = await client.get('${linkBase}_${course}.htm');
  if (response.statusCode != 200) return Tuple2(new List<HashMap<String, String>>(), 1);

  var document = parse(response.body);

  // Get weekday for that substitute table
  String headerText = strip(document.getElementsByTagName("body")[0].children[0].children[0].children[2].text.replaceAll("  ", "/"));
  var regexp = RegExp(r"^\w+\/(?<day>\d+).(?<month>\d+).");
  RegExpMatch match = regexp.firstMatch(headerText);
  print("${DateTime.now().year}.${int.parse(match.namedGroup("month"))}.${int.parse(match.namedGroup("day"))}");
  var substituteWeekday = DateTime(DateTime.now().year, int.parse(match.namedGroup("month")), int.parse(match.namedGroup("day"))).weekday;
  if (substituteWeekday > 5) {
    substituteWeekday = min(DateTime.now().weekday, 5);
  }

  List<dom.Element> tables = document.getElementsByTagName("table");
  for (int i = 0; i < tables.length; i++) {
    if (!tables[i].attributes.containsKey("rules")) {
      tables.removeAt(i);
    }
  }

  dom.Element mainTable = tables[0];
  List<dom.Element> rows = mainTable.getElementsByTagName("tr");
  List<String> headerInformation = [
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
  List<HashMap<String, String>> subsituions = new List<HashMap<String, String>>();

  for (var row in rows) {
    HashMap<String, String> substituion = new HashMap<String, String>();
    var coloumns = row.getElementsByTagName("td");
    for (int i = 0; i < coloumns.length; i++) {
      substituion[headerInformation[i]] =
          coloumns[i].text.replaceAll("\n", " ");
    }
    subsituions.add(substituion);
  }

  return Tuple2(subsituions, substituteWeekday);
}