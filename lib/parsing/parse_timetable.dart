import 'dart:collection';
import 'dart:developer';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:http/http.dart'; // Contains a client for making API calls

import 'package:stundenplan/parsing/parsing_util.dart'; // Contains parsing utils
import 'package:stundenplan/content.dart';
import 'package:tuple/tuple.dart';

import '../constants.dart';


/// This will fill the input content with a timetable based on the other arguments
Future<void> fillTimeTable(String course, List<dom.Element>? tables,
    Content content, List<String> subjects) async
{
  if (tables != null) {
    final mainTimeTable = tables[0];
    final footnoteTable = tables[1];
    final footnoteMap = parseFootnoteTable(footnoteTable); // Parse the footnote table
    parseMainTimeTable(content, subjects, mainTimeTable, footnoteMap, course); // Parse the main timetable
  }
}

enum GetTileTablesResponse {
  notFound,
  badStatus,
  fatalError,
  noTable,
  ok
}

Future<Tuple2<List<dom.Element>?, GetTileTablesResponse>> getTimeTableTables(String course, String linkBase, Client client) async {
  // Get the html file
  final response = await client.get(Uri.parse('${linkBase}_$course.htm'));
  if (response.statusCode != 200) {
    if (response.body.contains("FileNotFoundException")) {
      log("Cannot get timetable $course: Not found", name: "parsing.timetable");
      return const Tuple2(null, GetTileTablesResponse.notFound);
    }
    log("Cannot get timetable $course: Bad status code ${response.statusCode}", name: "parsing.timetable");
    return const Tuple2(null, GetTileTablesResponse.badStatus);
  }
  final dom.Document document = getParsedDocumentFromResponse(response);
  if (document.outerHtml.contains("Fatal error")) {
    log("Cannot get timetable $course: Fatal error", name: "parsing.timetable");
    return const Tuple2(null, GetTileTablesResponse.fatalError);
  }

  // Find all elements with attr rules
  final tables = <dom.Element>[];
  final elements =
      document.getElementsByTagName("body")[0].children[0].children;
  for (var i = 0; i < elements.length; i++) {
    if (elements[i].attributes.containsKey("rules")) {
      tables.add(elements[i]);
    }
  }
  // Check if tables exists if not don't parse the table
  if (tables.length > 1) {
    return Tuple2(tables, GetTileTablesResponse.ok);
  }
  return const Tuple2(null, GetTileTablesResponse.noTable);
}


dom.Document getParsedDocumentFromResponse(Response response) {
  // Init the parser
  final document = parse(response.body, encoding: "UTF-8");
  return document;
}

/// This class is used internally by parseFootnoteTable to parse the footnotes
class Area {
  late int columnStart;
  late int columnEnd;
  late int rowStart;
  late int rowEnd;

  @override
  String toString() {
    return "{Area columnStart:$columnStart,columnEnd:$columnEnd, rowStart:$rowStart, rowEnd:$rowEnd}";
  }
}

/// Creates a map that maps Footnotes indexes example : [1), 2)] to a Footnote object based on parsing the html footnote table.
HashMap<String, List<Footnote>> parseFootnoteTable(dom.Element footnoteTable) {
  final rows = footnoteTable.children[0].children;

  final headerColumnsText = <String>[];
  final headerColumnStringIndexMap = HashMap<String, List<int>>();
  final columnData = HashMap<int, List<String>>();

  // Find column header text
  final headerColumns = rows[0].children;
  for (var i = 0; i < headerColumns.length; i++) {
    final headerColumn = headerColumns[i];
    headerColumnsText.add(customStrip(headerColumn.text));
    columnData[i] = <String>[];
  }

  // Map column text to column indexes
  for (var i = 0; i < headerColumnsText.length; i++) {
    final headerColumnText = headerColumnsText[i];
    if (headerColumnStringIndexMap.containsKey(headerColumnText)) {
      headerColumnStringIndexMap[headerColumnText]!.add(i);
    } else {
      headerColumnStringIndexMap[headerColumnText] = [i];
    }
  }
  rows.removeAt(0); // remove header from rows

  // Convert format to columns first instead of rows
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    final columns = row.children;
    for (var i = 0; i < columns.length; i++) {
      columnData[i]!.add(customStrip(columns[i].text).replaceAll("\n", ""));
    }
  }

  // Find footnote areas
  final footnoteAreaMap = <String, Area>{};

  // Loop over all columns with the header Nr.
  final nrList = headerColumnStringIndexMap["Nr."]!;
  for (var i = 0; i < nrList.length; i++) {
    final columnIndex = nrList[i];
    final column = columnData[columnIndex]!;
    var currentFootnoteIndex = column[0];

    // Get the columnStart and End
    final columnStart = columnIndex;
    int columnEnd;
    if (i >= nrList.length - 1) {
      columnEnd = columnData.length - 1;
    } else {
      columnEnd = nrList[i + 1] - 1;
    }

    // Setup first area
    var currentArea = Area();
    currentArea.rowStart = 0;
    currentArea.columnStart = columnStart;
    currentArea.columnEnd = columnEnd;
    var lastJ = 0;

    // Loop over one column with the header Nr.
    for (var j = 0; j < column.length; j++) {
      final currentValue = column[j];
      lastJ = j;

      if (currentValue == " " || currentValue == currentFootnoteIndex) {
        // No start of a new area
        continue;
      } else {
        // Start of new area
        // Add old area to map
        currentArea.rowEnd = j - 1;
        footnoteAreaMap[currentFootnoteIndex] = currentArea;

        // Init new area
        currentFootnoteIndex = column[j];
        currentArea = Area();
        currentArea.rowStart = j;
        currentArea.columnStart = columnStart;
        currentArea.columnEnd = columnEnd;
      }
    }
    // Add last area to map
    currentArea.rowEnd = lastJ;
    footnoteAreaMap[currentFootnoteIndex] = currentArea;
  }

  // Parse footnote areas
  var lastFootnoteKey = "1)";
  final footnotesMap = HashMap<String, List<Footnote>>();
  for (final footnoteKey in footnoteAreaMap.keys) {
    final area = footnoteAreaMap[footnoteKey]!;
    final relevantColumns = <List<String>>[];

    // Get relevant columns within area
    final columnTextList = <String>[];
    for (var i = area.columnStart; i < area.columnEnd + 1; i++) {
      final relevantColumn = <String>[];
      columnTextList.add(headerColumnsText[i]);
      for (var j = area.rowStart; j < area.rowEnd + 1; j++) {
        relevantColumn.add(columnData[i]![j]);
      }
      relevantColumns.add(relevantColumn);
    }

    // Init footnotes
    final footnotes = <Footnote>[];
    for (var i = 0; i < area.rowEnd - area.rowStart + 1; i++) {
      footnotes.add(Footnote());
    }

    // Loop over all columns
    for (var columnIndex = 0;
        columnIndex < relevantColumns.length;
        columnIndex++) {
      // Loop over all rows
      for (var rowIndex = 0;
          rowIndex < relevantColumns[columnIndex].length;
          rowIndex++) {
        final value = relevantColumns[columnIndex][rowIndex];

        // Switch on current column header and set footnotes
        switch (columnTextList[columnIndex]) {
          case "Le.,Fa.,Rm.":
            final splitValue = value.split(",");
            if (splitValue.length >= 2) {
              footnotes[rowIndex].teacher = splitValue[0];
              footnotes[rowIndex].subject = splitValue[1];
            }
            // Room value may not exist on some footnotes
            if (splitValue.length >= 3) {
              footnotes[rowIndex].room = splitValue[2];
            }
            break;
          case "Kla.":
            footnotes[rowIndex].schoolClasses = customStrip(value).split(",");
            break;
          case "Schulwoche":
            footnotes[rowIndex].schoolWeek = customStrip(value);
            break;
          case "Text":
            footnotes[rowIndex].text = customStrip(value);
            break;
          case "ZeilenText-2":
            final footnote = footnotes[rowIndex];
            footnote.text += "${footnote.text.isEmpty ? " " : ""}${customStrip(value)}";
            break;
          default:
            break;
        }
      }
    }

    // Append footnote to last footnote if the current footnote key is " "
    if (footnoteKey == " ") {
      footnotesMap[lastFootnoteKey]!.addAll(footnotes);
    } else {
      footnotesMap[footnoteKey] = footnotes;
      lastFootnoteKey = footnoteKey;
    }
  }
  return footnotesMap;
}

void parseMainTimeTable(
    Content content,
    List<String> subjects,
    dom.Element mainTimeTable,
    HashMap<String, List<Footnote>> footnoteMap,
    String course)
{
  final rows = mainTimeTable.children[0].children; // Gets all <tr> elements of the main table
  rows.removeAt(0); // Removes header

  // Loop over all rows
  for (var y = 0; y < rows.length; y++) {
    final row = rows[y];
    final columns = row.children; // Gets the columns within that row
    var tableX = 0; // The next valid index of the next column within the html grid
    // Ignore this row if its empty
    if (columns.isEmpty) {
      continue;
    }
    // Loop over all days
    for (var x = 0; x <= 5; x++) {
      // If in first column (sidebar)
      if (x == 0) {
        parseOneCell(columns[x], x, y, content, subjects, footnoteMap, course);
        tableX++;
      } else {
        var doParseCell = true; // If this is false that cell will not be parsed
        if (y != 0) {
          final contentY = (y / 2).floor(); // Get the y pos in the content timetable from the html y pos
          if (contentY >= content.cells.length) {
            // If content to small break
            break;
          }
          // Check if a class is already at this position (Only happens if a double class is above the current class)
          final isDoubleClass = content.cells[contentY][x].isDoubleClass;
          if (isDoubleClass) {
            doParseCell = false; // Don't parse this cell since it dose not exist in the html
          }
        }
        if (doParseCell) {
          parseOneCell(columns[tableX], x, y, content, subjects, footnoteMap, course);
          tableX++;
        }
      }
    }
  }
}

/// Gets all theoretically available subjects, only supposed to be used for autocompletion
Future<List<String>> getAllAvailableSubjects(Client client, String fullSchoolGradeName, String schoolGrade) async {
  final tablesMain = (await getTimeTableTables(fullSchoolGradeName, Constants.timeTableLinkBase, client)).item1;
  if (tablesMain == null) return [];
  final options = (getAvailableSubjectNames(tablesMain)).toList();
  if (!Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
    final tablesCourse = (await getTimeTableTables("${schoolGrade}K", Constants.timeTableLinkBase, client)).item1;
    if (tablesCourse != null) options.addAll(getAvailableSubjectNames(tablesCourse));
  }
  if (Constants.useAGs) {
    final tablesAgs = (await getTimeTableTables(Constants.specialClassNameAG, Constants.timeTableLinkBase, client)).item1;
    if (tablesAgs != null) options.addAll(getAvailableSubjectNames(tablesAgs));
  }
  return options;
}

HashSet<String> getAvailableSubjectNamesInTimetable(dom.Element mainTimeTable) {
  final rows = mainTimeTable.children[0].children; // Gets all <tr> elements of the main table
  rows.removeAt(0); // Removes header
  final HashSet<String> availableSubjects = HashSet();
  // Loop over all rows
  for (var y = 0; y < rows.length; y++) {
    final row = rows[y];
    final columns = row.children; // Gets the columns within that row
    // Ignore this row if its empty
    if (columns.isEmpty) {
      continue;
    }
    for (final cellDom in columns) {
      final subjectName = getSubjectName(cellDom);
      if (subjectName != null) {
        availableSubjects.add(subjectName);
      }
    }
  }
  return availableSubjects;
}


HashSet<String> getAvailableSubjectNames(List<dom.Element>? tables) {
  final HashSet<String> availableSubjects = HashSet();

  if (tables != null) {
    final mainTimeTable = tables[0];
    final footnoteTable = tables[1];
    // Add subjects from timetable
    for (final subject in getAvailableSubjectNamesInTimetable(mainTimeTable)) {
      availableSubjects.add(subject);
    }
    final footnoteMap = parseFootnoteTable(footnoteTable); // Parse the footnote table
    // Add subject in footnotes
    for (final footnotes in footnoteMap.values) {
      for (final footnote in footnotes) {
        availableSubjects.add(footnote.subject);
      }
    }
  }
  availableSubjects.remove("---");
  return availableSubjects;
}


String? getSubjectName(dom.Element cellDom) {
  final cellData = cellDom.children[0].children[0].children;
  if (cellData.length >= 2) {
    final subjectAndFootnote = cellData[1].children;
    return customStrip(subjectAndFootnote[0].text);
  }
  return null;
}

void parseOneCell(
    dom.Element cellDom,
    int x,
    int y,
    Content content,
    List<String> subjects,
    HashMap<String, List<Footnote>> footnoteMap,
    String course)
{
  var cell = Cell();

  // Ignore the sidebar
  if (x == 0) {
    return;
  }

  // Parse normal cell
  final hours = int.parse(cellDom.attributes["rowspan"]!) / 2;
  cell.isDoubleClass = hours == 2;
  final cellData = cellDom.children[0].children[0].children;
  if (cellData.length >= 2) {
    // Store data from the html element into the cell
    final teacherAndRoom = cellData[0].children;
    final subjectAndFootnote = cellData[1].children;
    cell.teacher = customStrip(teacherAndRoom[0].text);
    // Check if room data exists and set it if it does
    if (teacherAndRoom.length > 1) cell.room = customStrip(teacherAndRoom[1].text);
    cell.subject = customStrip(subjectAndFootnote[0].text);
    // Check if footnote exists
    if (subjectAndFootnote.length > 1) {
      // Get footnotes from footnoteMap
      final footnoteKey = customStrip(subjectAndFootnote[1].text);
      final footnotes = footnoteMap[footnoteKey]!;

      // Filter out footnotes that don't matter to the user
      final requiredFootnotes = <Footnote>[];
      for (final footnote in footnotes) {
        if (subjects.contains(footnote.subject) && footnote.schoolClasses.contains(course)) {
          requiredFootnotes.add(footnote);
        }
      }

      // If only one required footnote, or the current subject is not required.
      // Set the subject room and teacher to the first element in the requiredFootnotes list.
      if (requiredFootnotes.length == 1 ||
          (!subjects.contains(cell.subject) && requiredFootnotes.isNotEmpty)) {
        cell.subject = requiredFootnotes[0].subject;
        cell.room = requiredFootnotes[0].room;
        cell.teacher = requiredFootnotes[0].teacher;
      }

      cell.footnotes = requiredFootnotes; // Set footnotes of cell
    }
  }

  if (subjects.contains(cell.subject)) {
    for (var i = 0; i < hours; i++) {
      content.setCell((y / 2).floor() + i, x, cell);
    }
  } else {
    // If user dose not have that subject skip that class
    for (var i = 0; i < hours; i++) {
      // Update class at current position and set it to be a double class
      cell = content.cells[(y / 2).floor() + i][x];
      cell.isDoubleClass = true;
      content.setCell((y / 2).floor() + i, x, cell);
    }
  }
}