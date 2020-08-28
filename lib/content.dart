import 'package:flutter/material.dart';

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
}

class Cell {
  String subject = "Hallo";
  String room;
  String teacher;
}
