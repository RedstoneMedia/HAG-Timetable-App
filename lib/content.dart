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
  String schoolClass;
  String schoolWeek;
  String text;

  @override
  String toString() {
    return "{Footnote teacher:${teacher}, subject:${subject}, room:${room}}";
  }
}

class Cell {
  //TODO: Replace default values
  String subject = "---";
  String originalSubject = "---";
  String room = "---";
  String originalRoom = "---";
  String teacher = "---";
  String originalTeacher = "---";
  String text = "---";
  String footNoteTextId = "";
  List<Footnote> footnotes;
  bool isDropped = false;
  bool isDoubleClass = false;

  String toString() {
    return "{Cell isDropped : ${isDropped}, subject : ${subject}, room : ${room}}";
  }

  bool isEmpty() {
    return subject == "---" && room == "---" && teacher == "---" && isDropped == false;
  }
}
