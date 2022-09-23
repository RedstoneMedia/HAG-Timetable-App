import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/calendar_data.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/calender_info_diaglog.dart';

import 'info_dialog.dart';

class WeekdayGridObject extends StatelessWidget {
  WeekdayGridObject(
      {/*required*/  required this.weekday,
      /*required*/  required this.x,
      /*required*/ required this.needsLeftBorder,
      /*required*/ required this.needsRightBorder,
      /*required*/ required this.sharedState});

  final String weekday;
  final int x;
  final int weekdayToday = DateTime.now().weekday;
  final bool needsLeftBorder;
  final bool needsRightBorder;
  final SharedState sharedState;

  @override
  Widget build(BuildContext context) {
    final dataPoints = sharedState.calendarData.days[x-1];
    final isHoliday = sharedState.holidayWeekdays.contains(x) || dataPoints.where((element) => element.calendarType == CalendarType.holiday).isNotEmpty;
    return Expanded(
      child: Opacity(
        opacity:
          isHoliday ? 0.5 : 1.0,
        child: InkWell(
          onTap: () {
            if (dataPoints.isNotEmpty) {
              showCalenderInfoDialog(dataPoints, context, sharedState);
            }
          },
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(needsLeftBorder ? 5 : 0),
                  topRight: Radius.circular(needsRightBorder ? 5 : 0),
                ),
                border: Border.all(width: 0.75, color: Colors.black26),
                color: x == weekdayToday ? sharedState.theme.textColor
                      : dataPoints.isNotEmpty ? sharedState.theme.subjectDropOutColor.withAlpha(150)
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
        ),
      ),
    );
  }
}

class ClassGridObject extends StatelessWidget {
  const ClassGridObject(
      {required this.content,
       required this.sharedState,
       required this.x,
       required this.y,
       required this.needsLeftBorder,
       required this.context});

  final Content content;
  final SharedState sharedState;
  final int x;
  final int y;
  final bool needsLeftBorder;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity:
          sharedState.holidayWeekdays.contains(x) || sharedState.calendarData.days[x-1].where((element) => element.calendarType == CalendarType.holiday).isNotEmpty ? 0.5 : 1.0,
        child: content.cells[y][x].isEmpty()
            ? Container(
            decoration: BoxDecoration(
              color: sharedState.theme.textColor.withAlpha(10),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(
                    (y == sharedState.height! - 2 && x == 1) ? 5 : 0),
                bottomRight: Radius.circular(
                    (y == sharedState.height! - 2 && x == Constants.width - 1)
                        ? 5
                        : 0),
              ),
              border: Border.all(width: 0.5, color: Colors.black26),
            ),
            child: Column(
              children: [
                Text(
                  content.cells[y][x].originalSubject,
                  style: const TextStyle(
                      color: Colors.transparent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0),
                ),
                Text(
                  content.cells[y][x].subject,
                  style: const TextStyle(
                    color: Colors.transparent,
                  ),
                ),
                Text(
                  content.cells[y][x].room,
                  style: const TextStyle(
                    color: Colors.transparent,
                  ),
                ),
                Text(
                  content.cells[y][x].teacher,
                  style: const TextStyle(
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
              )
            : Material(
          color: Colors.transparent,
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
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(
                          (y == sharedState.height! - 2 && x == 1) ? 5 : 0),
                      bottomRight: Radius.circular(
                          (y == sharedState.height! - 2 && x == Constants.width - 1)
                              ? 5
                              : 0),
                    ),
                    border: Border.all(width: 0.5, color: Colors.black26,
                  ),),
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
                                  fontSize: 16.0),overflow: TextOverflow.ellipsis,                  maxLines: 1,
                            ),
                            Text(
                              content.cells[y][x].subject,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),overflow: TextOverflow.ellipsis,                  maxLines: 1,
                            ),
                            Text(
                              content.cells[y][x].room,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),overflow: TextOverflow.ellipsis,                  maxLines: 1,
                            ),
                            Text(
                              content.cells[y][x].teacher,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),overflow: TextOverflow.ellipsis,                  maxLines: 1,
                            ),
                          ]
                        : [
                            Text(
                              content.cells[y][x].originalSubject,
                              style: const TextStyle(
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
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              content.cells[y][x].room,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              content.cells[y][x].teacher,
                              style:
                                  TextStyle(color: sharedState.theme.textColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              content.cells[y][x].originalSubject,
                              style: const TextStyle(
                                color: Colors.transparent,
                                fontWeight: FontWeight.bold,
                                fontSize: 8.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                  ),
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
      child: Text(
        "99:99",
        style: GoogleFonts.poppins(color: Colors.transparent),
      ),
    );
  }
}

// ignore: must_be_immutable
class TimeGridObject extends StatefulWidget {
  @override
  _TimeGridObjectState createState() => _TimeGridObjectState();

  TimeGridObject(this.y, this.sharedState) {
    // Get start hour and start minute
    final startTime = Constants.startTimes[y - 1].split(":");
    final startHour = int.parse(startTime[0]);
    final startMinute = int.parse(startTime[1]);

    // Get end hour and end minute
    final endTime = Constants.endTimes[y - 1].split(":");
    final endHour = int.parse(endTime[0]);
    final endMinute = int.parse(endTime[1]);

    // Construct TimeOfDay objects
    startCellTime = TimeOfDay(hour: startHour, minute: startMinute);
    endCellTime = TimeOfDay(hour: endHour, minute: endMinute);
  }

  final int y;
  final SharedState sharedState;
  late TimeOfDay startCellTime;
  late TimeOfDay endCellTime;
}

class _TimeGridObjectState extends State<TimeGridObject> {
  TimeOfDay timeOfDay = TimeOfDay.now();
  bool isActive = false;
  late SharedState sharedState;

  @override
  void initState() {
    sharedState = widget.sharedState;
    setIsActive();
    super.initState();
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
              SizedBox(
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
