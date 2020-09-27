import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/shared_state.dart';
import 'info_dialog.dart';

class WeekdayGridObject extends StatelessWidget {
  WeekdayGridObject(this.weekday, this.x, this.needsLeftBorder,
      this.needsRightBorder, this.sharedState);

  final String weekday;
  final int x;
  final int weekdayToday = DateTime.now().weekday;
  final bool needsLeftBorder;
  final bool needsRightBorder;
  final SharedState sharedState;

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
            color: x == weekdayToday
                ? sharedState.theme.textColor
                : sharedState.theme.textColor.withAlpha(25)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Text(
            weekday,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: x == weekdayToday
                    ? sharedState.theme.invertedTextColor
                    : sharedState.theme.textColor),
          )),
        ),
      ),
    );
  }
}

class ClassGridObject extends StatelessWidget {
  ClassGridObject(this.content, this.sharedState, this.x, this.y,
      this.needsLeftBorder, this.context);

  final Content content;
  final SharedState sharedState;
  final int x;
  final int y;
  final bool needsLeftBorder;
  final context;


  @override
  Widget build(BuildContext context) {
    return content.cells[y][x].isEmpty()
        ? Expanded(
            child: Container(
            decoration: BoxDecoration(
              color: sharedState.theme.textColor.withAlpha(10),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(
                    (y == sharedState.height - 2 && x == 1) ? 5 : 0),
                bottomRight: Radius.circular(
                    (y == sharedState.height - 2 && x == Constants.width - 1)
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
                Text(
                  content.cells[y][x].room,
                  style: TextStyle(
                    color: Colors.transparent,
                  ),
                ),
                Text(
                  content.cells[y][x].teacher,
                  style: TextStyle(
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ))
        : Expanded(
            child: Material(
              child: InkWell(
                onTap: () {
                  showInfoDialog(content.cells[y][x], context, sharedState);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: !content.cells[y][x].isDropped
                        ? content.cells[y][x].isSubstitute
                            ? sharedState.theme.subjectSubstitutionColor
                            : sharedState.theme.subjectColor
                        : sharedState.theme.subjectDropOutColor,
                    border: Border(
                        bottom: BorderSide(
                            width: 1.0,
                            color: (y - 1) % 2 == 0
                                ? Colors.black54
                                : Colors.black26),
                        right: BorderSide(width: 0.5, color: Colors.black26),
                        left: BorderSide(width: 0.5, color: Colors.black26)),
                  ),
                  child: Column(
                    children: content.cells[y][x].isDropped
                        ? [
                            Text(
                              content.cells[y][x].originalSubject,
                              style: TextStyle(
                                  color: sharedState.theme.textColor
                                      .withAlpha(214),
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0),
                            ),
                            Text(
                              content.cells[y][x].subject,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),
                            ),
                            Text(
                              content.cells[y][x].room,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),
                            ),
                            Text(
                              content.cells[y][x].teacher,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),
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
                                  color: sharedState.theme.textColor),
                            ),
                            Text(
                              content.cells[y][x].room,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),
                            ),
                            Text(
                              content.cells[y][x].teacher,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),
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
          "99:99",
          style: GoogleFonts.poppins(color: Colors.transparent),
        ),
      ),
    );
  }
}

class TimeGridObject extends StatefulWidget {
  @override
  _TimeGridObjectState createState() => _TimeGridObjectState();

  TimeGridObject(this.y, this.sharedState) {
    // Get start hour and start minute
    List<String> startTime = Constants.startTimes[y - 1].split(":");
    int startHour = int.parse(startTime[0]);
    int startMinute = int.parse(startTime[1]);

    // Get end hour and end minute
    List<String> endTime = Constants.endTimes[y - 1].split(":");
    int endHour = int.parse(endTime[0]);
    int endMinute = int.parse(endTime[1]);

    // Construct TimeOfDay objects
    startCellTime = TimeOfDay(hour: startHour, minute: startMinute);
    endCellTime = TimeOfDay(hour: endHour, minute: endMinute);
  }

  final int y;
  final SharedState sharedState;
  TimeOfDay startCellTime;
  TimeOfDay endCellTime;
}

class _TimeGridObjectState extends State<TimeGridObject> {
  TimeOfDay timeOfDay = TimeOfDay.now();
  bool isActive = false;
  SharedState sharedState;

  void initState() {
    sharedState = widget.sharedState;
    setIsActive();
  }

  void setIsActive() {
    timeOfDay = TimeOfDay.now();
    // Check if current time of day falls into start time and end time range
    if (timeToDouble(widget.startCellTime) <= timeToDouble(timeOfDay) &&
        timeToDouble(widget.endCellTime) > timeToDouble(timeOfDay)) {
      isActive = true;
    } else {
      isActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    setIsActive();

    return Container(
      decoration: BoxDecoration(
          color: isActive ? sharedState.theme.textColor : Colors.transparent,
          borderRadius: BorderRadius.circular(2.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? Colors.transparent
                    : sharedState.theme.textColor.withAlpha(214),
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 0,
                child: Text(
                  "99:99",
                  style: GoogleFonts.poppins(color: Colors.transparent),
                ),
              ),
              Text(
                Constants.startTimes[widget.y - 1],
                style: GoogleFonts.poppins(
                    color: isActive
                        ? sharedState.theme.backgroundColor
                        : sharedState.theme.textColor,
                    fontWeight: FontWeight.w200),
              ),
              Text(
                "${widget.y}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? sharedState.theme.backgroundColor
                      : sharedState.theme.textColor,
                ),
              ),
              Text(
                Constants.endTimes[widget.y - 1],
                style: GoogleFonts.poppins(
                    color: isActive
                        ? sharedState.theme.backgroundColor
                        : sharedState.theme.textColor,
                    fontWeight: FontWeight.w200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double timeToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;
}
