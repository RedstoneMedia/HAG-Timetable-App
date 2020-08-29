import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';

class WeekdayGridObject extends StatelessWidget {
  WeekdayGridObject(this.weekday, this.day, this.needsLeftBorder,
      this.needsRightBorder, this.constants);

  final String weekday;
  final String day;
  final bool needsLeftBorder;
  final bool needsRightBorder;
  final Constants constants;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(needsLeftBorder ? 5 : 0),
              topRight: Radius.circular(needsRightBorder ? 5 : 0),
            ),
            border: Border.all(width: 0.75, color: Colors.black26),
            color: compareWeekdays(day, weekday)
                ? constants.textColor
                : constants.textColor.withAlpha(25)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Text(
            weekday,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: compareWeekdays(day, weekday)
                    ? constants.invertedTextColor
                    : constants.textColor),
          )),
        ),
      ),
    );
  }
}

bool compareWeekdays(String day, String otherDay) {
  day = day.toLowerCase();
  otherDay = otherDay.toLowerCase();
  if ((day == "monday" && otherDay == "mo") ||
      (day == "tuesday" && otherDay == "di") ||
      (day == "wednesday" && otherDay == "mi") ||
      (day == "thursday" && otherDay == "do") ||
      (day == "friday" && otherDay == "fr")) return true;
  return false;
}

class ClassGridObject extends StatelessWidget {
  ClassGridObject(
      this.content, this.constants, this.x, this.y, this.needsLeftBorder);

  final Content content;
  final Constants constants;
  final int x;
  final int y;
  final bool needsLeftBorder;

  @override
  Widget build(BuildContext context) {
    return (content.cells[y][x].subject == "---" &&
            content.cells[y][x].originalSubject == "---")
        ? Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: constants.textColor.withAlpha(10),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(
                  (y == constants.height - 2 && x == 1) ? 5 : 0),
              bottomRight: Radius.circular(
                  (y == constants.height - 2 && x == constants.width - 1)
                      ? 5
                      : 0),
            ),
            border: Border.all(width: 0.5, color: Colors.black26),
          ),
          child: Column(
            children: [
              Text(
                content.cells[y][x].originalSubject,
                style: TextStyle(
                    color: Colors.transparent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0),
              ),
              Text(
                content.cells[y][x].subject,
                style: TextStyle(
                  color: Colors.transparent,
                ),
              ),
              Text(content.cells[y][x].room,
                  style: TextStyle(
                    color: Colors.transparent,
                  )),
              Text(content.cells[y][x].teacher,
                  style: TextStyle(
                    color: Colors.transparent,
                  )),
            ],
          ),
        ))
        : Expanded(
      child: Container(
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 1.0,
                    color: (y - 1) % 2 == 0
                        ? Colors.black54
                        : Colors.black26),
                right: BorderSide(width: 0.5, color: Colors.black26),
                left: BorderSide(width: 0.5, color: Colors.black26)),
            color: !content.cells[y][x].isDropped
                ? constants.subjectColor
                : constants.subjectAusfallColor),
        child: Column(
          children: content.cells[y][x].isDropped
              ? [
            Text(
              content.cells[y][x].originalSubject,
              style: TextStyle(
                  color: constants.textColor.withAlpha(214),
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0),
            ),
            Text(
              content.cells[y][x].subject,
              style: TextStyle(color: constants.textColor),
            ),
            Text(
              content.cells[y][x].room,
              style: TextStyle(color: constants.textColor),
            ),
            Text(
              content.cells[y][x].teacher,
              style: TextStyle(color: constants.textColor),
            ),
          ]
              : [
            Text(
              content.cells[y][x].originalSubject,
              style: TextStyle(
                color: Colors.transparent,
                fontWeight: FontWeight.bold,
                fontSize: 8.5,
              ),
            ),
            Text(
              content.cells[y][x].subject,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: constants.textColor),
            ),
            Text(
              content.cells[y][x].room,
              style: TextStyle(color: constants.textColor),
            ),
            Text(
              content.cells[y][x].teacher,
              style: TextStyle(color: constants.textColor),
            ),
            Text(
              content.cells[y][x].originalSubject,
              style: TextStyle(
                color: Colors.transparent,
                fontWeight: FontWeight.bold,
                fontSize: 8.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderGridObject extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
          child: Text(
        "12:30",
        style: GoogleFonts.poppins(color: Colors.transparent),
      )),
    );
  }
}

class TimeGridObject extends StatelessWidget {
  TimeGridObject(this.timeStart, this.timeEnd, this.y, this.constants);

  final String timeStart;
  final String timeEnd;
  final int y;
  final Constants constants;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: constants.textColor.withAlpha(214),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "12:30",
              style: GoogleFonts.poppins(color: constants.textColor),
            ),
            Text(
              "$y.",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: constants.textColor),
            ),
            Text(
              "12:43",
              style: GoogleFonts.poppins(color: constants.textColor),
            ),
          ],
        ),
      ),
    );
  }
}
