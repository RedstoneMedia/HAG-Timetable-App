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
  bool isDropped = false;
  bool isDoubleClass = false;

  String toString() {
    return "{Cell isDropped : ${isDropped}, subject : ${subject}, room : ${room}}";
  }
}
