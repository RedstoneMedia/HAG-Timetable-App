import 'dart:io';

class Content {
  Content(int width, int height) {
    for (int y = 0; y < height; y++) {
      List<Cell> row = new List<Cell>();
      for (int x = 0; x < width; x++) {
        row.add(new Cell());
      }
      cells.add(row);
    }
  }

  List<List<Map<String, dynamic>>> toJsonData() {
    List<List<Map<String, dynamic>>> jsonData = new List<List<Map<String, dynamic>>>();
    for (int y = 0; y < cells.length; y++) {
      List<Map<String, dynamic>> row = new List<Map<String, dynamic>>();
      for (int x = 0; x < cells[0].length; x++) {
        row.add(cells[y][x].toJsonData());
      }
      jsonData.add(row);
    }
    return jsonData;
  }

  static Content fromJsonData(List<dynamic> jsonData) {
    Content newContent = new Content(jsonData.length, jsonData[0].length);
    for (int y = 0; y < jsonData.length; y++) {
      for (int x = 0; x < jsonData[0].length; x++) {
        newContent.cells[y][x] = Cell.fromJsonData(jsonData[y][x]);
      }
    }
    return newContent;
  }

  List<List<Cell>> cells = List<List<Cell>>();
  void setCell(int y, int x, Cell value) {
    print("Seting cell at y:${y}, x:${x} to ${value}");
    cells[y][x] = value;
  }

  String toString() {
    return cells.toString();
  }

  void combine(Content other) {
    for (int y = 0; y < cells.length; y++) {
      for (int x = 0; x < cells[y].length; x++) {
        var myCell = cells[y][x];
        var otherCell = other.cells[y][x];
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
      "teacher": this.teacher,
      "subject": this.subject,
      "room": this.room,
      "schoolClasses": this.schoolClasses,
      "schoolWeek": this.schoolWeek,
      "text": this.text,
    };
  }

  @override
  String toString() {
    return "{Footnote teacher:${teacher}, subject:${subject}, room:${room}}";
  }
}

class Cell {
  Cell(
      {subject,
      originalSubject,
      room,
      originalRoom,
      teacher,
      originalTeacher,
      text,
      footNoteTextId,
      footnotes,
      isSubstitute,
      isDropped,
      isDoubleClass});

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

  String toString() {
    return "{Cell isDropped : ${isDropped}, subject : ${subject}, room : ${room}  original subject : ${originalSubject}}";
  }

  bool isEmpty() {
    return subject == "---" &&
        room == "---" &&
        teacher == "---" &&
        isDropped == false &&
        isSubstitute == false;
  }

  factory Cell.fromJsonData(Map<String, dynamic> parsedJson) {
    return new Cell(
      subject: parsedJson["subject"] ?? "---",
      originalSubject: parsedJson["originalSubject"] ?? "---",
      room: parsedJson["room"] ?? "---",
      originalRoom: parsedJson["originalRoom"] ?? "---",
      teacher: parsedJson["teacher"] ?? "---",
      originalTeacher: parsedJson["originalTeacher"] ?? "---",
      text: parsedJson["text"] ?? "---",
      footNoteTextId: parsedJson["footNoteTextId"] ?? "",
      footnotes: parsedJson["footnotes"] ?? [],
      isSubstitute: parsedJson["isSubstitute"] ?? false,
      isDropped: parsedJson["isDropped"] ?? false,
      isDoubleClass: parsedJson["isDoubleClass"] ?? false,
    );
  }

  Map<String, dynamic> toJsonData() {
    List<Map<String, dynamic>> footnotesMap = [{}];
    if (this.footnotes != null) {
      this.footnotes.forEach((footnote) {
        footnotesMap.add(footnote.toJsonData());
      });
    }

    return {
      "subject": this.subject,
      "originalSubject": this.originalSubject,
      "room": this.room,
      "originalRoom": this.originalRoom,
      "teacher": this.teacher,
      "originalTeacher": this.originalTeacher,
      "text": this.text,
      "footNoteTextId": this.footNoteTextId,
      "footnotes": footnotesMap,
      "isSubstitute": this.isSubstitute,
      "isDropped": this.isDropped,
      "isDoubleClass": this.isDoubleClass,
    };
  }
}
