import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';

class WeekdayGridObject extends StatelessWidget {
  WeekdayGridObject(this.weekday, this.day);

  final String weekday;
  final String day;

  @override
  Widget build(BuildContext context) {
    //print("$day - $weekday = ${compareWeekdays(day, weekday)}");
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(width: 1.0, color: Colors.black),
            color: compareWeekdays(day, weekday) ? Colors.black : Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Text(
            weekday,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: compareWeekdays(day, weekday)
                    ? Colors.white
                    : Colors.black),
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
  ClassGridObject(this.content, this.constants, this.x, this.y);

  final Content content;
  final Constants constants;
  final int x;
  final int y;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(width: 1.0, color: Colors.black),
            color: !content.cells[y][x].isDropped
                ? constants.subjectColor
                : constants.subjectAusfallColor),
        child: Column(
          children: [
            Text(
              content.cells[y][x].originalSubject,
              style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0),
            ),
            Text(content.cells[y][x].subject),
            Text(content.cells[y][x].room),
            Text(content.cells[y][x].teacher),
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
  TimeGridObject(this.timeStart, this.timeEnd, this.y);

  final String timeStart;
  final String timeEnd;
  final int y;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black54))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "12:30",
              style: GoogleFonts.poppins(),
            ),
            Text(
              "$y.",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            Text(
              "12:43",
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
      ),
    );
  }
}