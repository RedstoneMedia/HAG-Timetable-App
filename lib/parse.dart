import 'dart:collection';
import 'dart:math';
import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:html/dom.dart' as dom;
import 'package:stundenplan/content.dart'; // Contains DOM related classes for extracting data from elements

const String SUBSTITUTION_LINK_BASE = "https://hag-iserv.de/iserv/public/plan/show/Sch%C3%BCler-Stundenpl%C3%A4ne/b006cb5cf72cba5c/svertretung/svertretungen";
const String TIMETABLE_LINK_BASE = "https://hag-iserv.de/iserv/public/plan/show/Schüler-Stundenpläne/b006cb5cf72cba5c/splan/Kla1A";

String strip(String s) {
  return s.replaceAll(" ", "").replaceAll("\t", "").replaceAll("\n", "");
}


Future<void> initiate(course, Content content) async {
  var client = Client();
  var weekDay = DateTime.now().weekday;

  await fillTimeTable(course, TIMETABLE_LINK_BASE, client, content);

  List<HashMap<String, String>> plan = await getCourseSubsitutionPlan(course, SUBSTITUTION_LINK_BASE, client);
  List<HashMap<String, String>> coursePlan = await getCourseSubsitutionPlan("11K", SUBSTITUTION_LINK_BASE, client);
  plan.addAll(coursePlan);
  for (int i = 0; i < plan.length; i++) {
    var hours = strip(plan[i]["Stunde"]).split("-");

    // Fill cell
    Cell cell = new Cell();
    cell.subject = strip(plan[i]["Fach"]);
    cell.originalSubject = strip(plan[i]["statt Fach"]);
    cell.teacher = strip(plan[i]["Vertretung"]);
    cell.originalTeacher = strip(plan[i]["statt Lehrer"]);
    cell.room = strip(plan[i]["Raum"]);
    cell.originalRoom = strip(plan[i]["statt Raum"]);
    cell.text = plan[i]["Text"];
    cell.isDropped = strip(plan[i]["Entfall"]) == "x";

    if (hours.length == 1) {
      // No hour range (5)
      var hour = int.parse(hours[0]);
      content.setCell(hour, min(weekDay, 5), cell);
    } else if (hours.length == 2) {
      // Hour range (5-6)
      var hourStart = int.parse(hours[0]);
      var hourEnd = int.parse(hours[1]);
      for (var i = hourStart; i < hourEnd + 1; i++) {
        content.setCell(i, min(weekDay, 5), cell);
      }
    }
  }
}

Future<void> fillTimeTable(String course, String linkBase, client, Content content) async {
  Response response = await client.get('${linkBase}_${course}.htm');
  if (response.statusCode != 200) {
    print("Cannot get timetable");
    return;
  }

  var document = parse(response.body);

  // Find all tables with attr rules
  List<dom.Element> tables = document.getElementsByTagName("table");
  for (int i = 0; i < tables.length; i++) {
    if (!tables[i].attributes.containsKey("rules")) {
      tables.removeAt(i);
    }
  }
  var mainTimeTable = tables[0];
  var footnoteTable = tables[1];

  List<dom.Element> rows = mainTimeTable.children[0].children;
  rows.removeAt(0);

  for (var y = 0; y < rows.length; y++) {
    var row = rows[y];
    var columns = row.children;
    var tableX = 0;
    if (columns.length <= 0) {
      continue;
    }
    for (var x = 0; x < 6; x++) {
      if (x == 0) {
        parseOneCell(columns[x], x, y, content);
        tableX++;
      } else {
        var doParseCell = true;
        if (y != 0) {
          var contentY = (y/2).floor();
          if (contentY >= content.cells.length) {
            continue;
          }
          var isDoubleClass = content.cells[contentY][x].isDoubleClass;
          if (isDoubleClass) {
            doParseCell = false;
          }
          print("${contentY} ${x} ${doParseCell} ${tableX}");
        }
        if (doParseCell) {
          parseOneCell(columns[tableX], x, y, content);
          tableX++;
        }
      }
    }
  }
}

void parseOneCell(dom.Element cellDom, int x, int y, Content content) {
  var cell = new Cell();
  // sidebar
  if (x == 0) {
    return;
  }

  // Normal cell
  var hours = int.parse(cellDom.attributes["rowspan"]) / 2;
  cell.isDoubleClass = hours == 2;
  List<dom.Element> cellData = cellDom.children[0].children[0].children;
  if (cellData.length >= 2) {
    List<dom.Element> teacherAndRoom = cellData[0].children;
    List<dom.Element> subjectAndFootnote = cellData[1].children;
    cell.teacher = strip(teacherAndRoom[0].text);
    cell.room = strip(teacherAndRoom[1].text);
    cell.subject = strip(subjectAndFootnote[0].text);
  }

  for (var i = 0; i < hours; i++) {
    content.setCell((y / 2).floor() + i, x, cell);
  }
}

Future<List<HashMap<String, String>>> getCourseSubsitutionPlan(
    String course, String linkBase, client) async {
  Response response = await client.get('${linkBase}_${course}.htm');
  if (response.statusCode != 200) return new List<HashMap<String, String>>();

  var document = parse(response.body);
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
  List<HashMap<String, String>> subsituions =
      new List<HashMap<String, String>>();

  for (var row in rows) {
    HashMap<String, String> substituion = new HashMap<String, String>();
    var coloumns = row.getElementsByTagName("td");
    for (int i = 0; i < coloumns.length; i++) {
      substituion[headerInformation[i]] =
          coloumns[i].text.replaceAll("\n", " ");
    }
    subsituions.add(substituion);
  }

  return subsituions;
}
