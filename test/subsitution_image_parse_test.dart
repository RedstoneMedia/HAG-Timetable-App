import 'package:stundenplan/content.dart';
import 'package:stundenplan/parsing/subsitution_image_parse.dart';
import 'package:test/test.dart';

void main() {
  test("Test correct substitution", () {
    final content = Content(5, 9);
    final cell = Cell();
    cell.room = "C0.07";
    cell.teacher = "Gh";
    cell.subject = "PO1";
    content.setCell(0, 0, cell);
    final substitution = {"Fach" : "p01", "statt Fach" : "p01", "Vertretung" : "Si", "statt Lehrer" : "Gh", "Raum" : "B2.O1", "statt Raum" : "CO.07"};
    correctSubstitution(substitution, content, "Q1");
    expect(substitution["Fach"], equals("PO1"));
    expect(substitution["statt Fach"], equals("PO1"));
    expect(substitution["Vertretung"], equals("Si"));
    expect(substitution["statt Lehrer"], equals("Gh"));
    expect(substitution["Raum"], equals("B2.O1"));
    expect(substitution["statt Raum"], equals("C0.07"));
    expect(substitution["Klassen"], equals("Q1"));
  });
}