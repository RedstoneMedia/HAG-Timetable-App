import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/shared_state.dart';

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
            color: x + 1 == weekdayToday
                ? sharedState.theme.textColor
                : sharedState.theme.textColor.withAlpha(25)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Text(
                weekday,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                color: x + 1 == weekdayToday
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

  Future<void> _showMyDialog(Cell cell) async {
    bool showFootnotes = cell.footnotes != null;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 500),
          child: AlertDialog(
            title: Text('Informationen'),
            content: SingleChildScrollView(
              child: showFootnotes
                  ? SizedBox(
                height: 200,
                width: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cell.footnotes.length,
                  itemBuilder: (_, i) {
                    return Column(
                      children: [
                        Text("Fach: ${cell.footnotes[i].subject}"),
                        Text("Raum: ${cell.footnotes[i].room}"),
                        Text("Lehrer: ${cell.footnotes[i].teacher}"),
                        Text("Text: ${cell.footnotes[i].text}")
                      ],
                    );
                  },
                ),
              )
                  : ListBody(
                children: cell.isDropped
                    ? [
                  Text("Orginal-Fach: ${cell.originalSubject}"),
                  Text("Fach: ${cell.subject}\n"),
                  Text("Orginal-Raum: ${cell.originalRoom}"),
                  Text("Raum: ${cell.room}\n"),
                  Text("Orginal-Lehrer: ${cell.originalTeacher}"),
                  Text("Lehrer: ${cell.teacher}\n"),
                  cell.isSubstitute
                      ? Text("Text: ${cell.text}")
                      : Container(),
                ]
                    : [
                  Text("Fach: ${cell.subject}"),
                  Text("Raum: ${cell.room}"),
                  Text("Lehrer: ${cell.teacher}"),
                  cell.isSubstitute
                      ? Text("Text: ${cell.text}")
                      : Container(),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Schließen'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return content.cells[y][x].isEmpty()
        ? Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: sharedState.theme.textColor.withAlpha(10),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(
                  (y == Constants.height - 2 && x == 1) ? 5 : 0),
              bottomRight: Radius.circular(
                  (y == Constants.height - 2 && x == Constants.width - 1)
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
            _showMyDialog(content.cells[y][x]);
          },
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
                    ? sharedState.theme.subjectColor
                    : sharedState.theme.subjectDropOutColor),
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

class TimeGridObject extends StatelessWidget {
  TimeGridObject(this.y, this.sharedState);

  final int y;
  final SharedState sharedState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: sharedState.theme.textColor.withAlpha(214),
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
              Constants.startTimes[y - 1],
              style: GoogleFonts.poppins(
                  color: sharedState.theme.textColor,
                  fontWeight: FontWeight.w200),
            ),
            Text(
              "$y.",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: sharedState.theme.textColor),
            ),
            Text(
              Constants.endTimes[y - 1],
              style: GoogleFonts.poppins(
                  color: sharedState.theme.textColor,
                  fontWeight: FontWeight.w200),
            ),
          ],
        ),
      ),
    );
  }
}
