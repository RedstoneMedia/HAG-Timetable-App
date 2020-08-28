
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
  void setCell(int x, int y, Cell value) {
   // print("Setting sell at $x $y to $value");
    cells[x][y] = value;
  }
}

class Cell {
  String subject = "";
  String room;
  String teacher;

  String toString() {
    return subject;
  }
}
