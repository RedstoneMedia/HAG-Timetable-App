import 'dart:developer';

class Content {
  Content(int width, int height) {
    for (var y = 0; y < height; y++) {
      final row = <Cell>[];
      for (var x = 0; x < width; x++) {
        row.add(Cell());
      }
      cells.add(row);
    }
  }

  DateTime lastUpdated;

  void updateLastUpdated() {
    lastUpdated = DateTime.now();
    log("UPDATED LASTUPDATED", name: "cache");
  }

  List<List<Map<String, dynamic>>> toJsonData() {
    final jsonData = <List<Map<String, dynamic>>>[];
    for (var y = 0; y < cells.length; y++) {
      final row = <Map<String, dynamic>>[];
      for (var x = 0; x < cells[0].length; x++) {
        row.add(cells[y][x].toJsonData());
      }
      jsonData.add(row);
    }
    jsonData.add([
      {"lastUpdated": lastUpdated.toIso8601String()}
    ]);
    return jsonData;
  }

  // ignore: prefer_constructors_over_static_methods
  static Content fromJsonData(List<dynamic> jsonData) {
    final newContent = Content(jsonData[0].length as int, jsonData.length);
    for (var y = 0; y < jsonData.length - 1; y++) {
      for (var x = 0; x < (jsonData[0].length as int); x++) {
        final cell = Cell.fromJsonData(jsonData[y][x] as Map<String, dynamic>);
        newContent.setCell(y, x, cell);
      }
    }
    newContent.lastUpdated = DateTime.parse(
        jsonData[jsonData.length - 1][0]["lastUpdated"].toString());
    return newContent;
  }

  final cells = <List<Cell>>[];
  void setCell(int y, int x, Cell value) {
    log("Setting cell at y:$y, x:$x to $value", name: "content");
    cells[y][x] = value;
  }

  @override
  String toString() {
    return cells.toString();
  }

  void combine(Content other) {
    for (var y = 0; y < cells.length; y++) {
      for (var x = 0; x < cells[y].length; x++) {
        final myCell = cells[y][x];
        final otherCell = other.cells[y][x];
        // If current cell is empty set cell to other
        if (myCell.isEmpty()) {
          setCell(y, x, otherCell);
        }
        // If other cell is not empty set cell to current
        if (!otherCell.isEmpty()) {
          setCell(y, x, otherCell);
        }
      }
    }
  }
}

class Footnote {
  String teacher;
  String subject;
  String room;
  List<String> schoolClasses;
  String schoolWeek;
  String text;

  Map<String, dynamic> toJsonData() {
    return {
      "teacher": teacher,
      "subject": subject,
      "room": room,
      "schoolClasses": schoolClasses,
      "schoolWeek": schoolWeek,
      "text": text,
    };
  }

  // ignore: prefer_constructors_over_static_methods
  static Footnote fromJsonData(Map<String, dynamic> jsonData) {
    final newFootnote = Footnote();
    newFootnote.teacher = jsonData["teacher"].toString() ?? "";
    newFootnote.subject = jsonData["subject"].toString() ?? "";
    newFootnote.room = jsonData["room"].toString() ?? "";
    newFootnote.schoolClasses = [];
    for (final schoolClass in jsonData["schoolClasses"] ?? <String>[]) {
      newFootnote.schoolClasses.add(schoolClass.toString());
    }
    newFootnote.schoolWeek = jsonData["schoolWeek"].toString() ?? " ";
    newFootnote.text = jsonData["text"].toString() ?? " ";
    return newFootnote;
  }

  @override
  String toString() {
    return "{Footnote teacher:$teacher, subject:$subject, room:$room, text: '$text'}";
  }
}

class Cell {
  Cell();

  String subject = "---";
  String originalSubject = "---";
  String room = "---";
  String originalRoom = "---";
  String teacher = "---";
  String originalTeacher = "---";
  String text = "---";
  String footNoteTextId = "";
  List<Footnote> footnotes;
  bool isSubstitute = false;
  bool isDropped = false;
  bool isDoubleClass = false;

  @override
  String toString() {
    return "{Cell isDropped : $isDropped, subject : $subject, room : $room  original subject : $originalSubject}";
  }

  bool isEmpty() {
    return subject == "---" &&
        room == "---" &&
        teacher == "---" &&
        isDropped == false &&
        isSubstitute == false;
  }

  factory Cell.fromJsonData(Map<String, dynamic> parsedJson) {
    final newCell = Cell();
    newCell.subject = parsedJson["subject"].toString() ?? "---";
    newCell.originalSubject = parsedJson["originalSubject"].toString() ?? "---";
    newCell.room = parsedJson["room"].toString() ?? "---";
    newCell.originalRoom = parsedJson["originalRoom"].toString() ?? "---";
    newCell.teacher = parsedJson["teacher"].toString() ?? "---";
    newCell.originalTeacher = parsedJson["originalTeacher"].toString() ?? "---";
    newCell.text = parsedJson["text"].toString() ?? "---";
    newCell.footNoteTextId = parsedJson["footNoteTextId"].toString() ?? "";
    final footnotes = parsedJson["footnotes"];
    if (footnotes != null) {
      newCell.footnotes = [];
      for (final footnoteJsonData in footnotes) {
        newCell.footnotes.add(
            Footnote.fromJsonData(footnoteJsonData as Map<String, dynamic>));
      }
    }

    newCell.isSubstitute = parsedJson["isSubstitute"] as bool ?? false;
    newCell.isDropped = parsedJson["isDropped"] as bool ?? false;
    return newCell;
  }

  Map<String, dynamic> toJsonData() {
    List<dynamic> footnotesJsonDataList;
    if (footnotes != null) {
      footnotesJsonDataList = <dynamic>[];
      for (final footnote in footnotes) {
        if (footnote != null) {
          footnotesJsonDataList.add(footnote.toJsonData());
        }
      }
    }

    return {
      "subject": subject,
      "originalSubject": originalSubject,
      "room": room,
      "originalRoom": originalRoom,
      "teacher": teacher,
      "originalTeacher": originalTeacher,
      "text": text,
      "footNoteTextId": footNoteTextId,
      "footnotes": footnotesJsonDataList,
      "isSubstitute": isSubstitute,
      "isDropped": isDropped
    };
  }
}
