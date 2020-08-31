import 'dart:collection';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:http/http.dart'; // Contains a client for making API calls

import 'package:stundenplan/parsing/parsing_util.dart'; // Contains parsing utils
import 'package:stundenplan/content.dart';

/// This will fill the input content with a timetable based on the other arguments
Future<void> fillTimeTable(String course, String linkBase, client, Content content, List<String> subjects) async {
  // Get the html file
  Response response = await client.get('${linkBase}_${course}.htm');
  if (response.statusCode != 200) {
    print("Cannot get timetable");
    return;
  }

  // Init the parser
  var document = parse(response.body);

  // Find all elements with attr rules
  List<dom.Element> tables = new List<dom.Element>();
  List<dom.Element> elements = document.getElementsByTagName("body")[0].children[0].children;
  for (int i = 0; i < elements.length; i++) {
    if (elements[i].attributes.containsKey("rules")) {
      tables.add(elements[i]);
    }
  }
  // Check if tables exists if not don't parse the table
  if (tables.length > 1) {
    var mainTimeTable = tables[0];
    var footnoteTable = tables[1];
    var footnoteMap = parseFootnoteTable(footnoteTable);  // Parse the footnote table
    parseMainTimeTable(content, subjects, mainTimeTable, footnoteMap, course); // Parse the main timetable
  }
}

/// This class is used internally by parseFootnoteTable to parse the footnotes
class Area {
  int columnStart;
  int columnEnd;
  int rowStart;
  int rowEnd;

  @override
  String toString() {
    return "{Area columnStart:${columnStart},columnEnd:${columnEnd}, rowStart:${rowStart}, rowEnd:${rowEnd}}";
  }
}

/// Creates a map that maps Footnotes indexes example : [1), 2)] to a Footnote object based on parsing the html footnote table.
HashMap<String,List<Footnote>> parseFootnoteTable(dom.Element footnoteTable) {
  List<dom.Element> rows = footnoteTable.children[0].children;

  List<String> headerColumnsText = new List<String>();
  HashMap<String, List<int>> headerColumnStringIndexMap = new HashMap<String, List<int>>();
  HashMap<int, List<String>> columnData = new HashMap<int, List<String>>();

  // Find column header text
  var headerColumns = rows[0].children;
  for (var i = 0; i < headerColumns.length; i++) {
    var headerColumn = headerColumns[i];
    headerColumnsText.add(strip(headerColumn.text));
    columnData[i] = new List<String>();
  }

  // Map column text to column indexes
  for (var i = 0; i < headerColumnsText.length; i++) {
    var headerColumnText = headerColumnsText[i];
    if (headerColumnStringIndexMap.containsKey(headerColumnText)) {
      headerColumnStringIndexMap[headerColumnText].add(i);
    } else {
      headerColumnStringIndexMap[headerColumnText] = [i];
    }
  }
  rows.removeAt(0);  // remove header from rows

  // Convert format to columns first instead of rows
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    var row = rows[rowIndex];
    var columns = row.children;
    for (var i = 0; i < columns.length; i++) {
      columnData[i].add(strip(columns[i].text).replaceAll("\n", ""));
    }
  }

  // Find footnote areas
  LinkedHashMap<String, Area> footnoteAreaMap = new LinkedHashMap<String, Area>();

  // Loop over all columns with the header Nr.
  var nrList = headerColumnStringIndexMap["Nr."];
  for (var i = 0; i < nrList.length; i++) {
    var columnIndex = nrList[i];
    var column = columnData[columnIndex];
    var currentFootnoteIndex = column[0];

    // Get the columnStart and End
    var columnStart = columnIndex;
    int columnEnd;
    if (i >= nrList.length-1) {
      columnEnd = columnData.length-1;
    } else {
      columnEnd = nrList[i+1]-1;
    }

    // Setup first area
    var currentArea = new Area();
    currentArea.rowStart = 0;
    currentArea.columnStart = columnStart;
    currentArea.columnEnd = columnEnd;
    var lastJ = 0;

    // Loop over one column with the header Nr.
    for (var j = 0; j < column.length; j++) {
      var currentValue = column[j];
      lastJ = j;

      if (currentValue == " " || currentValue == currentFootnoteIndex) {  // No start of a new area
        continue;
      } else {  // Start of new area
        // Add old area to map
        currentArea.rowEnd = j-1;
        footnoteAreaMap[currentFootnoteIndex] = currentArea;

        // Init new area
        currentFootnoteIndex = column[j];
        currentArea = new Area();
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
  HashMap<String,List<Footnote>> footnotesMap = new HashMap<String,List<Footnote>>();
  for (var footnoteKey in footnoteAreaMap.keys) {
    var area = footnoteAreaMap[footnoteKey];
    var relevantColumns = new List<List<String>>();

    // Get relevant columns within area
    var columnTextList = new List<String>();
    for (var i = area.columnStart; i < area.columnEnd + 1; i++) {
      var relevantColumn = new List<String>();
      columnTextList.add(headerColumnsText[i]);
      for (var j = area.rowStart; j < area.rowEnd + 1; j++) {
        relevantColumn.add(columnData[i][j]);
      }
      relevantColumns.add(relevantColumn);
    }

    // Init footnotes
    var footnotes = new List<Footnote>();
    for (var i = 0; i < area.rowEnd-area.rowStart + 1; i++) {
      footnotes.add(new Footnote());
    }

    // Loop over all columns
    for (var columnIndex = 0; columnIndex < relevantColumns.length; columnIndex++) {
      // Loop over all rows
      for (var rowIndex = 0; rowIndex < relevantColumns[columnIndex].length; rowIndex++) {
        var value = relevantColumns[columnIndex][rowIndex];

        // Switch on current column header and set footnotes
        switch (columnTextList[columnIndex]) {
          case "Le.,Fa.,Rm.":
            var splitValue = value.split(",");
            if (splitValue.length >= 3) {
              footnotes[rowIndex].teacher = splitValue[0];
              footnotes[rowIndex].subject = splitValue[1];
              footnotes[rowIndex].room = splitValue[2];
            }
            break;
          case "Kla.":
            footnotes[rowIndex].schoolClasses = strip(value).split(",");
            break;
          case "Schulwoche":
            footnotes[rowIndex].schoolWeek = strip(value);
            break;
          case "Text":
            footnotes[rowIndex].text = value;
            break;
          default:
            break;
        }
      }
    }

    // Append footnote to last footnote if the current footnote key is " "
    if (footnoteKey == " ") {
      footnotesMap[lastFootnoteKey].addAll(footnotes);
    } else {
      footnotesMap[footnoteKey] = footnotes;
      lastFootnoteKey = footnoteKey;
    }
  }
  return footnotesMap;
}


void parseMainTimeTable(Content content, List<String> subjects, dom.Element mainTimeTable, HashMap<String,List<Footnote>> footnoteMap, String course) {
  List<dom.Element> rows = mainTimeTable.children[0].children;  // Gets all <tr> elements of the main table
  rows.removeAt(0);  // Removes header

  // Loop over all rows
  for (var y = 0; y < rows.length; y++) {
    var row = rows[y];
    var columns = row.children;  // Gets the columns within that row
    var tableX = 0;  // The next valid index of the next column within the html grid
    // Ignore this row if its empty
    if (columns.length <= 0) {
      continue;
    }
    // Loop over all days
    for (var x = 0; x <= 5; x++) {
      // If in first column (sidebar)
      if (x == 0) {
        parseOneCell(columns[x], x, y, content, subjects, footnoteMap, course);
        tableX++;
      } else {
        var doParseCell = true;  // If this is false that cell will not be parsed
        if (y != 0) {
          var contentY = (y / 2).floor();  // Get the y pos in the content timetable from the html y pos
          if (contentY >= content.cells.length) {  // If content to small break
            break;
          }
          // Check if a class is already at this position (Only happens if a double class is above the current class)
          var isDoubleClass = content.cells[contentY][x].isDoubleClass;
          if (isDoubleClass) {
            doParseCell = false;  // Don't parse this cell since it dose not exist in the html
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

void parseOneCell(dom.Element cellDom, int x, int y, Content content, List<String> subjects, HashMap<String,List<Footnote>> footnoteMap, String course) {
  var cell = new Cell();

  // Ignore the sidebar
  if (x == 0) {
    return;
  }

  // Parse normal cell
  var hours = int.parse(cellDom.attributes["rowspan"]) / 2;
  cell.isDoubleClass = hours == 2;
  List<dom.Element> cellData = cellDom.children[0].children[0].children;
  if (cellData.length >= 2) {
    // Store data from the html element into the cell
    List<dom.Element> teacherAndRoom = cellData[0].children;
    List<dom.Element> subjectAndFootnote = cellData[1].children;
    cell.teacher = strip(teacherAndRoom[0].text);
    cell.room = strip(teacherAndRoom[1].text);
    cell.subject = strip(subjectAndFootnote[0].text);
    // Check if footnote exists
    if (subjectAndFootnote.length > 1) {
      // Get footnotes from footnoteMap
      var footnoteKey = strip(subjectAndFootnote[1].text);
      var footnotes = footnoteMap[footnoteKey];

      // Filter out footnotes that don't matter to the user
      var requiredFootnotes = new List<Footnote>();
      for (var footnote in footnotes) {
        if (subjects.contains(footnote.subject) && footnote.schoolClasses.contains(course)) {
          requiredFootnotes.add(footnote);
        }
      }

      // If only one required footnote, or the current subject is not required.
      // Set the subject room and teacher to the first element in the requiredFootnotes list.
      if (requiredFootnotes.length == 1 || (!subjects.contains(cell.subject) && requiredFootnotes.length > 0)) {
        cell.subject = requiredFootnotes[0].subject;
        cell.room = requiredFootnotes[0].room;
        cell.teacher = requiredFootnotes[0].teacher;
      }

      cell.footnotes = requiredFootnotes;  // Set footnotes of cell
    }
  }


  if (subjects.contains(cell.subject)) {
    for (var i = 0; i < hours; i++) {
      content.setCell((y / 2).floor() + i, x, cell);
    }
  } else {  // If user dose not have that subject skip that class
    for (var i = 0; i < hours; i++) {
      // Update class at current position and set it to be a double class
      cell = content.cells[(y / 2).floor() + i][x];
      cell.isDoubleClass = true;
      content.setCell((y / 2).floor() + i, x, cell);
    }
  }
}