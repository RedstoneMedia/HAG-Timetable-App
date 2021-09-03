import 'package:stundenplan/content.dart';
import 'package:test/test.dart';

void main() {
  group("Content", () {
    test("Setting/Getting Cell inside Content", () {
      final Content content = Content(10, 10);

      // Cell at 5, 5 should be a empty Cell
      expect(content.getCell(5, 5).toString(), Cell().toString());

      final Cell testCell = Cell();
      testCell.text = "test";
      content.setCell(5, 5, testCell);

      // Cell at 5, 5 should be the testCell
      expect(content.getCell(5, 5).toString(), testCell.toString());
    });

    test("Setting Cell outside Content (Y)", () {
      final Content content = Content(5, 5);

      final Cell testCell = Cell();
      testCell.text = "test";
      // Setting a Cell outside of the height causes the Content object to grow
      content.setCell(10, 0, testCell);

      // Cell at at 10, 0 should be the testCell
      expect(content.getCell(10, 0).toString(), testCell.toString());
    });

    test("Setting Cell outside Content (X)", () {
      final Content content = Content(5, 5);

      final Cell testCell = Cell();
      testCell.text = "test";

      // Setting a Cell outside of the width throws a RangeError
      expect(() => content.setCell(0, 10, testCell), throwsA(isA<RangeError>()));
    });
  });
}
